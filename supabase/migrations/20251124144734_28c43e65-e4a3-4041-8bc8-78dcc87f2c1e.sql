-- Fix infinite recursion in RLS policies for service_visits and related tables

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Technicians can view visits they are assigned to" ON service_visits;
DROP POLICY IF EXISTS "Technicians can view their assigned visits" ON visit_technicians;
DROP POLICY IF EXISTS "Admins can view all visits" ON service_visits;
DROP POLICY IF EXISTS "Super admins can view all visits" ON service_visits;

-- Create security definer function to check if user is assigned to a visit
CREATE OR REPLACE FUNCTION public.is_assigned_to_visit(_user_id uuid, _visit_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM visit_technicians vt
    JOIN technicians t ON t.id = vt.technician_id
    WHERE vt.visit_id = _visit_id
      AND t.user_id = _user_id
  )
$$;

-- Create security definer function to check if user's company owns the visit
CREATE OR REPLACE FUNCTION public.visit_belongs_to_user_company(_user_id uuid, _visit_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM service_visits sv
    JOIN service_orders so ON so.id = sv.service_order_id
    JOIN profiles p ON p.id = _user_id
    WHERE sv.id = _visit_id
      AND so.company_id = p.company_id
  )
$$;

-- Recreate policies using security definer functions
CREATE POLICY "Technicians can view visits they are assigned to"
ON service_visits
FOR SELECT
USING (
  public.has_role(auth.uid(), 'technician') 
  AND public.is_assigned_to_visit(auth.uid(), id)
);

CREATE POLICY "Admins can view company visits"
ON service_visits
FOR SELECT
USING (
  public.has_role(auth.uid(), 'admin')
  AND public.visit_belongs_to_user_company(auth.uid(), id)
);

CREATE POLICY "Super admins can view all visits"
ON service_visits
FOR SELECT
USING (public.has_role(auth.uid(), 'super_admin'));

-- Fix visit_technicians policies
DROP POLICY IF EXISTS "Technicians can view their assignments" ON visit_technicians;
DROP POLICY IF EXISTS "Admins can view all assignments" ON visit_technicians;

CREATE POLICY "Technicians can view their assignments"
ON visit_technicians
FOR SELECT
USING (
  public.has_role(auth.uid(), 'technician')
  AND EXISTS (
    SELECT 1 FROM technicians t
    WHERE t.id = technician_id AND t.user_id = auth.uid()
  )
);

CREATE POLICY "Admins can view company assignments"
ON visit_technicians
FOR SELECT
USING (
  public.has_role(auth.uid(), 'admin')
  AND public.visit_belongs_to_user_company(auth.uid(), visit_id)
);

CREATE POLICY "Super admins can view all assignments"
ON visit_technicians
FOR SELECT
USING (public.has_role(auth.uid(), 'super_admin'));