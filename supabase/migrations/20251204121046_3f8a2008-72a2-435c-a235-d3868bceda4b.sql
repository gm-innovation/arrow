-- Drop problematic policies causing recursion
DROP POLICY IF EXISTS "Technicians can view their assigned service orders" ON service_orders;
DROP POLICY IF EXISTS "Users can view tasks in their company" ON tasks;
DROP POLICY IF EXISTS "Admins can manage tasks in their company" ON tasks;
DROP POLICY IF EXISTS "Managers can view all company tasks" ON tasks;

-- Create security definer function to check if technician has tasks on a service order
CREATE OR REPLACE FUNCTION public.is_tech_assigned_to_order(_user_id uuid, _service_order_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM tasks t
    JOIN technicians tech ON t.assigned_to = tech.id
    WHERE t.service_order_id = _service_order_id
      AND tech.user_id = _user_id
  )
$$;

-- Create security definer function to check if task belongs to user's company
CREATE OR REPLACE FUNCTION public.task_in_user_company(_user_id uuid, _task_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM tasks t
    JOIN service_orders so ON t.service_order_id = so.id
    JOIN profiles p ON p.id = _user_id
    WHERE t.id = _task_id
      AND so.company_id = p.company_id
  )
$$;

-- Recreate service_orders policy using security definer function
CREATE POLICY "Technicians can view their assigned service orders"
ON service_orders FOR SELECT
USING (is_tech_assigned_to_order(auth.uid(), id));

-- Recreate tasks policies using security definer function
CREATE POLICY "Users can view tasks in their company"
ON tasks FOR SELECT
USING (task_in_user_company(auth.uid(), id));

CREATE POLICY "Admins can manage tasks in their company"
ON tasks FOR ALL
USING (
  task_in_user_company(auth.uid(), id) 
  AND has_role(auth.uid(), 'admin'::app_role)
);

CREATE POLICY "Managers can view all company tasks"
ON tasks FOR SELECT
USING (
  task_in_user_company(auth.uid(), id) 
  AND has_role(auth.uid(), 'manager'::app_role)
);