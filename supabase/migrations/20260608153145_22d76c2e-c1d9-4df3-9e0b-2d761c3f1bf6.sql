
-- ============================================================
-- ONDA 1: Governance & structural compliance (ISO)
-- 1. Master flag + central approval (scoped)
-- 2. Processes / SIPOC (Opção B: linked to quality_documents)
-- 3. Management Review linked to OrgContext
-- 4. Company Documents (CNPJ, Alvará, IE, ...)
-- 5. Audits: recurrence + attachments
-- ============================================================

-- 0) Extend quality_settings with master + approval_scope
ALTER TABLE public.quality_settings
  ADD COLUMN IF NOT EXISTS quality_master_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS approval_scope jsonb NOT NULL DEFAULT jsonb_build_object(
    'document', true,
    'company_document', true,
    'process', true,
    'policy', true,
    'context_official', true,
    'ncr', false,
    'deviation', false
  );

CREATE UNIQUE INDEX IF NOT EXISTS quality_settings_master_user_unique
  ON public.quality_settings(company_id) WHERE quality_master_user_id IS NOT NULL;

-- 0b) Extend quality_org_context with last management review link
ALTER TABLE public.quality_org_context
  ADD COLUMN IF NOT EXISTS last_management_review_id uuid
    REFERENCES public.quality_management_reviews(id) ON DELETE SET NULL;

-- 0c) Mark official context snapshots
ALTER TABLE public.quality_context_versions
  ADD COLUMN IF NOT EXISTS is_official boolean NOT NULL DEFAULT false;

-- 0d) Audits recurrence + next_due_at
ALTER TABLE public.quality_audits
  ADD COLUMN IF NOT EXISTS recurrence text NOT NULL DEFAULT 'ad_hoc'
    CHECK (recurrence IN ('monthly','quarterly','semiannual','annual','ad_hoc')),
  ADD COLUMN IF NOT EXISTS next_due_at date;

-- ============================================================
-- Helper: is current user the company quality master?
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_quality_master(_company_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.quality_settings qs
    WHERE qs.company_id = _company_id
      AND qs.quality_master_user_id = auth.uid()
  );
$$;

-- ============================================================
-- 1) quality_central_approvals
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quality_central_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  entity_type text NOT NULL CHECK (entity_type IN ('document','company_document','process','policy','context_official','ncr','deviation')),
  entity_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  requested_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  requested_at timestamptz NOT NULL DEFAULT now(),
  approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, entity_type, entity_id, status)
);

CREATE INDEX IF NOT EXISTS idx_qca_company_status ON public.quality_central_approvals(company_id, status);
CREATE INDEX IF NOT EXISTS idx_qca_entity ON public.quality_central_approvals(entity_type, entity_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_central_approvals TO authenticated;
GRANT ALL ON public.quality_central_approvals TO service_role;
ALTER TABLE public.quality_central_approvals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qca_select" ON public.quality_central_approvals
  FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
      OR public.is_quality_master(company_id)));

CREATE POLICY "qca_insert" ON public.quality_central_approvals
  FOR INSERT TO authenticated
  WITH CHECK (company_id = public.user_company_id(auth.uid())
    AND requested_by = auth.uid()
    AND status = 'pending');

CREATE POLICY "qca_update_master" ON public.quality_central_approvals
  FOR UPDATE TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
    AND public.is_quality_master(company_id))
  WITH CHECK (company_id = public.user_company_id(auth.uid())
    AND public.is_quality_master(company_id)
    AND (approved_by IS NULL OR approved_by = auth.uid()));

CREATE TRIGGER trg_qca_updated BEFORE UPDATE ON public.quality_central_approvals
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================
-- 2) Processes + SIPOC + Activities (Opção B)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quality_processes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL DEFAULT 'operational' CHECK (type IN ('strategic','tactical','operational','support')),
  description text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','obsolete')),
  owner_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  current_document_id uuid REFERENCES public.quality_documents(id) ON DELETE SET NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qproc_company ON public.quality_processes(company_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_processes TO authenticated;
GRANT ALL ON public.quality_processes TO service_role;
ALTER TABLE public.quality_processes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qproc_select" ON public.quality_processes FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "qproc_write" ON public.quality_processes FOR ALL TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)))
  WITH CHECK (company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)));

CREATE TRIGGER trg_qproc_updated BEFORE UPDATE ON public.quality_processes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE IF NOT EXISTS public.quality_process_sipoc (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  process_id uuid NOT NULL REFERENCES public.quality_processes(id) ON DELETE CASCADE,
  suppliers text,
  inputs text,
  activities text,
  outputs text,
  customers text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (process_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_process_sipoc TO authenticated;
GRANT ALL ON public.quality_process_sipoc TO service_role;
ALTER TABLE public.quality_process_sipoc ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qsipoc_select" ON public.quality_process_sipoc FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.quality_processes p WHERE p.id = process_id
    AND p.company_id = public.user_company_id(auth.uid())));
CREATE POLICY "qsipoc_write" ON public.quality_process_sipoc FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.quality_processes p WHERE p.id = process_id
    AND p.company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role) OR has_role(auth.uid(),'director'::app_role) OR has_role(auth.uid(),'super_admin'::app_role))))
  WITH CHECK (EXISTS (SELECT 1 FROM public.quality_processes p WHERE p.id = process_id
    AND p.company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role) OR has_role(auth.uid(),'director'::app_role) OR has_role(auth.uid(),'super_admin'::app_role))));
CREATE TRIGGER trg_qsipoc_updated BEFORE UPDATE ON public.quality_process_sipoc
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE IF NOT EXISTS public.quality_process_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  process_id uuid NOT NULL REFERENCES public.quality_processes(id) ON DELETE CASCADE,
  order_index integer NOT NULL DEFAULT 0,
  activity text NOT NULL,
  responsible_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  indicators text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qpa_process ON public.quality_process_activities(process_id, order_index);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_process_activities TO authenticated;
GRANT ALL ON public.quality_process_activities TO service_role;
ALTER TABLE public.quality_process_activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qpa_select" ON public.quality_process_activities FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.quality_processes p WHERE p.id = process_id
    AND p.company_id = public.user_company_id(auth.uid())));
CREATE POLICY "qpa_write" ON public.quality_process_activities FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.quality_processes p WHERE p.id = process_id
    AND p.company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role) OR has_role(auth.uid(),'director'::app_role) OR has_role(auth.uid(),'super_admin'::app_role))))
  WITH CHECK (EXISTS (SELECT 1 FROM public.quality_processes p WHERE p.id = process_id
    AND p.company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role) OR has_role(auth.uid(),'director'::app_role) OR has_role(auth.uid(),'super_admin'::app_role))));
CREATE TRIGGER trg_qpa_updated BEFORE UPDATE ON public.quality_process_activities
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Optional process link on risks/ncrs
ALTER TABLE public.quality_risks ADD COLUMN IF NOT EXISTS process_id uuid
  REFERENCES public.quality_processes(id) ON DELETE SET NULL;
ALTER TABLE public.quality_ncrs ADD COLUMN IF NOT EXISTS process_id uuid
  REFERENCES public.quality_processes(id) ON DELETE SET NULL;

-- ============================================================
-- 4) Company Documents
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quality_company_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  document_type text NOT NULL,
  title text NOT NULL,
  file_url text,
  file_name text,
  issued_at date,
  expires_at date,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','expired','renewing','archived')),
  owner_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  notes text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qcd_company ON public.quality_company_documents(company_id);
CREATE INDEX IF NOT EXISTS idx_qcd_expires ON public.quality_company_documents(company_id, expires_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_company_documents TO authenticated;
GRANT ALL ON public.quality_company_documents TO service_role;
ALTER TABLE public.quality_company_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qcd_select" ON public.quality_company_documents FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "qcd_write" ON public.quality_company_documents FOR ALL TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role) OR has_role(auth.uid(),'director'::app_role) OR has_role(auth.uid(),'super_admin'::app_role)))
  WITH CHECK (company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role) OR has_role(auth.uid(),'director'::app_role) OR has_role(auth.uid(),'super_admin'::app_role)));
CREATE TRIGGER trg_qcd_updated BEFORE UPDATE ON public.quality_company_documents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================
-- 5) Audit attachments
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quality_audit_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_id uuid NOT NULL REFERENCES public.quality_audits(id) ON DELETE CASCADE,
  kind text NOT NULL DEFAULT 'evidence' CHECK (kind IN ('plan','evidence','report','photo','other')),
  file_name text NOT NULL,
  file_url text NOT NULL,
  notes text,
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qaa_audit ON public.quality_audit_attachments(audit_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_audit_attachments TO authenticated;
GRANT ALL ON public.quality_audit_attachments TO service_role;
ALTER TABLE public.quality_audit_attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qaa_select" ON public.quality_audit_attachments FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.quality_audits a WHERE a.id = audit_id
    AND a.company_id = public.user_company_id(auth.uid())));
CREATE POLICY "qaa_write" ON public.quality_audit_attachments FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.quality_audits a WHERE a.id = audit_id
    AND a.company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role) OR has_role(auth.uid(),'director'::app_role) OR has_role(auth.uid(),'super_admin'::app_role))))
  WITH CHECK (EXISTS (SELECT 1 FROM public.quality_audits a WHERE a.id = audit_id
    AND a.company_id = public.user_company_id(auth.uid())
    AND (has_role(auth.uid(),'qualidade'::app_role) OR has_role(auth.uid(),'director'::app_role) OR has_role(auth.uid(),'super_admin'::app_role))));
