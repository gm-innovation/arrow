CREATE POLICY "Coordinators and directors can view company service orders"
ON public.service_orders
FOR SELECT
TO authenticated
USING (
  company_id = user_company_id(auth.uid())
  AND (
    has_role(auth.uid(), 'coordinator'::app_role)
    OR has_role(auth.uid(), 'director'::app_role)
  )
);