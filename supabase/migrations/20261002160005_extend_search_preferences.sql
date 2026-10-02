alter table public.profiles
  add column years_experience numeric check (years_experience >= 0 and years_experience < 'Infinity'::numeric),
  add column skills text not null default 'any' check (length(trim(skills)) > 0 and length(skills) <= 1000);
comment on column public.profiles.years_experience is 'Candidate experience in years; null means unspecified, zero means no experience.';
comment on column public.profiles.skills is 'Comma-separated candidate skills or any. Requirements extraction is not yet implemented.';

create or replace function public.match_job_cards()
returns table(id uuid, title text, company text, location text, application_url text,
  last_seen_at timestamptz, reasons text[], caveats text[])
language sql stable security invoker set search_path = '' as $$
  with preferences as (
    select * from public.profiles where user_id = (select auth.uid())
      and unknown_salary_policy = 'include_with_caveat'
      and eligibility_policy = 'include_with_caveat'
  )
  select j.id, j.title, j.company, j.location, j.application_url, j.last_seen_at,
    array[case when lower(trim(p.target_role)) = 'any' then 'Any role selected' else 'Title contains role terms: ' || r.term end, case when lower(trim(p.location)) = 'any' then 'Any location selected' else 'Location contains: ' || l.term end],
    array['Salary and eligibility are unconfirmed.', 'Current availability must be checked on the employer site.']
      || case when p.years_experience is not null then array['Experience requirements are unverified; your experience has not been used to exclude jobs.'] else array[]::text[] end
      || case when lower(trim(p.skills)) <> 'any' then array['Skill requirements are unverified; your skills have not been used to exclude jobs.'] else array[]::text[] end
      || case when j.location is null then array['Location is not listed.'] else array[]::text[] end
      || case when p.salary_floor is not null then array['Your minimum salary cannot be verified.'] else array[]::text[] end
      || case when p.work_mode <> 'any' then array['Your work mode preference cannot be verified.'] else array[]::text[] end
      || case when p.role_type <> 'any' then array['Your employment type preference cannot be verified.'] else array[]::text[] end
      || case when public.job_match_text(l.term) = 'remote' then array['Remote country and timezone restrictions are unconfirmed.'] else array[]::text[] end
  from public.job_cards j cross join preferences p
  cross join lateral (
    select trim(term) as term from unnest(string_to_array(p.target_role, ',')) term
    where lower(trim(p.target_role)) = 'any' or (public.job_match_text(term) <> '' and not exists (
      select 1 from unnest(string_to_array(public.job_match_text(term), ' ')) token
      where strpos(' ' || public.job_match_text(j.title) || ' ', ' ' || token || ' ') = 0
    )) order by length(term) desc, term limit 1
  ) r
  cross join lateral (
    select trim(term) as term from unnest(string_to_array(p.location, ',')) term
    where lower(trim(p.location)) = 'any' or (public.job_match_text(term) <> ''
      and strpos(' ' || public.job_match_text(j.location) || ' ', ' ' || public.job_match_text(term) || ' ') > 0)
    order by length(term) desc, term limit 1
  ) l
  order by j.last_seen_at desc, j.title, j.id;
$$;
revoke all on function public.match_job_cards() from public, anon;
grant execute on function public.match_job_cards() to authenticated;
