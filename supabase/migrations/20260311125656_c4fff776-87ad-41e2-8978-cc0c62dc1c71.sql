CREATE POLICY "Coordinators can manage clients in their company"
  ON public.clients FOR ALL
  TO authenticated
  USING (
    has_role(auth.uid(), 'coordinator'::app_role)
    AND company_id = user_company_id(auth.uid())
  )
  WITH CHECK (
    has_role(auth.uid(), 'coordinator'::app_role)
    AND company_id = user_company_id(auth.uid())
  );