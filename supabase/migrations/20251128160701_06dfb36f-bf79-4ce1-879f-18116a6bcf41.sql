-- Allow technicians to view profiles of other technicians from the same visit/team
CREATE POLICY "Technicians can view team member profiles from their visits"
ON profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM visit_technicians vt1
    JOIN visit_technicians vt2 ON vt2.visit_id = vt1.visit_id
    JOIN technicians t1 ON t1.id = vt1.technician_id
    JOIN technicians t2 ON t2.id = vt2.technician_id
    WHERE t1.user_id = auth.uid()
    AND t2.user_id = profiles.id
  )
);