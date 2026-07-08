
-- Trigger: mirror 'marketing' role to 'commercial' so Marketing users
-- automatically inherit all Commercial RLS permissions and access.

CREATE OR REPLACE FUNCTION public.mirror_marketing_to_commercial()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.role = 'marketing'::app_role THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.user_id, 'commercial'::app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
  ELSIF TG_OP = 'DELETE' AND OLD.role = 'marketing'::app_role THEN
    DELETE FROM public.user_roles
    WHERE user_id = OLD.user_id AND role = 'commercial'::app_role;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_mirror_marketing_to_commercial_ins ON public.user_roles;
CREATE TRIGGER trg_mirror_marketing_to_commercial_ins
AFTER INSERT ON public.user_roles
FOR EACH ROW EXECUTE FUNCTION public.mirror_marketing_to_commercial();

DROP TRIGGER IF EXISTS trg_mirror_marketing_to_commercial_del ON public.user_roles;
CREATE TRIGGER trg_mirror_marketing_to_commercial_del
AFTER DELETE ON public.user_roles
FOR EACH ROW EXECUTE FUNCTION public.mirror_marketing_to_commercial();

-- Backfill: any existing marketing users get commercial too.
INSERT INTO public.user_roles (user_id, role)
SELECT user_id, 'commercial'::app_role
FROM public.user_roles
WHERE role = 'marketing'::app_role
ON CONFLICT (user_id, role) DO NOTHING;
