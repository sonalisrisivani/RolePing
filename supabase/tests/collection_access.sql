-- Run as database administrator. Test fixtures and imports are rolled back.
begin;
insert into roleping_collection.sources(slug, employer, feed_url) values
 ('__test_one', 'Test', 'https://boards-api.greenhouse.io/v1/boards/testone/jobs?content=true'),
 ('__test_two', 'Test', 'https://boards-api.greenhouse.io/v1/boards/testtwo/jobs?content=true');
set local role roleping_collector;
do $$
declare
  base jsonb := jsonb_build_object('source_slug','__test_one',
    'feed_url','https://boards-api.greenhouse.io/v1/boards/testone/jobs?content=true',
    'outcome','success','received_count',2,'errors','[]'::jsonb,
    'jobs','[{"source_job_id":"1","title":"Engineer","application_url":"https://example.com/1","raw_evidence":{"id":1}},
             {"source_job_id":"2","title":"Intern","application_url":"https://example.com/2","raw_evidence":{"id":2}}]'::jsonb);
  request jsonb;
  result jsonb;
  stamp timestamptz := clock_timestamp() - interval '20 minutes';
  initial_id uuid;
begin
  request := base || jsonb_build_object('run_id', gen_random_uuid(), 'started_at', stamp);
  perform roleping_collection.import_run(request);
  select id into initial_id from roleping_collection.jobs where source_slug='__test_one' and source_job_id='1';
  result := roleping_collection.import_run(request);
  if result->>'replayed' <> 'true' then raise exception 'Retry not idempotent'; end if;
  perform roleping_collection.import_run(base || jsonb_build_object('run_id', gen_random_uuid(), 'started_at', stamp + interval '1 minute'));
  if (select count(*) from roleping_collection.jobs where source_slug='__test_one') <> 2
    or (select id from roleping_collection.jobs where source_slug='__test_one' and source_job_id='1') <> initial_id then
    raise exception 'Repeat run duplicated or replaced jobs';
  end if;
  perform roleping_collection.import_run(base || jsonb_build_object('run_id',gen_random_uuid(), 'started_at',stamp + interval '2 minutes',
    'outcome','partial','jobs', jsonb_build_array(base->'jobs'->0),'errors',jsonb_build_array('truncated')));
  perform roleping_collection.import_run(base || jsonb_build_object('run_id',gen_random_uuid(), 'started_at',stamp + interval '3 minutes',
    'outcome','failed','jobs','[]'::jsonb,'received_count',0,'errors',jsonb_build_array('http_503')));
  if (select count(*) from roleping_collection.jobs where source_slug='__test_one' and status='open') <> 2 then
    raise exception 'Partial or failed run closed jobs';
  end if;
  if not exists(select 1 from roleping_collection.runs where source_slug='__test_one' and outcome='failed' and errors='["http_503"]'::jsonb) then
    raise exception 'Failure missing from health history';
  end if;
  perform roleping_collection.import_run(base || jsonb_build_object('run_id',gen_random_uuid(),'started_at',stamp + interval '4 minutes',
    'source_slug','__test_two','feed_url','https://boards-api.greenhouse.io/v1/boards/testtwo/jobs?content=true'));
  result := roleping_collection.import_run(base || jsonb_build_object('run_id',gen_random_uuid(),'started_at',stamp + interval '5 minutes',
    'received_count',1,'jobs',jsonb_build_array(base->'jobs'->0)));
  if (result->>'closed')::integer <> 1 then raise exception 'Complete run did not close missing posting'; end if;
  if (select count(*) from roleping_collection.jobs where source_slug='__test_two' and status='open') <> 2 then
    raise exception 'Closure crossed source boundary';
  end if;
  result := roleping_collection.import_run(base || jsonb_build_object('run_id',gen_random_uuid(),'started_at',stamp));
  if result->>'outcome' <> 'stale' or (select status from roleping_collection.jobs where source_slug='__test_one' and source_job_id='2') <> 'closed' then
    raise exception 'Older snapshot overwrote newer state';
  end if;
  perform roleping_collection.import_run(base || jsonb_build_object('run_id',gen_random_uuid(),'started_at',stamp + interval '6 minutes'));
  if (select status from roleping_collection.jobs where source_slug='__test_one' and source_job_id='2') <> 'open' then
    raise exception 'Reappearing posting was not reopened';
  end if;
  begin
    perform roleping_collection.import_run(base || jsonb_build_object('run_id',gen_random_uuid(),'started_at',stamp + interval '7 minutes','received_count',0,'jobs','[]'::jsonb));
    raise exception 'Empty success accepted';
  exception when raise_exception then
    if sqlerrm <> 'Complete nonempty response required to close missing jobs' then raise; end if;
  end;
  begin
    perform * from public.profiles;
    raise exception 'Collector can read private profiles';
  exception when insufficient_privilege then null;
  end;
  begin
    update roleping_collection.sources set enabled=false where slug='__test_one';
    raise exception 'Collector can change operator source configuration';
  exception when insufficient_privilege then null;
  end;
end $$;
set local role authenticated;
do $$ begin
  begin
    perform * from roleping_collection.jobs;
    raise exception 'Browser can read private evidence';
  exception when insufficient_privilege then null;
  end;
  begin
    perform roleping_collection.import_run('{}'::jsonb);
    raise exception 'Browser can invoke collector';
  exception when insufficient_privilege then null;
  end;
end $$;
set local role anon;
do $$ begin
  begin
    perform * from roleping_collection.runs;
    raise exception 'Anonymous access to operator logs';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
select 'PASS: repeat imports, retries, partial/failure safety, source isolation, closure, stale protection, reopen and access boundaries' as result;
rollback;
