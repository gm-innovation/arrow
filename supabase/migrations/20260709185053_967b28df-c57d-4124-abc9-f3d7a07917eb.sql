
CREATE OR REPLACE FUNCTION public.notify_new_site_lead()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec RECORD;
  lead_label TEXT;
BEGIN
  lead_label := COALESCE(NEW.company_name, NEW.name, 'Sem identificação');

  FOR rec IN
    SELECT DISTINCT p.id AS user_id
    FROM public.profiles p
    JOIN public.user_roles ur ON ur.user_id = p.id
    WHERE p.company_id = NEW.company_id
      AND ur.role IN ('commercial','marketing','coordinator','director','admin')
  LOOP
    INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id)
    VALUES (
      rec.user_id,
      'lead_received',
      'Novo lead recebido',
      lead_label || COALESCE(' — ' || NEW.source, ''),
      NEW.id
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_new_site_lead ON public.public_site_leads;
CREATE TRIGGER trg_notify_new_site_lead
AFTER INSERT ON public.public_site_leads
FOR EACH ROW EXECUTE FUNCTION public.notify_new_site_lead();
