
-- Director can manage service_orders in their company
CREATE POLICY "Directors can manage company service_orders"
ON public.service_orders
FOR ALL
TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'director'
  )
)
WITH CHECK (
  company_id = public.user_company_id(auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'director'
  )
);

-- Director can manage service_visits in their company
CREATE POLICY "Directors can manage company service_visits"
ON public.service_visits
FOR ALL
TO authenticated
USING (
  public.visit_belongs_to_user_company(auth.uid(), id)
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'director'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'director'
  )
);

-- Director can manage visit_technicians in their company
CREATE POLICY "Directors can manage company visit_technicians"
ON public.visit_technicians
FOR ALL
TO authenticated
USING (
  public.visit_belongs_to_user_company(auth.uid(), visit_id)
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'director'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'director'
  )
);

-- Director can manage tasks in their company
CREATE POLICY "Directors can manage company tasks"
ON public.tasks
FOR ALL
TO authenticated
USING (
  public.task_in_user_company(auth.uid(), id)
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'director'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'director'
  )
);
