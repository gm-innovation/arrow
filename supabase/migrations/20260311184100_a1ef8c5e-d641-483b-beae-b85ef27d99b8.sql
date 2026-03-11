
-- 1. Coordinators can insert tasks for their company's service orders
CREATE POLICY "Coordinators can insert tasks"
ON public.tasks
FOR INSERT TO authenticated
WITH CHECK (
  (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role))
  AND service_order_in_user_company(auth.uid(), service_order_id)
);

-- 2. Coordinators can delete tasks for their company's service orders
CREATE POLICY "Coordinators can delete tasks"
ON public.tasks
FOR DELETE TO authenticated
USING (
  (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role))
  AND task_in_user_company(auth.uid(), id)
);

-- 3. Coordinators can view roles in their company (needed for supervisor dropdown)
CREATE POLICY "Coordinators can view roles in their company"
ON public.user_roles
FOR SELECT TO authenticated
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = user_roles.user_id
      AND p.company_id = user_company_id(auth.uid())
  )
);
