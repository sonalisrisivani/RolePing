-- Public-facing projection: raw evidence and operator state stay private.
create table public.job_cards (
  id uuid primary key references roleping_collection.jobs(id) on delete cascade,
  source_slug text not null,
  title text not null,
  company text not null,
  location text,
  application_url text not null,
  last_seen_at timestamptz not null,
  is_open boolean not null,
  source_enabled boolean not null
);
alter table public.job_cards enable row level security;
revoke all on public.job_cards from public, anon, authenticated;
grant select on public.job_cards to authenticated;
grant select, insert, update on public.job_cards to roleping_collector;
create policy read_open_job_cards on public.job_cards for select to authenticated
  using (is_open and source_enabled);
create policy collector_job_cards on public.job_cards for all to roleping_collector
  using (true) with check (true);

create function roleping_collection.sync_job_card() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  insert into public.job_cards(id, source_slug, title, company, location, application_url, last_seen_at, is_open, source_enabled)
  select new.id, new.source_slug, new.title, s.employer, new.location_text,
    new.application_url, new.last_seen_at, new.status = 'open', s.enabled
  from roleping_collection.sources s where s.slug = new.source_slug
  on conflict(id) do update set source_slug = excluded.source_slug, title = excluded.title,
    company = excluded.company, location = excluded.location, application_url = excluded.application_url,
    last_seen_at = excluded.last_seen_at, is_open = excluded.is_open, source_enabled = excluded.source_enabled;
  return new;
end $$;
revoke all on function roleping_collection.sync_job_card() from public, anon, authenticated;
create trigger sync_job_card after insert or update on roleping_collection.jobs
  for each row execute function roleping_collection.sync_job_card();

create function roleping_collection.sync_source_cards() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  update public.job_cards set company = new.employer, source_enabled = new.enabled
  where source_slug = new.slug;
  return new;
end $$;
revoke all on function roleping_collection.sync_source_cards() from public, anon, authenticated;
create trigger sync_source_cards after update of employer, enabled on roleping_collection.sources
  for each row execute function roleping_collection.sync_source_cards();
create index job_cards_source on public.job_cards(source_slug);

insert into public.job_cards
select j.id, j.source_slug, j.title, s.employer, j.location_text, j.application_url,
  j.last_seen_at, j.status = 'open', s.enabled
from roleping_collection.jobs j join roleping_collection.sources s on s.slug = j.source_slug;
