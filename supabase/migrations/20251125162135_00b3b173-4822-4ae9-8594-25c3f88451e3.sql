-- Fix infinite recursion in visit_technicians RLS policies
-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage visit technicians" ON visit_technicians;
DROP POLICY IF EXISTS "Admins can view company assignments" ON visit_technicians;
DROP POLICY IF EXISTS "Super admins can view all assignments" ON visit_technicians;
DROP POLICY IF EXISTS "Technicians can view their assignments" ON visit_technicians;

-- Create new simplified policies without recursion
CREATE POLICY "Admins can manage visit technicians"
ON visit_technicians
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM service_visits sv
    JOIN service_orders so ON sv.service_order_id = so.id
    JOIN profiles p ON p.id = auth.uid()
    WHERE sv.id = visit_technicians.visit_id
      AND so.company_id = p.company_id
      AND has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "Super admins can view all assignments"
ON visit_technicians
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "Technicians can view their assignments"
ON visit_technicians
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM technicians t
    WHERE t.id = visit_technicians.technician_id
      AND t.user_id = auth.uid()
  )
);

CREATE POLICY "Users can view visit technicians in their company"
ON visit_technicians
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM service_visits sv
    JOIN service_orders so ON sv.service_order_id = so.id
    JOIN profiles p ON p.id = auth.uid()
    WHERE sv.id = visit_technicians.visit_id
      AND so.company_id = p.company_id
  )
);