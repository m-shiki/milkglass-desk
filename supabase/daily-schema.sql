-- Daily edition. The original app keeps using public.habit_saves.
begin;

create table if not exists public.habit_daily_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null check (revision > 0),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null default now()
);

alter table public.habit_daily_saves enable row level security;
revoke all on public.habit_daily_saves from public, anon, authenticated;
grant select, insert, update on public.habit_daily_saves to authenticated;

drop policy if exists "Daily saves belong to their owner" on public.habit_daily_saves;
create policy "Daily saves belong to their owner"
  on public.habit_daily_saves for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function public.save_daily_habit_state(
  p_expected_revision bigint,
  p_payload jsonb
)
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare
  owner_id uuid := auth.uid();
  saved_revision bigint;
begin
  if owner_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_expected_revision = 0 then
    insert into public.habit_daily_saves (user_id, revision, payload)
    values (owner_id, 1, p_payload)
    on conflict (user_id) do nothing
    returning revision into saved_revision;
  else
    update public.habit_daily_saves
    set revision = revision + 1, payload = p_payload, updated_at = now()
    where user_id = owner_id and revision = p_expected_revision
    returning revision into saved_revision;
  end if;

  if saved_revision is null then
    raise exception 'revision_conflict' using errcode = '40001';
  end if;
  return saved_revision;
end;
$$;

revoke all on function public.save_daily_habit_state(bigint, jsonb) from public, anon;
grant execute on function public.save_daily_habit_state(bigint, jsonb) to authenticated;

commit;
