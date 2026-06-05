
-- ENUMs
CREATE TYPE public.quality_document_status AS ENUM ('draft','pending_approval','published','obsolete','archived');
CREATE TYPE public.quality_document_content_kind AS ENUM ('rich_text','file');
CREATE TYPE public.quality_signature_action AS ENUM ('approval','acknowledgment','review','closure','issuance','other');
CREATE TYPE public.quality_access_action AS ENUM ('view','print','download');
CREATE TYPE public.quality_controlled_copy_status AS ENUM ('issued','returned','destroyed','lost','superseded');

-- 1. Tipos
CREATE TABLE public.quality_document_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  code_prefix TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  default_classification TEXT,
  default_review_interval_months INTEGER,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (company_id, code_prefix)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_document_types TO authenticated;
GRANT ALL ON public.quality_document_types TO service_role;
ALTER TABLE public.quality_document_types ENABLE ROW LEVEL SECURITY;

-- 2. Documentos
CREATE TABLE public.quality_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  document_type_id UUID REFERENCES public.quality_document_types(id) ON DELETE SET NULL,
  code TEXT NOT NULL,
  title TEXT NOT NULL,
  classification TEXT,
  normative_reference TEXT,
  status public.quality_document_status NOT NULL DEFAULT 'draft',
  current_version_id UUID,
  published_at TIMESTAMPTZ,
  next_review_date DATE,
  expires_at DATE,
  widely_visible BOOLEAN NOT NULL DEFAULT false,
  obsolete_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (company_id, code)
);
CREATE INDEX idx_quality_documents_company ON public.quality_documents(company_id);
CREATE INDEX idx_quality_documents_status ON public.quality_documents(status);
CREATE INDEX idx_quality_documents_next_review ON public.quality_documents(next_review_date);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_documents TO authenticated;
GRANT ALL ON public.quality_documents TO service_role;
ALTER TABLE public.quality_documents ENABLE ROW LEVEL SECURITY;

-- 3. Versões
CREATE TABLE public.quality_document_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  revision_label TEXT NOT NULL,
  revision_number INTEGER NOT NULL,
  content_kind public.quality_document_content_kind NOT NULL DEFAULT 'rich_text',
  rich_content JSONB,
  file_path TEXT,
  file_name TEXT,
  file_mime TEXT,
  file_size BIGINT,
  change_summary TEXT,
  prepared_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  issued_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  status public.quality_document_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (document_id, revision_number)
);
CREATE INDEX idx_qd_versions_doc ON public.quality_document_versions(document_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_document_versions TO authenticated;
GRANT ALL ON public.quality_document_versions TO service_role;
ALTER TABLE public.quality_document_versions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.quality_documents
  ADD CONSTRAINT quality_documents_current_version_fk
  FOREIGN KEY (current_version_id) REFERENCES public.quality_document_versions(id) ON DELETE SET NULL;

-- 4. Permissões
CREATE TABLE public.quality_document_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  can_view BOOLEAN NOT NULL DEFAULT true,
  can_print BOOLEAN NOT NULL DEFAULT false,
  can_download BOOLEAN NOT NULL DEFAULT false,
  receives_controlled_copy BOOLEAN NOT NULL DEFAULT false,
  granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (document_id, user_id)
);
CREATE INDEX idx_qd_perms_user ON public.quality_document_permissions(user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_document_permissions TO authenticated;
GRANT ALL ON public.quality_document_permissions TO service_role;
ALTER TABLE public.quality_document_permissions ENABLE ROW LEVEL SECURITY;

-- 5. Aprovações
CREATE TABLE public.quality_document_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_id UUID NOT NULL REFERENCES public.quality_document_versions(id) ON DELETE CASCADE,
  approver_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  approver_role TEXT,
  decision TEXT NOT NULL CHECK (decision IN ('approved','rejected')),
  comments TEXT,
  signature_event_id UUID,
  decided_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_qd_approvals_version ON public.quality_document_approvals(version_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_document_approvals TO authenticated;
GRANT ALL ON public.quality_document_approvals TO service_role;
ALTER TABLE public.quality_document_approvals ENABLE ROW LEVEL SECURITY;

-- 6. Log de Acesso
CREATE TABLE public.quality_document_access_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  version_id UUID REFERENCES public.quality_document_versions(id) ON DELETE SET NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action public.quality_access_action NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_qd_access_doc ON public.quality_document_access_log(document_id, created_at DESC);
GRANT SELECT, INSERT ON public.quality_document_access_log TO authenticated;
GRANT ALL ON public.quality_document_access_log TO service_role;
ALTER TABLE public.quality_document_access_log ENABLE ROW LEVEL SECURITY;

-- 7. Assinatura
CREATE TABLE public.quality_signatures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  signature_image_path TEXT NOT NULL,
  full_name_snapshot TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_signatures TO authenticated;
GRANT ALL ON public.quality_signatures TO service_role;
ALTER TABLE public.quality_signatures ENABLE ROW LEVEL SECURITY;

-- 8. Eventos de assinatura
CREATE TABLE public.quality_signature_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  version_id UUID REFERENCES public.quality_document_versions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action public.quality_signature_action NOT NULL,
  signature_image_path TEXT NOT NULL,
  full_name_snapshot TEXT,
  role_snapshot TEXT,
  signed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ip_address TEXT,
  user_agent TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_qd_sigev_doc ON public.quality_signature_events(document_id);
CREATE INDEX idx_qd_sigev_version ON public.quality_signature_events(version_id);
GRANT SELECT, INSERT ON public.quality_signature_events TO authenticated;
GRANT ALL ON public.quality_signature_events TO service_role;
ALTER TABLE public.quality_signature_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.quality_document_approvals
  ADD CONSTRAINT qd_approvals_sigev_fk
  FOREIGN KEY (signature_event_id) REFERENCES public.quality_signature_events(id) ON DELETE SET NULL;

-- 9. Cópias controladas
CREATE TABLE public.quality_controlled_copies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  version_id UUID NOT NULL REFERENCES public.quality_document_versions(id) ON DELETE CASCADE,
  copy_number INTEGER NOT NULL,
  recipient_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  recipient_name TEXT,
  recipient_location TEXT,
  issued_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  returned_at TIMESTAMPTZ,
  destroyed_at TIMESTAMPTZ,
  status public.quality_controlled_copy_status NOT NULL DEFAULT 'issued',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (document_id, copy_number)
);
CREATE INDEX idx_qd_copies_doc ON public.quality_controlled_copies(document_id);
CREATE INDEX idx_qd_copies_status ON public.quality_controlled_copies(status);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_controlled_copies TO authenticated;
GRANT ALL ON public.quality_controlled_copies TO service_role;
ALTER TABLE public.quality_controlled_copies ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS RLS
CREATE POLICY "qd_types_select" ON public.quality_document_types FOR SELECT TO authenticated
USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "qd_types_master_write" ON public.quality_document_types FOR ALL TO authenticated
USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')))
WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));

CREATE POLICY "qd_docs_master_full" ON public.quality_documents FOR ALL TO authenticated
USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')))
WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "qd_docs_director_read" ON public.quality_documents FOR SELECT TO authenticated
USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()) AND public.has_role(auth.uid(),'director'));
CREATE POLICY "qd_docs_widely_visible_read" ON public.quality_documents FOR SELECT TO authenticated
USING (status = 'published' AND widely_visible = true
  AND company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "qd_docs_permissioned_read" ON public.quality_documents FOR SELECT TO authenticated
USING (status = 'published'
  AND id IN (SELECT document_id FROM public.quality_document_permissions WHERE user_id = auth.uid() AND can_view = true));

CREATE POLICY "qd_versions_master_full" ON public.quality_document_versions FOR ALL TO authenticated
USING (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')))
WITH CHECK (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "qd_versions_director_read" ON public.quality_document_versions FOR SELECT TO authenticated
USING (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND public.has_role(auth.uid(),'director'));
CREATE POLICY "qd_versions_visible_read" ON public.quality_document_versions FOR SELECT TO authenticated
USING (status = 'published' AND document_id IN (
  SELECT id FROM public.quality_documents d
  WHERE d.status = 'published' AND (
    d.widely_visible = true
    OR d.id IN (SELECT document_id FROM public.quality_document_permissions WHERE user_id = auth.uid() AND can_view = true)
  )
));

CREATE POLICY "qd_perms_master_full" ON public.quality_document_permissions FOR ALL TO authenticated
USING (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')))
WITH CHECK (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "qd_perms_self_read" ON public.quality_document_permissions FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "qd_approvals_master_full" ON public.quality_document_approvals FOR ALL TO authenticated
USING (version_id IN (SELECT v.id FROM public.quality_document_versions v
  JOIN public.quality_documents d ON d.id = v.document_id
  WHERE d.company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')))
WITH CHECK (approver_user_id = auth.uid()
  AND version_id IN (SELECT v.id FROM public.quality_document_versions v
    JOIN public.quality_documents d ON d.id = v.document_id
    WHERE d.company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));
CREATE POLICY "qd_approvals_director_read" ON public.quality_document_approvals FOR SELECT TO authenticated
USING (version_id IN (SELECT v.id FROM public.quality_document_versions v
  JOIN public.quality_documents d ON d.id = v.document_id
  WHERE d.company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND public.has_role(auth.uid(),'director'));

CREATE POLICY "qd_access_self_insert" ON public.quality_document_access_log FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());
CREATE POLICY "qd_access_master_read" ON public.quality_document_access_log FOR SELECT TO authenticated
USING (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));

CREATE POLICY "qd_sig_self_all" ON public.quality_signatures FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "qd_sig_master_read" ON public.quality_signatures FOR SELECT TO authenticated
USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));

CREATE POLICY "qd_sigev_self_insert" ON public.quality_signature_events FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());
CREATE POLICY "qd_sigev_self_read" ON public.quality_signature_events FOR SELECT TO authenticated
USING (user_id = auth.uid());
CREATE POLICY "qd_sigev_master_read" ON public.quality_signature_events FOR SELECT TO authenticated
USING (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "qd_sigev_director_read" ON public.quality_signature_events FOR SELECT TO authenticated
USING (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND public.has_role(auth.uid(),'director'));

CREATE POLICY "qd_copies_master_full" ON public.quality_controlled_copies FOR ALL TO authenticated
USING (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')))
WITH CHECK (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "qd_copies_recipient_read" ON public.quality_controlled_copies FOR SELECT TO authenticated
USING (recipient_user_id = auth.uid());
CREATE POLICY "qd_copies_director_read" ON public.quality_controlled_copies FOR SELECT TO authenticated
USING (document_id IN (SELECT id FROM public.quality_documents WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))
  AND public.has_role(auth.uid(),'director'));

-- Triggers updated_at (função do projeto: public.update_updated_at)
CREATE TRIGGER trg_qd_types_updated BEFORE UPDATE ON public.quality_document_types FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_qd_docs_updated BEFORE UPDATE ON public.quality_documents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_qd_versions_updated BEFORE UPDATE ON public.quality_document_versions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_qd_perms_updated BEFORE UPDATE ON public.quality_document_permissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_qd_sig_updated BEFORE UPDATE ON public.quality_signatures FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_qd_copies_updated BEFORE UPDATE ON public.quality_controlled_copies FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Storage policies
CREATE POLICY "qd_storage_docs_master_all" ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'quality-documents' AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')))
WITH CHECK (bucket_id = 'quality-documents' AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "qd_storage_docs_director_read" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'quality-documents' AND public.has_role(auth.uid(),'director'));
CREATE POLICY "qd_storage_sig_owner_all" ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'quality-signatures' AND auth.uid()::text = (storage.foldername(name))[1])
WITH CHECK (bucket_id = 'quality-signatures' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "qd_storage_sig_master_read" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'quality-signatures' AND (public.has_role(auth.uid(),'qualidade') OR public.has_role(auth.uid(),'super_admin')));
