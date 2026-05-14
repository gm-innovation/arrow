-- Coordinators and directors access to crm_opportunities
DROP POLICY IF EXISTS "Coordinator and director can view opportunities" ON public.crm_opportunities;
DROP POLICY IF EXISTS "Coordinator can manage service opportunities" ON public.crm_opportunities;
DROP POLICY IF EXISTS "Director can manage opportunities" ON public.crm_opportunities;

CREATE POLICY "Coordinator and director can view opportunities"
ON public.crm_opportunities FOR SELECT
USING (
  company_id = user_company_id(auth.uid())
  AND (
    has_role(auth.uid(), 'coordinator'::app_role)
    OR has_role(auth.uid(), 'director'::app_role)
  )
);

CREATE POLICY "Coordinator can manage service opportunities"
ON public.crm_opportunities FOR ALL
USING (
  company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'coordinator'::app_role)
  AND (segment IN ('service','unknown') OR assigned_to = auth.uid())
)
WITH CHECK (
  company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'coordinator'::app_role)
  AND (segment IN ('service','unknown') OR assigned_to = auth.uid())
);

CREATE POLICY "Director can manage opportunities"
ON public.crm_opportunities FOR ALL
USING (
  company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'director'::app_role)
)
WITH CHECK (
  company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'director'::app_role)
);