-- Fix 1: WhatsApp conversations RLS - Remove overly permissive policy
DROP POLICY IF EXISTS "Service role can manage all WhatsApp conversations" ON public.whatsapp_conversations;

-- Fix 2: Technicians table - Replace overly permissive policy with restricted access
-- Drop the overly permissive policy that exposes PII to all company users
DROP POLICY IF EXISTS "Users can view technicians in their company" ON public.technicians;

-- Create a new policy that only shows basic info (non-PII) to non-admin users
-- Users can only see full technician records if:
-- 1. They are the technician themselves (own data)
-- 2. They are an admin in the same company
-- 3. They are assigned to the same visit (team members)
CREATE POLICY "Users can view limited technician info"
ON public.technicians
FOR SELECT
USING (
  -- User can see their own full data
  user_id = auth.uid()
  OR
  -- Admins can see all data in their company
  (has_role(auth.uid(), 'admin'::app_role) AND company_id = user_company_id(auth.uid()))
  OR
  -- Super admins can see all
  has_role(auth.uid(), 'super_admin'::app_role)
);

-- Create a secure view for non-sensitive technician data that other users can access
CREATE OR REPLACE VIEW public.technicians_public AS
SELECT 
  t.id,
  t.user_id,
  t.company_id,
  t.active,
  t.created_at,
  t.specialty,
  t.certifications,
  p.full_name,
  p.avatar_url
FROM public.technicians t
JOIN public.profiles p ON p.id = t.user_id
WHERE t.company_id = user_company_id(auth.uid());

-- Grant access to the view
GRANT SELECT ON public.technicians_public TO authenticated;