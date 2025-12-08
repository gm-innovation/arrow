-- Add is_travel and is_overnight columns to time_entries table
ALTER TABLE time_entries 
ADD COLUMN IF NOT EXISTS is_travel BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_overnight BOOLEAN DEFAULT false;

-- Add comments for documentation
COMMENT ON COLUMN time_entries.is_travel IS 'Indicates if the technician traveled on this day';
COMMENT ON COLUMN time_entries.is_overnight IS 'Indicates if the technician stayed overnight at a hotel';