alter table public.profiles
  add column role_type text not null default 'any'
    check (role_type in ('any', 'full_time', 'internship')),
  add column work_mode text not null default 'any'
    check (work_mode in ('any', 'remote', 'hybrid', 'onsite')),
  add column salary_floor numeric(12, 2)
    check (salary_floor >= 0),
  add column salary_currency text
    check (salary_currency is null or salary_currency ~ '^[A-Z]{3}$'),
  add column salary_period text
    check (salary_period is null or salary_period in ('year', 'month', 'hour')),
  add column unknown_salary_policy text
    check (unknown_salary_policy is null or unknown_salary_policy in ('include_with_caveat', 'exclude')),
  add column eligibility_policy text
    check (eligibility_policy is null or eligibility_policy in ('include_with_caveat', 'confirmed_only')),
  add constraint salary_floor_units_required
    check (salary_floor is null or (salary_currency is not null and salary_period is not null));
