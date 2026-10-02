import json
from io import BytesIO
from http.client import IncompleteRead
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError

from worker.collector import collect, fetch_feed, main, normalize_job, parse_feed, persist_via_cli, render_import_sql, render_sources_sql

SOURCE = {'slug': 'example', 'employer': 'Example', 'adapter': 'greenhouse', 'board_token': 'example'}
RULES = {'http_timeout_seconds': {'value': 1}, 'max_response_bytes': {'value': 1000},
         'empty_feed_policy': {'value': 'partial_requires_review'},
         'close_missing_only_on_complete_response': {'value': True}}
JOB = {'id': 123, 'title': 'Engineer', 'absolute_url': 'https://example.com/jobs/123',
       'updated_at': '2026-10-01T00:00:00Z', 'location': {'name': 'Bengaluru'},
       'content': '<p>Example job</p>'}


class CollectionTests(unittest.TestCase):
    def test_fetch_rejects_oversized_or_redirected_responses(self):
        url = 'https://boards-api.greenhouse.io/v1/boards/example/jobs?content=true'
        for body, final_url in ((b'12345', url), (b'{}', 'https://example.com/redirect')):
            response = BytesIO(body)
            response.status = 200
            response.geturl = lambda: final_url
            with patch('worker.collector.urlopen', return_value=response):
                with self.assertRaises(ValueError):
                    fetch_feed(url, 1, 4)

    def test_preserves_evidence_and_unknowns(self):
        job = {**JOB, 'location': None, 'updated_at': None}
        normalized = normalize_job(job)
        self.assertEqual(normalized['raw_evidence'], job)
        self.assertIsNone(normalized['location_text'])
        self.assertIsNone(normalized['source_updated_at'])
        self.assertNotIn('salary', normalized)
        self.assertNotIn('eligibility', normalized)

    def test_complete_feed(self):
        outcome, jobs, received, errors = parse_feed({'jobs': [JOB], 'meta': {'total': 1}})
        self.assertEqual((outcome, len(jobs), received, errors), ('success', 1, 1, []))

    def test_partial_count_or_missing_meta_never_success(self):
        for meta in ({'total': 2}, {}, {'total': True}, None):
            self.assertEqual(parse_feed({'jobs': [JOB], 'meta': meta})[0], 'partial')

    def test_empty_feed_requires_review(self):
        self.assertEqual(parse_feed({'jobs': [], 'meta': {'total': 0}})[0], 'partial')

    def test_invalid_rows_preserve_valid_records_as_partial(self):
        for bad in (None, {}, {**JOB, 'id': True}, {**JOB, 'title': ''},
                    {**JOB, 'absolute_url': 'javascript:alert(1)'},
                    {**JOB, 'updated_at': 'yesterday'}, {**JOB, 'content': []}):
            outcome, jobs, _, errors = parse_feed({'jobs': [JOB, bad], 'meta': {'total': 2}})
            self.assertEqual((outcome, len(jobs)), ('partial', 1))
            self.assertTrue(errors)

    def test_duplicates_are_partial(self):
        outcome, jobs, _, _ = parse_feed({'jobs': [JOB, JOB], 'meta': {'total': 2}})
        self.assertEqual((outcome, len(jobs)), ('partial', 1))

    def test_unstorable_evidence_does_not_poison_valid_rows(self):
        for evidence in ('\x00', '\ud800', float('nan')):
            bad = {**JOB, 'id': 124, 'metadata': [evidence]}
            outcome, jobs, _, errors = parse_feed({'jobs': [JOB, bad], 'meta': {'total': 2}})
            self.assertEqual((outcome, len(jobs)), ('partial', 1))
            self.assertTrue(errors)

    def test_bad_shape_fails(self):
        for payload in (None, [], {'jobs': {}}, {}):
            self.assertEqual(parse_feed(payload)[0], 'failed')

    def test_failure_does_not_prevent_next_source(self):
        for exception in (URLError('sensitive exception URL'), IncompleteRead(b'sensitive body'), RecursionError()):
            def fail(*args):
                raise exception
            failed = collect(SOURCE, RULES, fail)
            succeeded = collect(SOURCE, RULES, lambda *args: {'jobs': [JOB], 'meta': {'total': 1}})
            self.assertEqual(failed['outcome'], 'failed')
            self.assertEqual(failed['jobs'], [])
            self.assertNotIn('sensitive', json.dumps(failed))
            self.assertEqual(succeeded['outcome'], 'success')

    def test_rate_limit_records_code_without_retry_storm(self):
        def fail(*args):
            raise HTTPError('https://example.com', 429, 'limited', None, None)
        self.assertEqual(collect(SOURCE, RULES, fail)['errors'], ['http_429'])

    def test_sql_payload_cannot_end_its_literal(self):
        result = collect(SOURCE, RULES, lambda *args: {'jobs': [JOB], 'meta': {'total': 1}})
        result['jobs'][0]['title'] = "$roleping$'; drop table public.profiles; --"
        sql = render_import_sql([result])
        self.assertIn('$roleping_', sql)
        self.assertIn('set local role roleping_collector;', sql)
        self.assertIn('commit;', sql)
        self.assertIn('on conflict (slug)', render_sources_sql([SOURCE]))

    def test_persistence_failure_is_visible_and_next_source_still_runs(self):
        rules = {'collection': {**RULES, 'sources': {'value': [SOURCE, {**SOURCE, 'slug': 'second'}]}}}
        result = collect(SOURCE, RULES, lambda *args: {'jobs': [JOB], 'meta': {'total': 1}})
        with tempfile.TemporaryDirectory() as folder:
            config = Path(folder) / 'rules.json'
            config.write_text(json.dumps(rules))
            with patch('worker.collector.RULES_PATH', config), patch('sys.argv', ['collector', '--persist']), \
                 patch.dict('os.environ', {'ROLEPING_DATABASE_URL': 'private-dsn'}), \
                 patch('worker.collector.collect', return_value=result), \
                 patch('worker.collector.persist', side_effect=[RuntimeError('private-dsn'), {}]) as persist, \
                 patch('builtins.print') as output:
                self.assertEqual(main(), 1)
                self.assertEqual(persist.call_count, 2)
                self.assertNotIn('private-dsn', str(output.call_args_list))

    def test_cli_import_uses_scoped_role_and_temporary_file(self):
        def execute(command, **kwargs):
            self.assertEqual(command[:3], ['supabase', 'db', 'query'])
            path = Path(command[command.index('--file') + 1])
            self.assertIn('set local role roleping_collector;', path.read_text())
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            from types import SimpleNamespace
            return SimpleNamespace(stdout=json.dumps({'rows': [{'import_run': {'outcome': 'success'}}]}))
        with patch('worker.collector.subprocess.run', side_effect=execute) as run:
            self.assertEqual(persist_via_cli({}, 'a' * 20), {'outcome': 'success'})
            command = run.call_args.args[0]
            self.assertFalse(Path(command[command.index('--file') + 1]).exists())


if __name__ == '__main__':
    unittest.main()
