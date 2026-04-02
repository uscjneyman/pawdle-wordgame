-- Community posts: public "show off" feed
create table if not exists community_posts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade not null,
  username    text not null,
  word        text not null,
  tries       int not null,
  max_attempts int not null,
  sticker_emoji text not null,
  sticker_name  text not null,
  sticker_rarity text not null,
  paw_points_earned int,
  category    text,
  difficulty  int,
  word_length int,
  created_at  timestamptz default now() not null
);

-- Index for feed ordering
create index if not exists idx_community_posts_created
  on community_posts (created_at desc);

-- RLS: anyone authenticated can read all posts
alter table community_posts enable row level security;

create policy "Anyone can read community posts"
  on community_posts for select
  using (true);

create policy "Authenticated users can insert own posts"
  on community_posts for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own posts"
  on community_posts for delete
  using (auth.uid() = user_id);
