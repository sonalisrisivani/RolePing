-- Private ingestion state. No browser grants and no SECURITY DEFINER functions.
create schema roleping_collection;
revoke all on schema roleping_collection from public, anon, authenticated;
create role roleping_collector nologin nosuperuser nocreatedb nocreaterole noinherit nobypassrls;
grant roleping_collector to postgres;
grant usage on schema roleping_collection to roleping_collector;

create table roleping_collection.sources (
  slug text primary key,
  employer text not null,
  feed_url text not null check (feed_url like 'https://boards-api.greenhouse.io/v1/boards/%/jobs?content=true'),
  enabled boolean not null default true,
  last_applied_started_at timestamptz
);
create table roleping_collection.runs (
  id uuid primary key,
  source_slug text not null references roleping_collection.sources(slug),
  started_at timestamptz not null,
  finished_at timestamptz not null default clock_timestamp(),
  outcome text not null check (outcome in ('success', 'partial', 'failed', 'stale')),
  received_count integer not null check (received_count >= 0),
  accepted_count integer not null check (accepted_count >= 0),
  closed_count integer not null default 0 check (closed_count >= 0),
  errors jsonb not null default '[]' check (jsonb_typeof(errors) = 'array')
);
create index collection_runs_source_time on roleping_collection.runs(source_slug, started_at desc);
create table roleping_collection.jobs (
  id uuid primary key default gen_random_uuid(),
  source_slug text not null references roleping_collection.sources(slug),
  source_job_id text not null,
  title text not null check (length(trim(title)) > 0),
  location_text text,
  application_url text not null check (application_url ~ '^https://[^/]+'),
  description_html text,
  source_updated_at timestamptz,
  first_seen_at timestamptz not null,
  last_seen_at timestamptz not null,
  closed_at timestamptz,
  status text not null check (status in ('open', 'closed')),
  raw_evidence jsonb not null check (jsonb_typeof(raw_evidence) = 'object'),
  unique(source_slug, source_job_id)
);
-- Salary, work mode, degree, batch and role type are not inferred by this adapter.
comment on table roleping_collection.jobs is 'One canonical record per source posting; raw evidence is untrusted HTML/data. No confirmed eligibility inferred.';

alter table roleping_collection.sources enable row level security;
alter table roleping_collection.runs enable row level security;
alter table roleping_collection.jobs enable row level security;
revoke all on all tables in schema roleping_collection from public, anon, authenticated;
grant select on roleping_collection.sources to roleping_collector;
grant update(last_applied_started_at) on roleping_collection.sources to roleping_collector;
grant select, insert on roleping_collection.runs to roleping_collector;
grant select, insert, update on roleping_collection.jobs to roleping_collector;
create policy collector_read_sources on roleping_collection.sources for select to roleping_collector using (true);
create policy collector_update_source_health on roleping_collection.sources for update to roleping_collector using (true) with check (true);
create policy collector_read_runs on roleping_collection.runs for select to roleping_collector using (true);
create policy collector_insert_runs on roleping_collection.runs for insert to roleping_collector with check (true);
create policy collector_manage_jobs on roleping_collection.jobs for all to roleping_collector using (true) with check (true);

-- Fetch and validation happen before this short atomic transaction. Source row
-- locking serializes imports; older responses cannot overwrite newer evidence.
create function roleping_collection.import_run(payload jsonb)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare
  source_row roleping_collection.sources%rowtype;
  run_id uuid := (payload->>'run_id')::uuid;
  started timestamptz := (payload->>'started_at')::timestamptz;
  result text := payload->>'outcome';
  items jsonb := payload->'jobs';
  received integer := (payload->>'received_count')::integer;
  count_closed integer := 0;
  previous roleping_collection.runs%rowtype;
begin
  select * into strict source_row from roleping_collection.sources
    where slug = payload->>'source_slug' for update;
  if not source_row.enabled or source_row.feed_url <> payload->>'feed_url' then
    raise exception 'Source disabled or URL mismatch';
  end if;
  select * into previous from roleping_collection.runs where id = run_id;
  if found then
    if previous.source_slug <> source_row.slug then raise exception 'Run ID belongs to another source'; end if;
    return jsonb_build_object('run_id', run_id, 'outcome', previous.outcome, 'accepted', previous.accepted_count, 'closed', previous.closed_count, 'replayed', true);
  end if;
  if started is null or started > clock_timestamp() or result is null or result not in ('success','partial','failed')
    or items is null or jsonb_typeof(items) <> 'array' or received is null or received < jsonb_array_length(items)
    or jsonb_typeof(payload->'errors') is distinct from 'array' then
    raise exception 'Invalid run envelope';
  end if;
  if result = 'success' and (received <> jsonb_array_length(items) or received = 0 or jsonb_array_length(payload->'errors') <> 0) then
    raise exception 'Complete nonempty response required to close missing jobs';
  end if;
  if result = 'failed' and jsonb_array_length(items) <> 0 then raise exception 'Failed run cannot contain accepted jobs'; end if;
  if exists (select 1 from jsonb_array_elements(items) j where
    coalesce(j->>'source_job_id','') = '' or coalesce(trim(j->>'title'),'') = ''
    or coalesce(j->>'application_url','') !~ '^https://[^/]+'
    or jsonb_typeof(j->'raw_evidence') is distinct from 'object') then
    raise exception 'Invalid normalized job';
  end if;
  if (select count(distinct j->>'source_job_id') from jsonb_array_elements(items) j) <> jsonb_array_length(items) then
    raise exception 'Duplicate source job IDs';
  end if;
  if started <= source_row.last_applied_started_at then result := 'stale'; end if;
  if result in ('success', 'partial') then
    insert into roleping_collection.jobs(source_slug, source_job_id, title, location_text, application_url,
      description_html, source_updated_at, first_seen_at, last_seen_at, status, raw_evidence)
    select source_row.slug, j->>'source_job_id', j->>'title', j->>'location_text', j->>'application_url',
      j->>'description_html', (j->>'source_updated_at')::timestamptz, started, started, 'open', j->'raw_evidence'
    from jsonb_array_elements(items) j
    on conflict(source_slug, source_job_id) do update set
      title = excluded.title, location_text = excluded.location_text, application_url = excluded.application_url,
      description_html = excluded.description_html, source_updated_at = excluded.source_updated_at,
      last_seen_at = excluded.last_seen_at, status = 'open', closed_at = null, raw_evidence = excluded.raw_evidence;
    if result = 'success' then
      update roleping_collection.jobs set status = 'closed', closed_at = started
      where source_slug = source_row.slug and status = 'open'
        and source_job_id not in (select j->>'source_job_id' from jsonb_array_elements(items) j);
      get diagnostics count_closed = row_count;
    end if;
    update roleping_collection.sources set last_applied_started_at = started where slug = source_row.slug;
  end if;
  insert into roleping_collection.runs(id, source_slug, started_at, outcome, received_count, accepted_count, closed_count, errors)
  values(run_id, source_row.slug, started, result, received,
    case when result in ('success','partial') then jsonb_array_length(items) else 0 end, count_closed, payload->'errors');
  return jsonb_build_object('run_id', run_id, 'outcome', result,
    'accepted', case when result in ('success','partial') then jsonb_array_length(items) else 0 end, 'closed', count_closed);
end $$;
revoke all on function roleping_collection.import_run(jsonb) from public, anon, authenticated;
grant execute on function roleping_collection.import_run(jsonb) to roleping_collector;
