-- Run as the database administrator. All fixtures and writes are rolled back.
begin;
insert into auth.users (id) values
  ('a6100210-0000-4000-8000-000000000001'),
  ('a6100210-0000-4000-8000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub', 'a6100210-0000-4000-8000-000000000001', true);
insert into public.profiles (user_id, target_role, location, unknown_salary_policy, eligibility_policy)
values (auth.uid(), 'Engineer', 'Remote', 'exclude', 'confirmed_only');
update public.profiles set paused = true, digest_time = '09:30' where user_id = auth.uid();
do $$ begin
  if not exists (select 1 from public.profiles where user_id = auth.uid() and paused and digest_time = '09:30') then
    raise exception 'Own preference save/reload failed';
  end if;
end $$;
select set_config('request.jwt.claim.sub', 'a6100210-0000-4000-8000-000000000002', true);
do $$ declare affected integer; begin
  if exists (select 1 from public.profiles where user_id = 'a6100210-0000-4000-8000-000000000001') then
    raise exception 'Other account can read profile';
  end if;
  update public.profiles set paused = false where user_id = 'a6100210-0000-4000-8000-000000000001';
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'Other account can update profile'; end if;
  begin
    insert into public.profiles (user_id) values ('a6100210-0000-4000-8000-000000000001');
    raise exception 'Other account can insert profile';
  exception when insufficient_privilege then null;
  end;
end $$;
insert into public.profiles (user_id) values (auth.uid());
do $$ begin
  begin
    update public.profiles set user_id = 'a6100210-0000-4000-8000-000000000003' where user_id = auth.uid();
    raise exception 'Account can transfer profile ownership';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.profiles where user_id = auth.uid();
    raise exception 'Client can delete profile';
  exception when insufficient_privilege then null;
  end;
end $$;
set local role anon;
do $$ begin
  begin
    perform * from public.profiles;
    raise exception 'Anonymous profile read allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.profiles (user_id) values ('a6100210-0000-4000-8000-000000000003');
    raise exception 'Anonymous profile write allowed';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
select 'PASS: preference round trip, account isolation, ownership and anonymous access' as result;
rollback;
