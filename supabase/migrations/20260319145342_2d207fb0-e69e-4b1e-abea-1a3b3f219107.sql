-- Allow directors to view user_roles in their company
CREATE POLICY "Directors can view roles in their company"
ON public.user_roles
FOR SELECT
USING (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = user_roles.user_id
      AND p.company_id = user_company_id(auth.uid())
  )
);