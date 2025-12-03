-- Fix the SECURITY DEFINER view issue by recreating as SECURITY INVOKER
DROP VIEW IF EXISTS public.technicians_public;

CREATE VIEW public.technicians_public
WITH (security_invoker = true)
AS
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