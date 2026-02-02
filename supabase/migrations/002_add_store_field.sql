-- Migration: Add store field to items table
-- Run this in your Supabase SQL Editor after 001_initial_schema.sql

-- Add store column to items table
ALTER TABLE public.items
ADD COLUMN IF NOT EXISTS store text;

-- Create index for store-based queries
CREATE INDEX IF NOT EXISTS items_store_idx ON public.items(store);

-- Create a stores table to track user's stores
CREATE TABLE IF NOT EXISTS public.stores (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Enable RLS on stores
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Policies for stores
CREATE POLICY "Users can view own stores"
  ON public.stores FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own stores"
  ON public.stores FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own stores"
  ON public.stores FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own stores"
  ON public.stores FOR DELETE
  USING (auth.uid() = user_id);

-- Index for user's stores
CREATE INDEX IF NOT EXISTS stores_user_id_idx ON public.stores(user_id);
