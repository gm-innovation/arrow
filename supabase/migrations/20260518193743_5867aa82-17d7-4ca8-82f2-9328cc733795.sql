
-- Tabela de tags por empresa
CREATE TABLE public.job_application_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  name text NOT NULL,
  color text NOT NULL DEFAULT '#6366f1',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, name)
);

ALTER TABLE public.job_application_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "HR/Director/Coordinator can view tags"
ON public.job_application_tags FOR SELECT TO authenticated
USING (
  has_role(auth.uid(), 'super_admin'::app_role) OR
  (company_id = user_company_id(auth.uid()) AND (
    has_role(auth.uid(), 'hr'::app_role) OR
    has_role(auth.uid(), 'director'::app_role) OR
    has_role(auth.uid(), 'coordinator'::app_role) OR
    has_role(auth.uid(), 'admin'::app_role)
  ))
);

CREATE POLICY "HR/Director/Coordinator can insert tags"
ON public.job_application_tags FOR INSERT TO authenticated
WITH CHECK (
  company_id = user_company_id(auth.uid()) AND (
    has_role(auth.uid(), 'hr'::app_role) OR
    has_role(auth.uid(), 'director'::app_role) OR
    has_role(auth.uid(), 'coordinator'::app_role) OR
    has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "HR/Director/Coordinator can update tags"
ON public.job_application_tags FOR UPDATE TO authenticated
USING (
  company_id = user_company_id(auth.uid()) AND (
    has_role(auth.uid(), 'hr'::app_role) OR
    has_role(auth.uid(), 'director'::app_role) OR
    has_role(auth.uid(), 'coordinator'::app_role) OR
    has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "HR/Director/Coordinator can delete tags"
ON public.job_application_tags FOR DELETE TO authenticated
USING (
  company_id = user_company_id(auth.uid()) AND (
    has_role(auth.uid(), 'hr'::app_role) OR
    has_role(auth.uid(), 'director'::app_role) OR
    has_role(auth.uid(), 'admin'::app_role)
  )
);

-- Atribuições de tags a candidaturas
CREATE TABLE public.job_application_tag_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES public.job_applications(id) ON DELETE CASCADE,
  tag_id uuid NOT NULL REFERENCES public.job_application_tags(id) ON DELETE CASCADE,
  assigned_by uuid,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (application_id, tag_id)
);

CREATE INDEX idx_jata_application ON public.job_application_tag_assignments(application_id);
CREATE INDEX idx_jata_tag ON public.job_application_tag_assignments(tag_id);

ALTER TABLE public.job_application_tag_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "HR/Director/Coordinator can view assignments"
ON public.job_application_tag_assignments FOR SELECT TO authenticated
USING (
  has_role(auth.uid(), 'super_admin'::app_role) OR
  EXISTS (
    SELECT 1 FROM public.job_applications ja
    WHERE ja.id = application_id
      AND ja.company_id = user_company_id(auth.uid())
      AND (
        has_role(auth.uid(), 'hr'::app_role) OR
        has_role(auth.uid(), 'director'::app_role) OR
        has_role(auth.uid(), 'coordinator'::app_role) OR
        has_role(auth.uid(), 'admin'::app_role)
      )
  )
);

CREATE POLICY "HR/Director/Coordinator can insert assignments"
ON public.job_application_tag_assignments FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.job_applications ja
    WHERE ja.id = application_id
      AND ja.company_id = user_company_id(auth.uid())
      AND (
        has_role(auth.uid(), 'hr'::app_role) OR
        has_role(auth.uid(), 'director'::app_role) OR
        has_role(auth.uid(), 'coordinator'::app_role) OR
        has_role(auth.uid(), 'admin'::app_role)
      )
  )
);

CREATE POLICY "HR/Director/Coordinator can delete assignments"
ON public.job_application_tag_assignments FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.job_applications ja
    WHERE ja.id = application_id
      AND ja.company_id = user_company_id(auth.uid())
      AND (
        has_role(auth.uid(), 'hr'::app_role) OR
        has_role(auth.uid(), 'director'::app_role) OR
        has_role(auth.uid(), 'coordinator'::app_role) OR
        has_role(auth.uid(), 'admin'::app_role)
      )
  )
);

-- Coluna para guardar extração do CV
ALTER TABLE public.job_applications
ADD COLUMN IF NOT EXISTS cv_extracted_data jsonb;
