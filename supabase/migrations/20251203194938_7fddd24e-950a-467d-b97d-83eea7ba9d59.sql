-- Fix 1: task_time_estimates - Restrict to service_role only
DROP POLICY IF EXISTS "System can manage time estimates" ON public.task_time_estimates;

CREATE POLICY "Service role can manage time estimates" 
ON public.task_time_estimates 
FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- Also add admin read access for their company
CREATE POLICY "Admins can view time estimates in their company" 
ON public.task_time_estimates 
FOR SELECT 
USING (
  has_role(auth.uid(), 'admin'::app_role) 
  AND company_id = user_company_id(auth.uid())
);

-- Fix 2: service_orders - Restrict technician view to assigned orders only
DROP POLICY IF EXISTS "Technicians can view their service orders" ON public.service_orders;

CREATE POLICY "Technicians can view their assigned service orders" 
ON public.service_orders 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM tasks t
    JOIN technicians tech ON t.assigned_to = tech.id
    WHERE t.service_order_id = service_orders.id
    AND tech.user_id = auth.uid()
  )
);