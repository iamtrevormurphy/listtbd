-- Add description and icon fields to lists table
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS icon text;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS lists_updated_at_idx ON public.lists(updated_at DESC);
