
-- Allow technicians to view all team members assigned to their service orders
CREATE POLICY "Technicians can view team members from their service orders"
ON visit_technicians
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM service_visits sv
    JOIN service_orders so ON sv.service_order_id = so.id
    JOIN tasks t ON t.service_order_id = so.id
    JOIN technicians tech ON t.assigned_to = tech.id
    WHERE sv.id = visit_technicians.visit_id
    AND tech.user_id = auth.uid()
  )
);
