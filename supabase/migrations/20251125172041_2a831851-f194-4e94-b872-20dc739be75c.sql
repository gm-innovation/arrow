-- 1. Remove a política recursiva problemática
DROP POLICY IF EXISTS "Admins can view company visits" ON service_visits;

-- 2. Cria nova política sem recursão
CREATE POLICY "Admins can view company visits" ON service_visits
FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) 
  AND EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = service_visits.service_order_id
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- 3. Popula visit_technicians com dados existentes de tasks
INSERT INTO visit_technicians (visit_id, technician_id, is_lead, assigned_by)
SELECT DISTINCT 
  sv.id as visit_id,
  t.assigned_to as technician_id,
  (ROW_NUMBER() OVER (PARTITION BY sv.id ORDER BY t.created_at) = 1) as is_lead,
  so.created_by as assigned_by
FROM service_visits sv
JOIN service_orders so ON so.id = sv.service_order_id
JOIN tasks t ON t.service_order_id = so.id
WHERE t.assigned_to IS NOT NULL
  AND sv.visit_type = 'initial'
  AND NOT EXISTS (
    SELECT 1 FROM visit_technicians vt 
    WHERE vt.visit_id = sv.id AND vt.technician_id = t.assigned_to
  );