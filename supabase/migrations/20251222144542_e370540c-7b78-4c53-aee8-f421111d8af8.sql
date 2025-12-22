-- Adicionar política de DELETE para HR na tabela technicians
CREATE POLICY "HR can delete company technicians"
ON public.technicians
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'hr'::app_role) 
  AND company_id = user_company_id(auth.uid())
);