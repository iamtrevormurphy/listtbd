-- Add sort_order column to items table for drag-and-drop reordering in project lists
-- Items are ordered by sort_order ASC, then created_at DESC

ALTER TABLE public.items ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

-- Create index for efficient ordering queries
CREATE INDEX IF NOT EXISTS idx_items_sort_order ON public.items (list_id, sort_order);
