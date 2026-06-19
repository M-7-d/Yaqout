-- Create follows table
create table if not exists public.follows (
  id          uuid primary key default gen_random_uuid(),
  follower_id uuid references public.profiles(id) on delete cascade not null,
  seller_id   uuid references public.profiles(id) on delete cascade not null,
  created_at  timestamptz default now(),
  unique(follower_id, seller_id)
);

-- Enable Row Level Security
alter table public.follows enable row level security;

-- Policy: users can insert/delete their own follows
create policy "Users can manage their own follows"
  on public.follows for all
  using (auth.uid() = follower_id)
  with check (auth.uid() = follower_id);

-- Policy: anyone can read follows (needed by edge function via service role)
create policy "Anyone can read follows"
  on public.follows for select
  using (true);
