
-- Enum for exam types
DO $$ BEGIN
  CREATE TYPE public.hr_health_exam_type AS ENUM (
    'admissional',
    'periodico',
    'mudanca_funcao',
    'retorno_trabalho',
    'demissional'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.hr_health_exam_result AS ENUM (
    'apto',
    'apto_com_restricao',
    'inapto',
    'pendente'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Settings table (periodicity per exam type)
CREATE TABLE IF NOT EXISTS public.hr_health_exam_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_type public.hr_health_exam_type NOT NULL UNIQUE,
  periodicity_months INTEGER NOT NULL DEFAULT 12,
  alert_days_before INTEGER NOT NULL DEFAULT 60,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.hr_health_exam_settings TO authenticated;
GRANT ALL ON public.hr_health_exam_settings TO service_role;
ALTER TABLE public.hr_health_exam_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "HR can view exam settings"
  ON public.hr_health_exam_settings FOR SELECT
  TO authenticated
  USING (
    public.has_role(auth.uid(), 'hr'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  );

CREATE POLICY "HR can manage exam settings"
  ON public.hr_health_exam_settings FOR ALL
  TO authenticated
  USING (
    public.has_role(auth.uid(), 'hr'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'hr'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  );

-- Main exams table
CREATE TABLE IF NOT EXISTS public.hr_health_exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  exam_type public.hr_health_exam_type NOT NULL,
  exam_date DATE NOT NULL,
  next_exam_date DATE,
  clinic_name TEXT,
  doctor_name TEXT,
  doctor_crm TEXT,
  result public.hr_health_exam_result NOT NULL DEFAULT 'pendente',
  restrictions TEXT,
  observations TEXT,
  attachment_path TEXT,
  attachment_name TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hr_health_exams_employee ON public.hr_health_exams(employee_id);
CREATE INDEX IF NOT EXISTS idx_hr_health_exams_next_date ON public.hr_health_exams(next_exam_date);
CREATE INDEX IF NOT EXISTS idx_hr_health_exams_type ON public.hr_health_exams(exam_type);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.hr_health_exams TO authenticated;
GRANT ALL ON public.hr_health_exams TO service_role;

ALTER TABLE public.hr_health_exams ENABLE ROW LEVEL SECURITY;

-- Employee sees own exams
CREATE POLICY "Employees view own exams"
  ON public.hr_health_exams FOR SELECT
  TO authenticated
  USING (employee_id = auth.uid());

-- HR / Director / Super Admin see all
CREATE POLICY "HR views all exams"
  ON public.hr_health_exams FOR SELECT
  TO authenticated
  USING (
    public.has_role(auth.uid(), 'hr'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  );

-- Direct manager sees subordinate exams
CREATE POLICY "Manager views subordinate exams"
  ON public.hr_health_exams FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = hr_health_exams.employee_id
        AND p.direct_manager_id = auth.uid()
    )
  );

CREATE POLICY "HR manages exams"
  ON public.hr_health_exams FOR ALL
  TO authenticated
  USING (
    public.has_role(auth.uid(), 'hr'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'hr'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  );

-- Trigger to auto-calc next_exam_date and updated_at
CREATE OR REPLACE FUNCTION public.hr_health_exam_calc_next_date()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_months INTEGER;
BEGIN
  NEW.updated_at = now();

  -- Only recalc if next_exam_date not explicitly provided (or on insert)
  IF NEW.next_exam_date IS NULL AND NEW.exam_date IS NOT NULL THEN
    SELECT periodicity_months INTO v_months
      FROM public.hr_health_exam_settings
     WHERE exam_type = NEW.exam_type;

    IF v_months IS NOT NULL AND v_months > 0 THEN
      NEW.next_exam_date = NEW.exam_date + (v_months || ' months')::interval;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_hr_health_exam_calc_next ON public.hr_health_exams;
CREATE TRIGGER trg_hr_health_exam_calc_next
  BEFORE INSERT OR UPDATE ON public.hr_health_exams
  FOR EACH ROW EXECUTE FUNCTION public.hr_health_exam_calc_next_date();

-- Seed default settings
INSERT INTO public.hr_health_exam_settings (exam_type, periodicity_months, alert_days_before, description) VALUES
  ('admissional',      0,  0,  'Realizado antes do início das atividades'),
  ('periodico',        12, 60, 'Anual conforme NR-7 / PCMSO'),
  ('mudanca_funcao',   0,  0,  'Antes da mudança de função com novo risco'),
  ('retorno_trabalho', 0,  0,  'Retorno após afastamento igual ou superior a 30 dias'),
  ('demissional',      0,  0,  'Realizado no desligamento do colaborador')
ON CONFLICT (exam_type) DO NOTHING;
