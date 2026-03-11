
-- Allow coordinators to view technicians in their company
CREATE POLICY "Coordinators can view company technicians"
ON public.technicians FOR SELECT TO authenticated
USING (
  public.has_role(auth.uid(), 'coordinator'::app_role)
  AND company_id = public.user_company_id(auth.uid())
);
