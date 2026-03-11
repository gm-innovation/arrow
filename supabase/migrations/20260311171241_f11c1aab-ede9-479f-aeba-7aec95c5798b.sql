
-- Allow coordinators and directors to create service orders in their company
CREATE POLICY "Coordinators and directors can create service orders"
ON public.service_orders
FOR INSERT
TO authenticated
WITH CHECK (
  company_id = user_company_id(auth.uid())
  AND created_by = auth.uid()
  AND (
    has_role(auth.uid(), 'coordinator'::app_role)
    OR has_role(auth.uid(), 'director'::app_role)
  )
);

-- Allow coordinators to update their own service orders
CREATE POLICY "Coordinators can update their own service orders"
ON public.service_orders
FOR UPDATE
TO authenticated
USING (
  company_id = user_company_id(auth.uid())
  AND created_by = auth.uid()
  AND has_role(auth.uid(), 'coordinator'::app_role)
)
WITH CHECK (
  company_id = user_company_id(auth.uid())
  AND created_by = auth.uid()
  AND has_role(auth.uid(), 'coordinator'::app_role)
);
