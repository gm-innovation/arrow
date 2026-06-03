
ALTER TABLE public.epi_items DROP COLUMN IF EXISTS ca_number;
ALTER TABLE public.epi_items DROP COLUMN IF EXISTS ca_expires_at;

CREATE TABLE public.home_office_schedules (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID NOT NULL,
  technician_id UUID NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  notes TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_home_office_company ON public.home_office_schedules(company_id);
CREATE INDEX idx_home_office_technician ON public.home_office_schedules(technician_id);
CREATE INDEX idx_home_office_dates ON public.home_office_schedules(start_date, end_date);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.home_office_schedules TO authenticated;
GRANT ALL ON public.home_office_schedules TO service_role;

ALTER TABLE public.home_office_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "HR/Director/Coord manage home office"
ON public.home_office_schedules
FOR ALL
TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.company_id = home_office_schedules.company_id)
  AND (
    public.has_role(auth.uid(), 'hr'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'coordinator'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
)
WITH CHECK (
  EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.company_id = home_office_schedules.company_id)
  AND (
    public.has_role(auth.uid(), 'hr'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'coordinator'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE POLICY "Technician views own home office"
ON public.home_office_schedules
FOR SELECT
TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.technicians t WHERE t.id = home_office_schedules.technician_id AND t.user_id = auth.uid())
);

CREATE TRIGGER trg_home_office_updated_at
BEFORE UPDATE ON public.home_office_schedules
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();
