-- Initial user settings for the first runnable frontend slice.
-- Later migrations will add jobs, matching, source runs, and delivery state.
create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '' check (length(full_name) <= 120),
  target_role text not null default '' check (length(target_role) <= 300),
  location text not null default '' check (length(location) <= 300),
  digest_time time without time zone not null default time '07:00',
  timezone text not null default 'Asia/Kolkata' check (length(timezone) <= 100),
  paused boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;
grant select, insert, update on public.profiles to authenticated;

create policy "users_read_own_profile"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "users_insert_own_profile"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "users_update_own_profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
