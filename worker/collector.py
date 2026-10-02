"""Fetch Greenhouse postings without interpreting eligibility or executing HTML."""
import argparse
from datetime import datetime, timezone
from http.client import HTTPException
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
from uuid import uuid4

RULES_PATH = Path(__file__).resolve().parents[1] / 'config' / 'product-rules.json'


def feed_url(source):
    token = source['board_token']
    if source['adapter'] != 'greenhouse' or not re.fullmatch(r'[a-zA-Z0-9_-]+', token):
        raise ValueError('Unsupported source configuration')
    return f'https://boards-api.greenhouse.io/v1/boards/{token}/jobs?content=true'


def normalize_job(job):
    if not isinstance(job, dict) or type(job.get('id')) is not int or job['id'] <= 0:
        raise ValueError('invalid_id')
    # PostgreSQL jsonb cannot store NUL or lone surrogate code points. Reject
    # these rows individually so one malformed record does not lose the run.
    def check_strings(value):
        if isinstance(value, str):
            if '\x00' in value:
                raise ValueError('unsupported_evidence_text')
            try:
                value.encode('utf-8')
            except UnicodeEncodeError:
                raise ValueError('unsupported_evidence_text') from None
        elif isinstance(value, dict):
            for key, child in value.items():
                check_strings(key)
                check_strings(child)
        elif isinstance(value, list):
            for child in value:
                check_strings(child)
    check_strings(job)
    try:
        json.dumps(job, allow_nan=False)
    except (ValueError, TypeError):
        raise ValueError('invalid_evidence_json') from None
    title = job.get('title')
    url = job.get('absolute_url')
    if not isinstance(title, str) or not title.strip():
        raise ValueError('missing_title')
    if not isinstance(url, str):
        raise ValueError('invalid_application_url')
    parsed = urlsplit(url)
    if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError('invalid_application_url')
    updated = job.get('updated_at')
    if updated is not None:
        try:
            timestamp = datetime.fromisoformat(updated.replace('Z', '+00:00'))
            if timestamp.tzinfo is None:
                raise ValueError('missing_offset')
            updated = timestamp.isoformat()
        except (ValueError, TypeError, AttributeError):
            raise ValueError('invalid_updated_at') from None
    location = job.get('location')
    location = location.get('name') if isinstance(location, dict) else None
    content = job.get('content')
    if content is not None and not isinstance(content, str):
        raise ValueError('invalid_content')
    return {
        'source_job_id': str(job['id']), 'title': title.strip(),
        'location_text': location.strip() if isinstance(location, str) and location.strip() else None,
        'application_url': url, 'description_html': content,
        'source_updated_at': updated, 'raw_evidence': job,
    }


def parse_feed(payload):
    if not isinstance(payload, dict) or not isinstance(payload.get('jobs'), list):
        return 'failed', [], 0, ['invalid_feed_shape']
    raw_jobs = payload['jobs']
    errors, jobs, seen = [], [], set()
    meta = payload.get('meta')
    total = meta.get('total') if isinstance(meta, dict) else None
    if type(total) is not int or total != len(raw_jobs):
        errors.append('total_missing_or_mismatched')
    if not raw_jobs:
        errors.append('empty_feed_requires_review')
    for index, job in enumerate(raw_jobs):
        try:
            normalized = normalize_job(job)
            if normalized['source_job_id'] in seen:
                raise ValueError('duplicate_id')
            seen.add(normalized['source_job_id'])
            jobs.append(normalized)
        except ValueError as error:
            errors.append(f'row_{index}:{error}')
    return ('partial' if errors else 'success'), jobs, len(raw_jobs), errors


def fetch_feed(url, timeout, max_bytes):
    request = Request(url, headers={'Accept': 'application/json', 'User-Agent': 'RolePing/0.1 job collector'})
    with urlopen(request, timeout=timeout) as response:
        # An unexpected redirect is not evidence that the original board is complete.
        if response.geturl() != url or response.status != 200:
            raise ValueError('unexpected_response')
        body = response.read(max_bytes + 1)
        if len(body) > max_bytes:
            raise ValueError('response_too_large')
        return json.loads(body)


def collect(source, rules, fetch=fetch_feed):
    started = datetime.now(timezone.utc).isoformat()
    url = feed_url(source)
    try:
        payload = fetch(url, rules['http_timeout_seconds']['value'], rules['max_response_bytes']['value'])
        outcome, jobs, received, errors = parse_feed(payload)
    except HTTPError as error:
        outcome, jobs, received, errors = 'failed', [], 0, [f'http_{error.code}']
    except (URLError, TimeoutError, OSError, ValueError, HTTPException, RecursionError):
        # Do not persist response bodies, exception URLs or credentials in logs.
        outcome, jobs, received, errors = 'failed', [], 0, ['fetch_or_decode_failed']
    return {'run_id': str(uuid4()), 'source_slug': source['slug'], 'feed_url': url,
            'started_at': started, 'outcome': outcome, 'jobs': jobs,
            'received_count': received, 'errors': errors}


def sql_literal(value):
    # Dollar-quote JSON without permitting data to terminate the SQL literal.
    serialized = json.dumps(value, ensure_ascii=True, allow_nan=False)
    tag = '$roleping$'
    while tag in serialized:
        tag = '$roleping_' + uuid4().hex + '$'
    return f'{tag}{serialized}{tag}'


def render_import_sql(results):
    statements = ['begin;', 'set local role roleping_collector;']
    statements += [f'select roleping_collection.import_run({sql_literal(result)}::jsonb);' for result in results]
    return '\n'.join(statements + ['commit;', ''])


def render_sources_sql(sources):
    # Operator-only registration, deliberately separate from the collector role.
    statements = ['begin;']
    for source in sources:
        obj = sql_literal({'slug': source['slug'], 'employer': source['employer'], 'feed_url': feed_url(source)})
        statements.append(f'''insert into roleping_collection.sources(slug, employer, feed_url)
select p->>'slug', p->>'employer', p->>'feed_url' from (select {obj}::jsonb p) v
on conflict (slug) do update set employer = excluded.employer, feed_url = excluded.feed_url;''')
    return '\n'.join(statements + ['commit;', ''])


def persist(result, database_url):
    import psycopg
    from psycopg.types.json import Jsonb
    # Use a dedicated login granted roleping_collector; never a browser key.
    with psycopg.connect(database_url, connect_timeout=10) as connection:
        connection.execute('set local role roleping_collector')
        return connection.execute('select roleping_collection.import_run(%s)', (Jsonb(result),)).fetchone()[0]


def persist_via_cli(result, project_ref):
    """Manual operator transport using an existing Supabase CLI login."""
    if not re.fullmatch(r'[a-z0-9]{20}', project_ref):
        raise ValueError('Invalid project ref')
    with tempfile.NamedTemporaryFile(mode='w', suffix='.sql', encoding='utf-8') as sql_file:
        sql_file.write(render_import_sql([result]))
        sql_file.flush()
        response = subprocess.run(
            ['supabase', 'db', 'query', '--linked', '--project-ref', project_ref,
             '--file', sql_file.name, '--output', 'json'],
            check=True, capture_output=True, text=True, timeout=60,
        )
        return json.loads(response.stdout)['rows'][0]['import_run']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', help='Configured source slug; defaults to all sources')
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--sql-output', type=Path, help='Write a reviewable import SQL file; does not persist')
    mode.add_argument('--register-sql', type=Path, help='Write operator source registration SQL; no fetch')
    mode.add_argument('--persist', action='store_true', help='Import using ROLEPING_DATABASE_URL')
    mode.add_argument('--project-ref', help='Fetch and import using an authenticated Supabase CLI (manual operator mode)')
    args = parser.parse_args()
    rules = json.loads(RULES_PATH.read_text())['collection']
    if (rules['empty_feed_policy']['value'] != 'partial_requires_review'
            or rules['close_missing_only_on_complete_response']['value'] is not True):
        parser.error('Collection safety policy changes require a reviewed adapter and migration update')
    sources = rules['sources']['value']
    if args.source:
        sources = [source for source in sources if source['slug'] == args.source]
        if not sources:
            parser.error('Unknown source slug')
    if args.register_sql:
        args.register_sql.write_text(render_sources_sql(sources))
        return 0
    database_url = os.environ.get('ROLEPING_DATABASE_URL')
    if args.persist and not database_url:
        parser.error('ROLEPING_DATABASE_URL is required for --persist')
    results, unsuccessful = [], False
    for source in sources:
        result = collect(source, rules)
        results.append(result)
        summary = {key: result[key] for key in ('source_slug', 'outcome', 'received_count', 'errors')}
        summary['accepted_count'] = len(result['jobs'])
        summary['persisted'] = False
        if args.persist or args.project_ref:
            try:
                summary['database'] = (persist_via_cli(result, args.project_ref) if args.project_ref
                                       else persist(result, database_url))
                summary['persisted'] = True
                unsuccessful |= summary['database'].get('outcome') not in ('success', 'partial')
            except Exception as error:
                # Continue other sources, fail the process, do not log the DSN.
                summary['persistence_error'] = type(error).__name__
                unsuccessful = True
        unsuccessful |= result['outcome'] != 'success'
        print(json.dumps(summary))
    if args.sql_output:
        args.sql_output.write_text(render_import_sql(results))
    return 1 if unsuccessful else 0


if __name__ == '__main__':
    sys.exit(main())
