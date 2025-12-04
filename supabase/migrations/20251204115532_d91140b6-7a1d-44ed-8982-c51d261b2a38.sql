-- Drop problematic policies that cause recursion
DROP POLICY IF EXISTS "Technicians can view supervisors from their service orders" ON profiles;
DROP POLICY IF EXISTS "Managers can view roles in their company" ON user_roles;

-- Create security definer function to check if a technician can view a supervisor
CREATE OR REPLACE FUNCTION public.can_tech_view_supervisor(_user_id uuid, _supervisor_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM service_orders so
    JOIN tasks t ON t.service_order_id = so.id
    JOIN technicians tech ON t.assigned_to = tech.id
    WHERE so.supervisor_id = _supervisor_id
      AND tech.user_id = _user_id
  )
$$;

-- Create security definer function to check if manager can view a user's role
CREATE OR REPLACE FUNCTION public.can_manager_view_role(_manager_id uuid, _target_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM profiles p1
    JOIN profiles p2 ON p1.company_id = p2.company_id
    WHERE p1.id = _manager_id
      AND p2.id = _target_user_id
      AND p1.company_id IS NOT NULL
  )
$$;

-- Recreate policies using the security definer functions
CREATE POLICY "Technicians can view supervisors from their service orders"
ON profiles FOR SELECT
USING (can_tech_view_supervisor(auth.uid(), id));

CREATE POLICY "Managers can view roles in their company"
ON user_roles FOR SELECT
USING (
  has_role(auth.uid(), 'manager'::app_role) 
  AND can_manager_view_role(auth.uid(), user_id)
);