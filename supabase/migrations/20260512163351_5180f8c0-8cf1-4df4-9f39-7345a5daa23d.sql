DROP POLICY IF EXISTS "Company staff can view their site leads" ON public.public_site_leads;
DROP POLICY IF EXISTS "Company staff can update their site leads" ON public.public_site_leads;

CREATE POLICY "Company staff can view their site leads"
ON public.public_site_leads
FOR SELECT
USING (
  has_role(auth.uid(), 'super_admin'::app_role) OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.company_id = public_site_leads.company_id
      AND (
        has_role(auth.uid(), 'commercial'::app_role)
        OR has_role(auth.uid(), 'marketing'::app_role)
        OR has_role(auth.uid(), 'coordinator'::app_role)
        OR has_role(auth.uid(), 'director'::app_role)
        OR has_role(auth.uid(), 'admin'::app_role)
      )
  )
);

CREATE POLICY "Company staff can update their site leads"
ON public.public_site_leads
FOR UPDATE
USING (
  has_role(auth.uid(), 'super_admin'::app_role) OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.company_id = public_site_leads.company_id
      AND (
        has_role(auth.uid(), 'commercial'::app_role)
        OR has_role(auth.uid(), 'marketing'::app_role)
        OR has_role(auth.uid(), 'coordinator'::app_role)
        OR has_role(auth.uid(), 'director'::app_role)
        OR has_role(auth.uid(), 'admin'::app_role)
      )
  )
);