
-- 1) companies: drop unsafe anon SELECT policy and replace with RPC
DROP POLICY IF EXISTS "Allow anon to read company logo for onboarding" ON public.companies;

CREATE OR REPLACE FUNCTION public.get_company_public_logo(_company_id uuid)
RETURNS TABLE(id uuid, name text, logo_url text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT c.id, c.name, c.logo_url
  FROM public.companies c
  WHERE c.id = _company_id
    AND EXISTS (SELECT 1 FROM public.employee_onboarding eo WHERE eo.company_id = c.id);
$$;
GRANT EXECUTE ON FUNCTION public.get_company_public_logo(uuid) TO anon, authenticated;

-- 2) employee_onboarding: drop unsafe anon "USING true" policy; add token-scoped RPC
DROP POLICY IF EXISTS "Anon can view onboarding by token" ON public.employee_onboarding;

CREATE OR REPLACE FUNCTION public.get_onboarding_by_token(_token uuid)
RETURNS SETOF public.employee_onboarding
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT * FROM public.employee_onboarding WHERE access_token = _token LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_onboarding_by_token(uuid) TO anon, authenticated;

-- 3) onboarding_document_types: drop blanket policies; scope authenticated by company; provide RPC for anon by token
DROP POLICY IF EXISTS "Anon can view document types" ON public.onboarding_document_types;
DROP POLICY IF EXISTS "Authenticated can view onboarding doc types" ON public.onboarding_document_types;

CREATE POLICY "Authenticated view doc types of own company"
ON public.onboarding_document_types
FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));

CREATE OR REPLACE FUNCTION public.get_onboarding_doc_types_by_token(_token uuid)
RETURNS SETOF public.onboarding_document_types
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  _company uuid;
  _position text;
BEGIN
  SELECT company_id, position_tag INTO _company, _position
  FROM public.employee_onboarding WHERE access_token = _token LIMIT 1;
  IF _company IS NULL THEN RETURN; END IF;
  RETURN QUERY
  SELECT * FROM public.onboarding_document_types
  WHERE company_id = _company
    AND (position_tag IS NULL OR position_tag = _position)
  ORDER BY sort_order;
END; $$;
GRANT EXECUTE ON FUNCTION public.get_onboarding_doc_types_by_token(uuid) TO anon, authenticated;

-- 4) reports bucket: tighten policies (path-based ownership)
DROP POLICY IF EXISTS "Users can view their own reports" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own reports" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own reports" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own reports" ON storage.objects;

CREATE POLICY "Reports: authenticated upload to own folder"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'reports' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Reports: authenticated update own folder"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'reports' AND (storage.foldername(name))[1] = auth.uid()::text)
WITH CHECK (bucket_id = 'reports' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Reports: authenticated delete own folder"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'reports'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE POLICY "Reports: authenticated view own folder"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'reports' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 5) corp-documents bucket: company-scoped policies
DROP POLICY IF EXISTS "corp_storage_select" ON storage.objects;
DROP POLICY IF EXISTS "corp_storage_insert" ON storage.objects;
DROP POLICY IF EXISTS "corp_storage_delete" ON storage.objects;

CREATE POLICY "corp_storage_select" ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'corp-documents' AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id::text = (storage.foldername(name))[1]
        AND p.company_id = public.user_company_id(auth.uid())
    )
    OR (
      (storage.foldername(name))[1] = 'onboarding'
      AND (storage.foldername(name))[2] = public.user_company_id(auth.uid())::text
      AND (
        has_role(auth.uid(), 'hr'::app_role)
        OR has_role(auth.uid(), 'director'::app_role)
        OR has_role(auth.uid(), 'admin'::app_role)
        OR has_role(auth.uid(), 'super_admin'::app_role)
      )
    )
  )
);

CREATE POLICY "corp_storage_insert" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'corp-documents' AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR (
      (storage.foldername(name))[1] = 'onboarding'
      AND (storage.foldername(name))[2] = public.user_company_id(auth.uid())::text
    )
  )
);

CREATE POLICY "corp_storage_delete" ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'corp-documents' AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR (
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND p.company_id = public.user_company_id(auth.uid())
      )
      AND (
        has_role(auth.uid(), 'hr'::app_role)
        OR has_role(auth.uid(), 'director'::app_role)
        OR has_role(auth.uid(), 'admin'::app_role)
        OR has_role(auth.uid(), 'super_admin'::app_role)
      )
    )
  )
);

-- Allow anon to upload during public onboarding under onboarding/{company_id}/...
CREATE POLICY "corp_storage_onboarding_anon_insert" ON storage.objects FOR INSERT TO anon
WITH CHECK (
  bucket_id = 'corp-documents'
  AND (storage.foldername(name))[1] = 'onboarding'
  AND EXISTS (
    SELECT 1 FROM public.employee_onboarding eo
    WHERE eo.company_id::text = (storage.foldername(name))[2]
  )
);

-- 6) university_certificates: company-scope HR access
DROP POLICY IF EXISTS "Users can view own certificates" ON public.university_certificates;
DROP POLICY IF EXISTS "System can insert certificates" ON public.university_certificates;

CREATE POLICY "Users can view own certificates"
ON public.university_certificates FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR (
    public.is_hr_in_company(auth.uid())
    AND EXISTS (
      SELECT 1 FROM public.university_enrollments e
      JOIN public.university_courses c ON c.id = e.course_id
      WHERE e.id = university_certificates.enrollment_id
        AND c.company_id = public.user_company_id(auth.uid())
    )
  )
);

CREATE POLICY "System can insert certificates"
ON public.university_certificates FOR INSERT TO authenticated
WITH CHECK (
  user_id = auth.uid()
  OR (
    public.is_hr_in_company(auth.uid())
    AND EXISTS (
      SELECT 1 FROM public.university_enrollments e
      JOIN public.university_courses c ON c.id = e.course_id
      WHERE e.id = university_certificates.enrollment_id
        AND c.company_id = public.user_company_id(auth.uid())
    )
  )
);

-- 7) user_roles: scope admin role management to same company
DROP POLICY IF EXISTS "Admins can manage roles in their company" ON public.user_roles;

CREATE POLICY "Admins can manage roles in their company"
ON public.user_roles FOR ALL TO authenticated
USING (
  has_role(auth.uid(), 'admin'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = user_roles.user_id
      AND p.company_id = public.user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = user_roles.user_id
      AND p.company_id = public.user_company_id(auth.uid())
  )
);
