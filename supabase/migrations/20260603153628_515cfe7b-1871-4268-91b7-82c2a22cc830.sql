UPDATE public.profiles p
SET 
  birth_date = COALESCE(p.birth_date, t.birth_date),
  cpf = COALESCE(p.cpf, t.cpf),
  rg = COALESCE(p.rg, t.rg),
  gender = COALESCE(p.gender, t.gender),
  nationality = COALESCE(p.nationality, t.nationality),
  height = COALESCE(p.height, t.height)
FROM public.technicians t
WHERE t.user_id = p.id
  AND (
    (p.birth_date IS NULL AND t.birth_date IS NOT NULL) OR
    (p.cpf IS NULL AND t.cpf IS NOT NULL) OR
    (p.rg IS NULL AND t.rg IS NOT NULL) OR
    (p.gender IS NULL AND t.gender IS NOT NULL) OR
    (p.nationality IS NULL AND t.nationality IS NOT NULL) OR
    (p.height IS NULL AND t.height IS NOT NULL)
  );

CREATE OR REPLACE FUNCTION public.sync_technician_personal_to_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  UPDATE public.profiles p
  SET
    birth_date = COALESCE(p.birth_date, NEW.birth_date),
    cpf = COALESCE(p.cpf, NEW.cpf),
    rg = COALESCE(p.rg, NEW.rg),
    gender = COALESCE(p.gender, NEW.gender),
    nationality = COALESCE(p.nationality, NEW.nationality),
    height = COALESCE(p.height, NEW.height)
  WHERE p.id = NEW.user_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_technician_personal_to_profile ON public.technicians;
CREATE TRIGGER trg_sync_technician_personal_to_profile
AFTER INSERT OR UPDATE OF birth_date, cpf, rg, gender, nationality, height
ON public.technicians
FOR EACH ROW
EXECUTE FUNCTION public.sync_technician_personal_to_profile();