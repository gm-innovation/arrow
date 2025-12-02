-- Add policy to allow managers to view roles of users in their company
CREATE POLICY "Managers can view roles in their company"
ON public.user_roles
FOR SELECT
USING (
  has_role(auth.uid(), 'manager'::app_role) 
  AND EXISTS (
    SELECT 1 FROM profiles p1, profiles p2
    WHERE p1.id = auth.uid()
    AND p2.id = user_roles.user_id
    AND p1.company_id = p2.company_id
    AND p1.company_id IS NOT NULL
  )
);