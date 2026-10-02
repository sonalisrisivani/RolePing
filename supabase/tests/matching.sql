begin;
insert into auth.users(id) values ('a6100210-0000-4000-8000-000000000091'), ('a6100210-0000-4000-8000-000000000092');
insert into public.profiles(user_id,target_role,location,unknown_salary_policy,eligibility_policy)
values ('a6100210-0000-4000-8000-000000000091','Software Engineer, C++ Developer','Test City, Remote','include_with_caveat','include_with_caveat'),
('a6100210-0000-4000-8000-000000000092','Designer','Test City','include_with_caveat','include_with_caveat');
insert into roleping_collection.sources(slug,employer,feed_url) values ('matching-test','Match test','https://boards-api.greenhouse.io/v1/boards/test/jobs?content=true');
insert into roleping_collection.jobs(source_slug,source_job_id,title,location_text,application_url,first_seen_at,last_seen_at,status,raw_evidence)
select 'matching-test', n::text, title, location, 'https://example.com/job', now(), now(), 'open', '{}'
from (values (1,'Senior Software Development Engineer','Test City'),(2,'Software Engineering Manager','Test City'),(3,'Software Engineer','Another City'),(4,'Designer','Test City'),(5,'C++ Developer','Remote'),(6,'C Developer','Remote'),(7,'Software Engineer',null)) t(n,title,location);
set local role authenticated;
select set_config('request.jwt.claim.sub','a6100210-0000-4000-8000-000000000091',true);
do $$ begin
  if (select count(*) from public.match_job_cards() where company='Match test') <> 2 then raise exception 'Role boundaries, location, alternatives or C++ matching incorrect'; end if;
  if exists(select 1 from public.match_job_cards() where cardinality(reasons)<>2 or cardinality(caveats)<2) then raise exception 'Missing explanations'; end if;
end $$;
update public.profiles set target_role='any', location='any', years_experience=2.5, skills='React, SQL' where user_id=auth.uid();
do $$ begin
  if (select count(*) from public.match_job_cards() where company='Match test') <> 7 then raise exception 'Any does not bypass role/location filters'; end if;
  if not exists(select 1 from public.profiles where user_id=auth.uid() and years_experience=2.5 and skills='React, SQL') then raise exception 'New preferences did not persist'; end if;
  if exists(select 1 from public.match_job_cards() where company='Match test' and not ('Experience requirements are unverified; your experience has not been used to exclude jobs.' = any(caveats))) then raise exception 'Missing experience caveat'; end if;
end $$;
update public.profiles set target_role='Designer', location='any', years_experience=0, skills='any' where user_id=auth.uid();
do $$ begin
  if (select count(*) from public.match_job_cards() where company='Match test') <> 1 then raise exception 'Any location bypassed specific role'; end if;
end $$;
update public.profiles set target_role='any', location='Remote' where user_id=auth.uid();
do $$ begin
  if (select count(*) from public.match_job_cards() where company='Match test') <> 2 then raise exception 'Any role bypassed specific location'; end if;
end $$;
update public.profiles set target_role='any', location='any' where user_id=auth.uid();
update public.profiles set unknown_salary_policy='exclude' where user_id=auth.uid();
do $$ begin if exists(select 1 from public.match_job_cards()) then raise exception 'Unknown salary preference ignored'; end if; end $$;
update public.profiles set unknown_salary_policy='include_with_caveat',eligibility_policy='confirmed_only' where user_id=auth.uid();
do $$ begin if exists(select 1 from public.match_job_cards()) then raise exception 'Strict eligibility ignored'; end if; end $$;
update public.profiles set eligibility_policy='include_with_caveat',target_role=' , ',location='Test City' where user_id=auth.uid();
do $$ begin if exists(select 1 from public.match_job_cards()) then raise exception 'Blank terms match all'; end if; end $$;
select set_config('request.jwt.claim.sub','a6100210-0000-4000-8000-000000000092',true);
do $$ begin
  if (select count(*) from public.match_job_cards() where company='Match test')<>1 then raise exception 'Second profile not respected'; end if;
  if exists(select 1 from public.match_job_cards() where company='Match test' and title<>'Designer') then raise exception 'Another user preferences used'; end if;
end $$;
reset role;
update roleping_collection.jobs set status='closed' where source_slug='matching-test' and source_job_id='4';
set local role authenticated;
do $$ begin if exists(select 1 from public.match_job_cards() where company='Match test') then raise exception 'Closed job matched'; end if; end $$;
reset role;
set local role anon;
do $$ begin
  begin perform * from public.match_job_cards(); raise exception 'Anonymous match access';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
select 'PASS: role terms, locations, alternatives, unknown policies, explanations, account isolation, closures and anonymous denial' as result;
rollback;
