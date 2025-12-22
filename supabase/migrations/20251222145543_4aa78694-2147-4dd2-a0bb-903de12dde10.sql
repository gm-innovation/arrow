-- Tornar technician_id nullable nas tabelas de histórico para permitir ON DELETE SET NULL

-- time_entries
ALTER TABLE public.time_entries 
ALTER COLUMN technician_id DROP NOT NULL;

-- visit_technicians
ALTER TABLE public.visit_technicians 
ALTER COLUMN technician_id DROP NOT NULL;

-- checklist_responses
ALTER TABLE public.checklist_responses 
ALTER COLUMN technician_id DROP NOT NULL;

-- productivity_snapshots
ALTER TABLE public.productivity_snapshots 
ALTER COLUMN technician_id DROP NOT NULL;

-- technician_absences
ALTER TABLE public.technician_absences 
ALTER COLUMN technician_id DROP NOT NULL;

-- technician_on_call
ALTER TABLE public.technician_on_call 
ALTER COLUMN technician_id DROP NOT NULL;

-- hr_time_adjustments
ALTER TABLE public.hr_time_adjustments 
ALTER COLUMN technician_id DROP NOT NULL;