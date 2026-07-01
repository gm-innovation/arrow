
ALTER TABLE public.quality_context_items
  ADD COLUMN IF NOT EXISTS department_id uuid NULL REFERENCES public.departments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS analysis_period text NULL;

CREATE INDEX IF NOT EXISTS idx_quality_context_items_dept_period
  ON public.quality_context_items (company_id, department_id, analysis_period, category);

ALTER TABLE public.quality_interested_parties
  ADD COLUMN IF NOT EXISTS power_level smallint NULL CHECK (power_level BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS interest_level smallint NULL CHECK (interest_level BETWEEN 1 AND 5);

DO $$ BEGIN
  CREATE TYPE public.quality_party_process_relationship AS ENUM
    ('cliente','fornecedor','fiscaliza','recebe_informacao','executa','impacta','influencia');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.quality_party_process_relevance AS ENUM ('low','medium','high');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.quality_interested_party_processes (
  party_id uuid NOT NULL REFERENCES public.quality_interested_parties(id) ON DELETE CASCADE,
  process_id uuid NOT NULL REFERENCES public.quality_processes(id) ON DELETE CASCADE,
  relevance public.quality_party_process_relevance NOT NULL DEFAULT 'medium',
  relationship_type public.quality_party_process_relationship NOT NULL DEFAULT 'impacta',
  company_id uuid NOT NULL,
  created_by uuid NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (party_id, process_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_interested_party_processes TO authenticated;
GRANT ALL ON public.quality_interested_party_processes TO service_role;

ALTER TABLE public.quality_interested_party_processes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "party_processes_select_company" ON public.quality_interested_party_processes;
CREATE POLICY "party_processes_select_company"
  ON public.quality_interested_party_processes FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));

DROP POLICY IF EXISTS "party_processes_write_quality" ON public.quality_interested_party_processes;
CREATE POLICY "party_processes_write_quality"
  ON public.quality_interested_party_processes FOR ALL TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role) OR public.has_role(auth.uid(),'super_admin'::app_role))
  )
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role) OR public.has_role(auth.uid(),'super_admin'::app_role))
  );

CREATE INDEX IF NOT EXISTS idx_party_processes_process ON public.quality_interested_party_processes(process_id);
CREATE INDEX IF NOT EXISTS idx_party_processes_company ON public.quality_interested_party_processes(company_id);

ALTER TABLE public.quality_documents
  ADD COLUMN IF NOT EXISTS process_id uuid NULL REFERENCES public.quality_processes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_quality_documents_process ON public.quality_documents(process_id);
