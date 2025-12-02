-- Managers can view all company service orders
CREATE POLICY "Managers can view all company service orders"
ON public.service_orders FOR SELECT
USING (
  company_id = user_company_id(auth.uid()) 
  AND has_role(auth.uid(), 'manager'::app_role)
);

-- Managers can view all company tasks
CREATE POLICY "Managers can view all company tasks"
ON public.tasks FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = tasks.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  ) AND has_role(auth.uid(), 'manager'::app_role)
);

-- Managers can view all company technicians
CREATE POLICY "Managers can view all company technicians"
ON public.technicians FOR SELECT
USING (
  company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'manager'::app_role)
);

-- Managers can view all clients
CREATE POLICY "Managers can view all clients"
ON public.clients FOR SELECT
USING (
  company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'manager'::app_role)
);

-- Managers can view all task reports
CREATE POLICY "Managers can view all task reports"
ON public.task_reports FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM tasks t
    JOIN service_orders so ON t.service_order_id = so.id
    WHERE t.id::text = task_reports.task_id
      AND so.company_id = user_company_id(auth.uid())
  ) AND has_role(auth.uid(), 'manager'::app_role)
);

-- Managers can view all measurements
CREATE POLICY "Managers can view all measurements"
ON public.measurements FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  ) AND has_role(auth.uid(), 'manager'::app_role)
);

-- Managers can view all service visits
CREATE POLICY "Managers can view all company visits"
ON public.service_visits FOR SELECT
USING (
  has_role(auth.uid(), 'manager'::app_role) AND 
  EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = service_visits.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

-- Managers can view all profiles in their company
CREATE POLICY "Managers can view all company profiles"
ON public.profiles FOR SELECT
USING (
  company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'manager'::app_role)
);

-- Managers can view service history
CREATE POLICY "Managers can view all service history"
ON public.service_history FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = service_history.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  ) AND has_role(auth.uid(), 'manager'::app_role)
);

-- Managers can view vessels
CREATE POLICY "Managers can view all company vessels"
ON public.vessels FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM clients c
    WHERE c.id = vessels.client_id
      AND c.company_id = user_company_id(auth.uid())
  ) AND has_role(auth.uid(), 'manager'::app_role)
);