-- Drop the existing policy that's too restrictive
DROP POLICY IF EXISTS "Technicians can view team members from their service orders" ON visit_technicians;

-- Create a better policy that allows technicians to see all team members from visits they're assigned to
CREATE POLICY "Technicians can view all team members from their visits"
ON visit_technicians
FOR SELECT
TO authenticated
USING (
  visit_id IN (
    SELECT vt.visit_id
    FROM visit_technicians vt
    JOIN technicians t ON t.id = vt.technician_id
    WHERE t.user_id = auth.uid()
  )
);