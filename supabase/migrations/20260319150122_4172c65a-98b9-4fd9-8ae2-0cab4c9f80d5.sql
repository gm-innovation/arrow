
-- Drop the restrictive coordinator policy
DROP POLICY "Coordinators can manage their measurements" ON public.measurements;

-- Create a proper policy: coordinators can manage measurements for any OS in their company
CREATE POLICY "Coordinators can manage company measurements"
ON public.measurements
FOR ALL
USING (
  has_role(auth.uid(), 'admin'::app_role)
  AND EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role)
  AND EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

-- Also allow directors to manage measurements
CREATE POLICY "Directors can manage company measurements"
ON public.measurements
FOR ALL
USING (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
