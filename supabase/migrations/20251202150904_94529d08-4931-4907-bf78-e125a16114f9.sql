-- Permitir que admins atualizem status de service_orders da sua empresa
DROP POLICY IF EXISTS "Admins can update service orders in their company" ON public.service_orders;

CREATE POLICY "Admins can update service orders in their company" 
ON public.service_orders 
FOR UPDATE 
USING (
  has_role(auth.uid(), 'admin'::app_role) 
  AND company_id = user_company_id(auth.uid())
)
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) 
  AND company_id = user_company_id(auth.uid())
);