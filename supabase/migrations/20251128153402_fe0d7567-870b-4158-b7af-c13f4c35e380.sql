-- Allow technicians to view supervisor profiles from their assigned service orders
CREATE POLICY "Technicians can view supervisors from their service orders"
ON profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM service_orders so
    JOIN tasks t ON t.service_order_id = so.id
    JOIN technicians tech ON t.assigned_to = tech.id
    WHERE so.supervisor_id = profiles.id
    AND tech.user_id = auth.uid()
  )
);