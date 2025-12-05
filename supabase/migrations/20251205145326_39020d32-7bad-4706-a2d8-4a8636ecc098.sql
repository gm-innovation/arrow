-- Drop the existing ALL policy and create separate policies for each operation
DROP POLICY IF EXISTS "Admins can manage tasks in their company" ON public.tasks;

-- Create a helper function to check if service_order belongs to user's company
CREATE OR REPLACE FUNCTION public.service_order_in_user_company(p_user_id uuid, p_service_order_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = p_service_order_id
    AND so.company_id = user_company_id(p_user_id)
  );
$$;

-- SELECT policy for admins
CREATE POLICY "Admins can view tasks in their company"
ON public.tasks
FOR SELECT
USING (
  task_in_user_company(auth.uid(), id) AND has_role(auth.uid(), 'admin'::app_role)
);

-- INSERT policy for admins (check via service_order_id since task id doesn't exist yet)
CREATE POLICY "Admins can insert tasks in their company"
ON public.tasks
FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) AND 
  service_order_in_user_company(auth.uid(), service_order_id)
);

-- UPDATE policy for admins
CREATE POLICY "Admins can update tasks in their company"
ON public.tasks
FOR UPDATE
USING (
  task_in_user_company(auth.uid(), id) AND has_role(auth.uid(), 'admin'::app_role)
);

-- DELETE policy for admins
CREATE POLICY "Admins can delete tasks in their company"
ON public.tasks
FOR DELETE
USING (
  task_in_user_company(auth.uid(), id) AND has_role(auth.uid(), 'admin'::app_role)
);