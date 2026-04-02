-- Player profile + won words persistence for Paw-dle
-- Apply with: supabase db push

create extension if not exists pgcrypto;

create table if not exists public.player_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  paw_points integer not null default 2 check (paw_points >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.won_words (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  word text not null,
  tries integer not null check (tries > 0),
  max_attempts integer not null check (max_attempts > 0),
  won_at timestamptz not null default now(),
  sticker_id text not null,
  sticker_name text not null,
  sticker_emoji text not null,
  sticker_rarity text not null,
  paw_points_earned integer,
  category text,
  difficulty integer,
  word_length integer,
  created_at timestamptz not null default now()
);

create index if not exists idx_won_words_user_date on public.won_words(user_id, won_at desc);

alter table public.player_profiles enable row level security;
alter table public.won_words enable row level security;

drop policy if exists "player_profiles_owner_select" on public.player_profiles;
create policy "player_profiles_owner_select"
on public.player_profiles
for select
using (auth.uid() = user_id);

drop policy if exists "player_profiles_owner_insert" on public.player_profiles;
create policy "player_profiles_owner_insert"
on public.player_profiles
for insert
with check (auth.uid() = user_id);

drop policy if exists "player_profiles_owner_update" on public.player_profiles;
create policy "player_profiles_owner_update"
on public.player_profiles
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "player_profiles_owner_delete" on public.player_profiles;
create policy "player_profiles_owner_delete"
on public.player_profiles
for delete
using (auth.uid() = user_id);

drop policy if exists "won_words_owner_select" on public.won_words;
create policy "won_words_owner_select"
on public.won_words
for select
using (auth.uid() = user_id);

drop policy if exists "won_words_owner_insert" on public.won_words;
create policy "won_words_owner_insert"
on public.won_words
for insert
with check (auth.uid() = user_id);

drop policy if exists "won_words_owner_update" on public.won_words;
create policy "won_words_owner_update"
on public.won_words
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "won_words_owner_delete" on public.won_words;
create policy "won_words_owner_delete"
on public.won_words
for delete
using (auth.uid() = user_id);
