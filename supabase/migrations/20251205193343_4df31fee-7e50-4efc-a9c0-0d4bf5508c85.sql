-- Policy for HR to manage technician documents in their company
CREATE POLICY "HR can manage company technician documents" 
ON public.technician_documents
FOR ALL
TO authenticated
USING (
  has_role(auth.uid(), 'hr'::app_role) 
  AND EXISTS (
    SELECT 1 FROM technicians t
    WHERE t.id = technician_documents.technician_id
    AND t.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'hr'::app_role) 
  AND EXISTS (
    SELECT 1 FROM technicians t
    WHERE t.id = technician_documents.technician_id
    AND t.company_id = user_company_id(auth.uid())
  )
);