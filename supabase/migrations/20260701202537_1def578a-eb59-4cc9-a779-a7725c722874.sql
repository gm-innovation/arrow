
ALTER TABLE public.quality_org_context
  ADD COLUMN IF NOT EXISTS mission text,
  ADD COLUMN IF NOT EXISTS vision text,
  ADD COLUMN IF NOT EXISTS "values" text;

CREATE TABLE IF NOT EXISTS public.quality_process_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  process_id uuid NOT NULL REFERENCES public.quality_processes(id) ON DELETE CASCADE,
  document_id uuid NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  relationship_type text NOT NULL CHECK (relationship_type IN ('input','output','reference','procedure')),
  notes text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (process_id, document_id, relationship_type)
);

CREATE INDEX IF NOT EXISTS idx_qpd_process ON public.quality_process_documents(process_id);
CREATE INDEX IF NOT EXISTS idx_qpd_document ON public.quality_process_documents(document_id);
CREATE INDEX IF NOT EXISTS idx_qpd_company ON public.quality_process_documents(company_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_process_documents TO authenticated;
GRANT ALL ON public.quality_process_documents TO service_role;

ALTER TABLE public.quality_process_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qpd_select" ON public.quality_process_documents
  FOR SELECT TO authenticated
  USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "qpd_write" ON public.quality_process_documents
  FOR ALL TO authenticated
  USING (
    company_id = user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role))
  )
  WITH CHECK (
    company_id = user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role))
  );

CREATE TRIGGER trg_qpd_updated
  BEFORE UPDATE ON public.quality_process_documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
