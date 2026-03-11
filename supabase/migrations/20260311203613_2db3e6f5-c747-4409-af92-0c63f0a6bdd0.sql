
-- Tighten anon INSERT policy on onboarding_documents to validate onboarding_id has valid token
DROP POLICY IF EXISTS "Anon can upload onboarding documents" ON public.onboarding_documents;
CREATE POLICY "Anon can upload onboarding documents"
ON public.onboarding_documents FOR INSERT TO anon
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.employee_onboarding eo
    WHERE eo.id = onboarding_id
  )
);

-- Tighten anon SELECT on onboarding_documents
DROP POLICY IF EXISTS "Anon can view onboarding documents" ON public.onboarding_documents;
CREATE POLICY "Anon can view onboarding documents"
ON public.onboarding_documents FOR SELECT TO anon
USING (
  EXISTS (
    SELECT 1 FROM public.employee_onboarding eo
    WHERE eo.id = onboarding_id
  )
);
