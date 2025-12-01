-- Allow technicians to view their own company data
CREATE POLICY "Technicians can view their company"
ON public.companies FOR SELECT
USING (id = user_company_id(auth.uid()));