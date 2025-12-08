-- Adicionar novos campos para suportar timestamps completos e breakdown de horas
ALTER TABLE time_entries 
  ADD COLUMN IF NOT EXISTS check_in_at timestamptz,
  ADD COLUMN IF NOT EXISTS check_out_at timestamptz,
  ADD COLUMN IF NOT EXISTS service_order_id uuid REFERENCES service_orders(id),
  ADD COLUMN IF NOT EXISTS hours_normal numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hours_extra numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hours_night numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hours_standby numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS notes text;

-- Tornar task_id opcional
ALTER TABLE time_entries ALTER COLUMN task_id DROP NOT NULL;

-- Migrar dados existentes para novos campos
UPDATE time_entries 
SET 
  check_in_at = COALESCE(check_in_at, (entry_date::text || ' ' || start_time::text)::timestamptz),
  check_out_at = COALESCE(check_out_at, (entry_date::text || ' ' || end_time::text)::timestamptz),
  hours_normal = CASE WHEN entry_type = 'work_normal' AND hours_normal = 0 THEN 
    EXTRACT(EPOCH FROM (end_time - start_time)) / 3600 ELSE hours_normal END,
  hours_extra = CASE WHEN entry_type = 'work_extra' AND hours_extra = 0 THEN 
    EXTRACT(EPOCH FROM (end_time - start_time)) / 3600 ELSE hours_extra END,
  hours_night = CASE WHEN entry_type = 'work_night' AND hours_night = 0 THEN 
    EXTRACT(EPOCH FROM (end_time - start_time)) / 3600 ELSE hours_night END,
  hours_standby = CASE WHEN entry_type = 'standby' AND hours_standby = 0 THEN 
    EXTRACT(EPOCH FROM (end_time - start_time)) / 3600 ELSE hours_standby END
WHERE check_in_at IS NULL OR check_out_at IS NULL;

-- RLS: HR pode gerenciar time_entries da empresa
CREATE POLICY "HR can manage company time entries"
ON public.time_entries FOR ALL TO authenticated
USING (
  has_role(auth.uid(), 'hr'::app_role) 
  AND EXISTS (
    SELECT 1 FROM technicians t 
    WHERE t.id = time_entries.technician_id 
    AND t.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'hr'::app_role) 
  AND EXISTS (
    SELECT 1 FROM technicians t 
    WHERE t.id = time_entries.technician_id 
    AND t.company_id = user_company_id(auth.uid())
  )
);

-- RLS: HR pode ver tasks da empresa
CREATE POLICY "HR can view company tasks"
ON public.tasks FOR SELECT TO authenticated
USING (has_role(auth.uid(), 'hr'::app_role) AND task_in_user_company(auth.uid(), id));

-- RLS: HR pode ver service_orders da empresa
CREATE POLICY "HR can view company service orders"
ON public.service_orders FOR SELECT TO authenticated
USING (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()));