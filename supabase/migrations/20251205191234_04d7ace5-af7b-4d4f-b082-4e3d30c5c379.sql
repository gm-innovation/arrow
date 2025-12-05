-- Policy for HR to manage (update) technicians in their company
CREATE POLICY "HR can update company technicians" 
ON public.technicians
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'hr'::app_role) 
  AND company_id = user_company_id(auth.uid())
)
WITH CHECK (
  has_role(auth.uid(), 'hr'::app_role) 
  AND company_id = user_company_id(auth.uid())
);