-- Live, invoker-only matching: callers cannot select another user's profile.
-- No persisted matches until extraction quality and ranking are validated.
create function public.job_match_text(value text) returns text
language sql immutable security invoker set search_path = '' as $$
  select trim(regexp_replace(lower(coalesce(value, '')), '[-/(),[:space:]]+', ' ', 'g'));
$$;
revoke all on function public.job_match_text(text) from public, anon;
grant execute on function public.job_match_text(text) to authenticated;

create function public.match_job_cards()
returns table(id uuid, title text, company text, location text, application_url text,
  last_seen_at timestamptz, reasons text[], caveats text[])
language sql stable security invoker set search_path = '' as $$
  with preferences as (
    select * from public.profiles where user_id = (select auth.uid())
      and unknown_salary_policy = 'include_with_caveat'
      and eligibility_policy = 'include_with_caveat'
  )
  select j.id, j.title, j.company, j.location, j.application_url, j.last_seen_at,
    array['Title contains role terms: ' || r.term, 'Location contains: ' || l.term],
    array['Salary and eligibility are unconfirmed.', 'Current availability must be checked on the employer site.']
      || case when p.salary_floor is not null then array['Your minimum salary cannot be verified.'] else array[]::text[] end
      || case when p.work_mode <> 'any' then array['Your work mode preference cannot be verified.'] else array[]::text[] end
      || case when p.role_type <> 'any' then array['Your employment type preference cannot be verified.'] else array[]::text[] end
      || case when public.job_match_text(l.term) = 'remote' then array['Remote country and timezone restrictions are unconfirmed.'] else array[]::text[] end
  from public.job_cards j cross join preferences p
  cross join lateral (
    select trim(term) as term from unnest(string_to_array(p.target_role, ',')) term
    where public.job_match_text(term) <> '' and not exists (
      select 1 from unnest(string_to_array(public.job_match_text(term), ' ')) token
      where strpos(' ' || public.job_match_text(j.title) || ' ', ' ' || token || ' ') = 0
    ) order by length(term) desc, term limit 1
  ) r
  cross join lateral (
    select trim(term) as term from unnest(string_to_array(p.location, ',')) term
    where public.job_match_text(term) <> ''
      and strpos(' ' || public.job_match_text(j.location) || ' ', ' ' || public.job_match_text(term) || ' ') > 0
    order by length(term) desc, term limit 1
  ) l
  order by j.last_seen_at desc, j.title, j.id;
$$;
revoke all on function public.match_job_cards() from public, anon;
grant execute on function public.match_job_cards() to authenticated;
