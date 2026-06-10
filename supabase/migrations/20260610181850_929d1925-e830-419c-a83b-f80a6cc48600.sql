
-- Helper SECURITY DEFINER functions to break RLS recursion cycle
CREATE OR REPLACE FUNCTION public.quality_doc_company_id(_doc_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT company_id FROM public.quality_documents WHERE id = _doc_id
$$;

CREATE OR REPLACE FUNCTION public.quality_version_doc_id(_version_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT document_id FROM public.quality_document_versions WHERE id = _version_id
$$;

CREATE OR REPLACE FUNCTION public.quality_doc_user_can_view(_doc_id uuid, _user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.quality_documents d
    WHERE d.id = _doc_id
      AND d.status = 'published'::quality_document_status
      AND (
        d.widely_visible = true
        OR EXISTS (
          SELECT 1 FROM public.quality_document_permissions p
          WHERE p.document_id = _doc_id
            AND p.user_id = _user
            AND p.can_view = true
        )
      )
  )
$$;

-- quality_documents: rewrite permissioned read
DROP POLICY IF EXISTS qd_docs_permissioned_read ON public.quality_documents;
CREATE POLICY qd_docs_permissioned_read ON public.quality_documents
  FOR SELECT
  USING (public.quality_doc_user_can_view(id, auth.uid()));

-- quality_document_permissions: rewrite master_full
DROP POLICY IF EXISTS qd_perms_master_full ON public.quality_document_permissions;
CREATE POLICY qd_perms_master_full ON public.quality_document_permissions
  FOR ALL
  USING (
    public.quality_doc_company_id(document_id) IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
    AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
  )
  WITH CHECK (
    public.quality_doc_company_id(document_id) IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
    AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
  );

-- quality_document_versions: rewrite
DROP POLICY IF EXISTS qd_versions_master_full ON public.quality_document_versions;
CREATE POLICY qd_versions_master_full ON public.quality_document_versions
  FOR ALL
  USING (
    public.quality_doc_company_id(document_id) IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
    AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
  )
  WITH CHECK (
    public.quality_doc_company_id(document_id) IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
    AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
  );

DROP POLICY IF EXISTS qd_versions_director_read ON public.quality_document_versions;
CREATE POLICY qd_versions_director_read ON public.quality_document_versions
  FOR SELECT
  USING (
    public.quality_doc_company_id(document_id) IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
    AND has_role(auth.uid(), 'director'::app_role)
  );

DROP POLICY IF EXISTS qd_versions_visible_read ON public.quality_document_versions;
CREATE POLICY qd_versions_visible_read ON public.quality_document_versions
  FOR SELECT
  USING (
    status = 'published'::quality_document_status
    AND public.quality_doc_user_can_view(document_id, auth.uid())
  );

-- quality_document_approvals: rewrite using version helper
DROP POLICY IF EXISTS qd_approvals_master_full ON public.quality_document_approvals;
CREATE POLICY qd_approvals_master_full ON public.quality_document_approvals
  FOR ALL
  USING (
    public.quality_doc_company_id(public.quality_version_doc_id(version_id)) IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
    AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
  )
  WITH CHECK (
    approver_user_id = auth.uid()
    AND public.quality_doc_company_id(public.quality_version_doc_id(version_id)) IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
  );

DROP POLICY IF EXISTS qd_approvals_director_read ON public.quality_document_approvals;
CREATE POLICY qd_approvals_director_read ON public.quality_document_approvals
  FOR SELECT
  USING (
    public.quality_doc_company_id(public.quality_version_doc_id(version_id)) IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
    AND has_role(auth.uid(), 'director'::app_role)
  );
