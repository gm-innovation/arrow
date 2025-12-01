-- Allow technicians to view visits from their assigned service orders
CREATE POLICY "Technicians can view visits from their assigned orders"
ON public.service_visits FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM tasks t
    JOIN technicians tech ON t.assigned_to = tech.id
    WHERE t.service_order_id = service_visits.service_order_id
      AND tech.user_id = auth.uid()
  )
);