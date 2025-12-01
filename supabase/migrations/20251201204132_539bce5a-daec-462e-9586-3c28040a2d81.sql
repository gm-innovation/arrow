-- Add more permissive policy for technicians to view company data via service orders
CREATE POLICY "Technicians can view company via service order"
ON public.companies FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM service_orders so
    JOIN tasks t ON t.service_order_id = so.id
    JOIN technicians tech ON tech.id = t.assigned_to
    WHERE so.company_id = companies.id
      AND tech.user_id = auth.uid()
  )
);