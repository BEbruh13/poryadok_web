-- Порядок: таблица для задач, событий, заметок и проектов.
-- Выполните один раз: Supabase → SQL Editor → New query → вставить → Run.

create table if not exists public.items (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  kind       text not null check (kind in ('tasks', 'events', 'notes', 'projects')),
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

create index if not exists items_user_id_idx on public.items (user_id);

-- Каждый видит и меняет только свои записи.
alter table public.items enable row level security;

drop policy if exists "items_select_own" on public.items;
drop policy if exists "items_insert_own" on public.items;
drop policy if exists "items_update_own" on public.items;
drop policy if exists "items_delete_own" on public.items;

create policy "items_select_own" on public.items for select to authenticated using ((select auth.uid()) = user_id);
create policy "items_insert_own" on public.items for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "items_update_own" on public.items for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "items_delete_own" on public.items for delete to authenticated using ((select auth.uid()) = user_id);

-- Мгновенная синхронизация между устройствами.
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'items') then
    alter publication supabase_realtime add table public.items;
  end if;
end $$;
