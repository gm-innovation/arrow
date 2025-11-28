-- Permitir técnicos visualizarem clientes de suas service orders
CREATE POLICY "Technicians can view clients from their assigned tasks"
ON clients
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM tasks
    JOIN service_orders ON service_orders.id = tasks.service_order_id
    JOIN technicians ON technicians.id = tasks.assigned_to
    WHERE service_orders.client_id = clients.id
      AND technicians.user_id = auth.uid()
  )
);

-- Permitir técnicos visualizarem embarcações de suas service orders
CREATE POLICY "Technicians can view vessels from their assigned tasks"
ON vessels
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM tasks
    JOIN service_orders ON service_orders.id = tasks.service_order_id
    JOIN technicians ON technicians.id = tasks.assigned_to
    WHERE service_orders.vessel_id = vessels.id
      AND technicians.user_id = auth.uid()
  )
);