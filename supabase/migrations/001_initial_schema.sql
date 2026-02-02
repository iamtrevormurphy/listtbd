-- Listapp Database Schema
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================
-- PROFILES TABLE
-- ============================================
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text,
  notification_preferences jsonb default '{"daily_digest": true, "repurchase_reminders": true}'::jsonb,
  created_at timestamptz default now() not null
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Policies
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ============================================
-- LISTS TABLE
-- ============================================
create table if not exists public.lists (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  name text not null default 'Shopping List',
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Enable RLS
alter table public.lists enable row level security;

-- Policies
create policy "Users can view own lists"
  on public.lists for select
  using (auth.uid() = user_id);

create policy "Users can create own lists"
  on public.lists for insert
  with check (auth.uid() = user_id);

create policy "Users can update own lists"
  on public.lists for update
  using (auth.uid() = user_id);

create policy "Users can delete own lists"
  on public.lists for delete
  using (auth.uid() = user_id);

-- Index
create index if not exists lists_user_id_idx on public.lists(user_id);

-- ============================================
-- ITEMS TABLE
-- ============================================
create table if not exists public.items (
  id uuid primary key default uuid_generate_v4(),
  list_id uuid references public.lists(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  category text,
  category_confidence float,
  notes text,
  quantity int default 1 not null,
  is_archived boolean default false not null,
  archived_at timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Enable RLS
alter table public.items enable row level security;

-- Policies
create policy "Users can view own items"
  on public.items for select
  using (auth.uid() = user_id);

create policy "Users can create own items"
  on public.items for insert
  with check (auth.uid() = user_id);

create policy "Users can update own items"
  on public.items for update
  using (auth.uid() = user_id);

create policy "Users can delete own items"
  on public.items for delete
  using (auth.uid() = user_id);

-- Indexes
create index if not exists items_list_id_idx on public.items(list_id);
create index if not exists items_user_id_idx on public.items(user_id);
create index if not exists items_is_archived_idx on public.items(is_archived);

-- ============================================
-- PURCHASE HISTORY TABLE
-- ============================================
create table if not exists public.purchase_history (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  item_name text not null,
  item_name_normalized text not null,
  category text,
  purchased_at timestamptz default now() not null
);

-- Enable RLS
alter table public.purchase_history enable row level security;

-- Policies
create policy "Users can view own purchase history"
  on public.purchase_history for select
  using (auth.uid() = user_id);

create policy "Users can create own purchase history"
  on public.purchase_history for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own purchase history"
  on public.purchase_history for delete
  using (auth.uid() = user_id);

-- Indexes
create index if not exists purchase_history_user_id_idx on public.purchase_history(user_id);
create index if not exists purchase_history_item_normalized_idx on public.purchase_history(item_name_normalized);
create index if not exists purchase_history_purchased_at_idx on public.purchase_history(purchased_at);

-- ============================================
-- REPURCHASE SUGGESTIONS TABLE
-- ============================================
create table if not exists public.repurchase_suggestions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  item_name text not null,
  category text,
  avg_interval_days int,
  last_purchased_at timestamptz,
  suggested_at timestamptz default now() not null,
  status text default 'pending' not null check (status in ('pending', 'added', 'dismissed')),
  dismissed_until timestamptz
);

-- Enable RLS
alter table public.repurchase_suggestions enable row level security;

-- Policies
create policy "Users can view own suggestions"
  on public.repurchase_suggestions for select
  using (auth.uid() = user_id);

create policy "Users can create own suggestions"
  on public.repurchase_suggestions for insert
  with check (auth.uid() = user_id);

create policy "Users can update own suggestions"
  on public.repurchase_suggestions for update
  using (auth.uid() = user_id);

create policy "Users can delete own suggestions"
  on public.repurchase_suggestions for delete
  using (auth.uid() = user_id);

-- Indexes
create index if not exists suggestions_user_id_idx on public.repurchase_suggestions(user_id);
create index if not exists suggestions_status_idx on public.repurchase_suggestions(status);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to automatically create profile on user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'display_name');

  -- Also create a default shopping list
  insert into public.lists (user_id, name)
  values (new.id, 'Shopping List');

  return new;
end;
$$ language plpgsql security definer;

-- Trigger for new user signup
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Function to update updated_at timestamp
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Triggers for updated_at
create trigger update_lists_updated_at
  before update on public.lists
  for each row execute procedure public.update_updated_at();

create trigger update_items_updated_at
  before update on public.items
  for each row execute procedure public.update_updated_at();

-- ============================================
-- REALTIME
-- ============================================

-- Enable realtime for items table (for live updates)
alter publication supabase_realtime add table public.items;
