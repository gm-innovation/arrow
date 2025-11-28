
-- Fix infinite recursion in visit_technicians RLS policies
-- The "Technicians can view all team members from their visits" policy was querying
-- visit_technicians within its own policy, causing infinite recursion

-- Drop the problematic policy
DROP POLICY IF EXISTS "Technicians can view all team members from their visits" ON public.visit_technicians;

-- Recreate it using the security definer function instead
CREATE POLICY "Technicians can view all team members from their visits" 
ON public.visit_technicians 
FOR SELECT 
USING (public.is_assigned_to_visit(auth.uid(), visit_id));
