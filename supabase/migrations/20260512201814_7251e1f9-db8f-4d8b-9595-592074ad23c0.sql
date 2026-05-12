
-- ============================================================
-- Recrutamento: vagas, candidaturas, notas, bucket
-- ============================================================

-- 1) Tabelas
CREATE TABLE public.job_openings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  area text,
  description text,
  location text,
  employment_type text,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_job_openings_company ON public.job_openings(company_id, is_active);

CREATE TABLE public.job_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  job_opening_id uuid REFERENCES public.job_openings(id) ON DELETE SET NULL,
  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  city text,
  state text,
  linkedin_url text,
  area_of_interest text,
  salary_expectation numeric,
  availability text,
  cover_letter text,
  cv_file_url text,
  cv_file_name text,
  status text NOT NULL DEFAULT 'new',
  source text NOT NULL DEFAULT 'site',
  reviewed_by uuid,
  reviewed_at timestamptz,
  ip text,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_job_applications_company_status ON public.job_applications(company_id, status, created_at DESC);
CREATE INDEX idx_job_applications_opening ON public.job_applications(job_opening_id);

CREATE TABLE public.job_application_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES public.job_applications(id) ON DELETE CASCADE,
  author_id uuid NOT NULL,
  note text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_job_app_notes_application ON public.job_application_notes(application_id, created_at DESC);

ALTER TABLE public.employee_onboarding
  ADD COLUMN IF NOT EXISTS job_application_id uuid REFERENCES public.job_applications(id) ON DELETE SET NULL;

-- 2) Triggers updated_at
CREATE TRIGGER trg_job_openings_updated
  BEFORE UPDATE ON public.job_openings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_job_applications_updated
  BEFORE UPDATE ON public.job_applications
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 3) RLS
ALTER TABLE public.job_openings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_application_notes ENABLE ROW LEVEL SECURITY;

-- job_openings: RH/Diretor da empresa gerenciam tudo; público lê ativas
CREATE POLICY "HR/Director manage openings"
ON public.job_openings FOR ALL
USING (public.is_hr_or_director_in_company(auth.uid(), company_id))
WITH CHECK (public.is_hr_or_director_in_company(auth.uid(), company_id));

CREATE POLICY "Public can view active openings"
ON public.job_openings FOR SELECT
USING (is_active = true);

-- job_applications: somente RH/Diretor da empresa
CREATE POLICY "HR/Director manage applications"
ON public.job_applications FOR ALL
USING (public.is_hr_or_director_in_company(auth.uid(), company_id))
WITH CHECK (public.is_hr_or_director_in_company(auth.uid(), company_id));

-- job_application_notes: RH/Diretor que pode ver a candidatura
CREATE POLICY "HR/Director manage notes"
ON public.job_application_notes FOR ALL
USING (EXISTS (
  SELECT 1 FROM public.job_applications ja
  WHERE ja.id = application_id
    AND public.is_hr_or_director_in_company(auth.uid(), ja.company_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.job_applications ja
  WHERE ja.id = application_id
    AND public.is_hr_or_director_in_company(auth.uid(), ja.company_id)
));

-- 4) Bucket de currículos (privado)
INSERT INTO storage.buckets (id, name, public)
VALUES ('recruitment-cvs', 'recruitment-cvs', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "HR/Director read cvs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'recruitment-cvs'
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.company_id::text = (storage.foldername(name))[1]
      AND (public.has_role(auth.uid(), 'hr'::app_role)
           OR public.has_role(auth.uid(), 'director'::app_role)
           OR public.has_role(auth.uid(), 'admin'::app_role))
  )
);

-- 5) Trigger de notificação para RH ao chegar nova candidatura
CREATE OR REPLACE FUNCTION public.notify_hr_on_new_application()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  FOR v_user_id IN
    SELECT DISTINCT ur.user_id
    FROM public.user_roles ur
    JOIN public.profiles p ON p.id = ur.user_id
    WHERE ur.role IN ('hr','director')
      AND p.company_id = NEW.company_id
  LOOP
    INSERT INTO public.notifications (user_id, title, message, notification_type, reference_id, read)
    VALUES (
      v_user_id,
      'Novo currículo recebido',
      'Candidato: ' || NEW.full_name || ' <' || NEW.email || '>',
      'request_created',
      NEW.id,
      false
    );
  END LOOP;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_hr_new_application
  AFTER INSERT ON public.job_applications
  FOR EACH ROW EXECUTE FUNCTION public.notify_hr_on_new_application();
