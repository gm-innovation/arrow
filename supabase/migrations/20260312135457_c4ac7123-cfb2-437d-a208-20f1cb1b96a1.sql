CREATE POLICY "Allow anon to read company logo for onboarding"
ON public.companies
FOR SELECT
TO anon
USING (
  id IN (
    SELECT company_id FROM public.employee_onboarding
  )
);