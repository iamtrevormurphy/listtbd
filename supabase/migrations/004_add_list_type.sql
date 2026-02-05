-- Add list type column to support different list behaviors
-- grocery: Aisle categories + stores (default)
-- shopping: Shopping categories + stores
-- project: No categories, no stores

ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS type text DEFAULT 'grocery';
