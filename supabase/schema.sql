-- Milkglass Desk: private, revision-safe manual save sync
-- Run this entire file once in Supabase SQL Editor.

create table if not exists public.habit_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 0 check (revision >= 0),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by text not null default 'unknown'
);

alter table public.habit_saves enable row level security;

revoke all on table public.habit_saves from anon;
grant select, insert, update on table public.habit_saves to authenticated;

-- Re-running setup should replace the policies cleanly.
drop policy if exists "Users can read their own habit save" on public.habit_saves;
drop policy if exists "Users can create their own habit save" on public.habit_saves;
drop policy if exists "Users can update their own habit save" on public.habit_saves;

create policy "Users can read their own habit save"
on public.habit_saves
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can create their own habit save"
on public.habit_saves
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own habit save"
on public.habit_saves
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Atomic compare-and-swap save. The write succeeds only when the browser's
-- expected revision still matches the current cloud revision.
create or replace function public.save_habit_state(
  p_expected_revision bigint,
  p_payload jsonb,
  p_device_id text
)
returns table (
  revision bigint,
  payload jsonb,
  updated_at timestamptz,
  updated_by text
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_expected_revision = 0 then
    insert into public.habit_saves (user_id, revision, payload, updated_at, updated_by)
    values (v_user_id, 1, p_payload, now(), coalesce(nullif(p_device_id, ''), 'unknown'))
    on conflict (user_id) do nothing;

    if found then
      return query
      select h.revision, h.payload, h.updated_at, h.updated_by
      from public.habit_saves h
      where h.user_id = v_user_id;
      return;
    end if;
  end if;

  return query
  update public.habit_saves h
  set revision = h.revision + 1,
      payload = p_payload,
      updated_at = now(),
      updated_by = coalesce(nullif(p_device_id, ''), 'unknown')
  where h.user_id = v_user_id
    and h.revision = p_expected_revision
  returning h.revision, h.payload, h.updated_at, h.updated_by;

  if not found then
    raise exception 'revision_conflict' using errcode = '40001';
  end if;
end;
$$;

revoke all on function public.save_habit_state(bigint, jsonb, text) from public;
grant execute on function public.save_habit_state(bigint, jsonb, text) to authenticated;
