begin;
insert into roleping_collection.sources(slug, employer, feed_url)
values ('cards-test', 'Test employer', 'https://boards-api.greenhouse.io/v1/boards/test/jobs?content=true');
set local role roleping_collector;
insert into roleping_collection.jobs(source_slug, source_job_id, title, application_url, first_seen_at, last_seen_at, status, raw_evidence)
values ('cards-test', '1', 'Test role', 'https://example.com/job', now(), now(), 'open', '{}');
reset role;
set local role authenticated;
do $$ begin
  if (select count(*) from public.job_cards where source_slug = 'cards-test') <> 1 then raise exception 'Open job not published'; end if;
  begin
    update public.job_cards set title = 'Tampered';
    raise exception 'Browser write allowed';
  exception when insufficient_privilege then null; end;
  begin
    perform * from roleping_collection.jobs;
    raise exception 'Raw evidence accessible';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
set local role anon;
do $$ begin
  begin
    perform * from public.job_cards;
    raise exception 'Anonymous read allowed';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
set local role roleping_collector;
update roleping_collection.jobs set status = 'closed' where source_slug = 'cards-test';
reset role;
set local role authenticated;
do $$ begin
  if exists(select 1 from public.job_cards where source_slug = 'cards-test') then raise exception 'Closed job visible'; end if;
end $$;
reset role;
set local role roleping_collector;
update roleping_collection.jobs set status = 'open', title = 'Reopened role' where source_slug = 'cards-test';
reset role;
update roleping_collection.sources set enabled = false where slug = 'cards-test';
set local role authenticated;
do $$ begin
  if exists(select 1 from public.job_cards where source_slug = 'cards-test') then raise exception 'Disabled source visible'; end if;
end $$;
reset role;
update roleping_collection.sources set enabled = true, employer = 'Renamed employer' where slug = 'cards-test';
set local role authenticated;
do $$ begin
  if not exists(select 1 from public.job_cards where source_slug = 'cards-test' and title = 'Reopened role' and company = 'Renamed employer') then raise exception 'Reopen/source sync failed'; end if;
end $$;
reset role;
do $$ begin
  if has_table_privilege('authenticated', 'public.job_cards', 'INSERT')
    or has_table_privilege('authenticated', 'public.job_cards', 'DELETE') then raise exception 'Browser mutation grants'; end if;
end $$;
rollback;
