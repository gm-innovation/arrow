
-- 1. Add direct_manager_id to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS direct_manager_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_direct_manager_id ON public.profiles(direct_manager_id);

-- 2. Anti-cycle trigger
CREATE OR REPLACE FUNCTION public.check_manager_no_cycle()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_id uuid;
  depth int := 0;
BEGIN
  IF NEW.direct_manager_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.direct_manager_id = NEW.id THEN
    RAISE EXCEPTION 'Um colaborador não pode ser gestor de si mesmo';
  END IF;

  current_id := NEW.direct_manager_id;
  WHILE current_id IS NOT NULL AND depth < 20 LOOP
    IF current_id = NEW.id THEN
      RAISE EXCEPTION 'Ciclo de hierarquia detectado (gestor direto cria um loop)';
    END IF;
    SELECT direct_manager_id INTO current_id
    FROM public.profiles
    WHERE id = current_id;
    depth := depth + 1;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_manager_no_cycle ON public.profiles;
CREATE TRIGGER trg_profiles_manager_no_cycle
  BEFORE INSERT OR UPDATE OF direct_manager_id ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.check_manager_no_cycle();

-- 3. RPC: resolve approver for an employee
CREATE OR REPLACE FUNCTION public.get_employee_approver(_employee_id uuid)
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  approver_id uuid;
  dept_id uuid;
BEGIN
  -- 1st choice: direct_manager_id on profile
  SELECT direct_manager_id INTO approver_id
  FROM public.profiles
  WHERE id = _employee_id;

  IF approver_id IS NOT NULL THEN
    RETURN approver_id;
  END IF;

  -- 2nd choice: manager of the employee's department
  SELECT dm.department_id INTO dept_id
  FROM public.department_members dm
  WHERE dm.user_id = _employee_id
  LIMIT 1;

  IF dept_id IS NOT NULL THEN
    SELECT manager_id INTO approver_id
    FROM public.departments
    WHERE id = dept_id;

    IF approver_id IS NOT NULL AND approver_id <> _employee_id THEN
      RETURN approver_id;
    END IF;
  END IF;

  -- 3rd choice: NULL → caller falls back to HR
  RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_employee_approver(uuid) TO authenticated;

-- 4. RLS: allow HR, director, super_admin to update direct_manager_id (read already allowed by existing profile policies)
-- Add a permissive UPDATE policy scoped to HR/Director/SuperAdmin if not already present.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='profiles' AND policyname='HR Director SuperAdmin can manage hierarchy'
  ) THEN
    CREATE POLICY "HR Director SuperAdmin can manage hierarchy"
      ON public.profiles
      FOR UPDATE
      TO authenticated
      USING (
        public.has_role(auth.uid(), 'hr'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
        OR public.has_role(auth.uid(), 'super_admin'::app_role)
      )
      WITH CHECK (
        public.has_role(auth.uid(), 'hr'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
        OR public.has_role(auth.uid(), 'super_admin'::app_role)
      );
  END IF;
END$$;
