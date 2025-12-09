-- Add new columns to time_entries for manual entry of vessel, coordinator and status flags
ALTER TABLE public.time_entries 
ADD COLUMN IF NOT EXISTS vessel_name text,
ADD COLUMN IF NOT EXISTS coordinator_name text,
ADD COLUMN IF NOT EXISTS is_onboard boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS is_standby boolean DEFAULT false;

-- Add comment for documentation
COMMENT ON COLUMN public.time_entries.vessel_name IS 'Nome do barco (manual ou preenchido via OS)';
COMMENT ON COLUMN public.time_entries.coordinator_name IS 'Nome do coordenador (manual ou preenchido via OS)';
COMMENT ON COLUMN public.time_entries.is_onboard IS 'Técnico esteve a bordo do navio';
COMMENT ON COLUMN public.time_entries.is_standby IS 'Técnico estava de sobreaviso';