-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "Technicians can view team member profiles from their visits" ON profiles;

-- Create a security definer function to check if a user can view a profile
-- This bypasses RLS and prevents infinite recursion
CREATE OR REPLACE FUNCTION public.can_view_profile(_viewer_id uuid, _profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM visit_technicians vt1
    JOIN visit_technicians vt2 ON vt2.visit_id = vt1.visit_id
    JOIN technicians t1 ON t1.id = vt1.technician_id
    JOIN technicians t2 ON t2.id = vt2.technician_id
    WHERE t1.user_id = _viewer_id
    AND t2.user_id = _profile_id
  )
$$;

-- Create a new policy using the security definer function
CREATE POLICY "Technicians can view team member profiles via function"
ON profiles
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR public.can_view_profile(auth.uid(), id)
);