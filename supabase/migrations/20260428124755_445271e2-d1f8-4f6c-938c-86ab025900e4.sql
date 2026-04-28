-- =========================================================================
-- 1. Drop all existing SELECT policies on public.profiles to start clean
-- =========================================================================
DROP POLICY IF EXISTS "Users can view profiles in their company"      ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile"                    ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles in their company" ON public.profiles;
DROP POLICY IF EXISTS "Managers can view all company profiles"        ON public.profiles;
DROP POLICY IF EXISTS "HR can view all company profiles"              ON public.profiles;
DROP POLICY IF EXISTS "Technicians can view team member profiles via function" ON public.profiles;
DROP POLICY IF EXISTS "Technicians can view supervisors from their service orders" ON public.profiles;

-- =========================================================================
-- 2. New restrictive SELECT policies on profiles
--    (UPDATE/INSERT/DELETE policies remain untouched — HR, Admin, Super Admin, self)
-- =========================================================================
CREATE POLICY "Self can view own profile"
ON public.profiles FOR SELECT TO authenticated
USING (id = auth.uid());

CREATE POLICY "Privileged roles can view company profiles"
ON public.profiles FOR SELECT TO authenticated
USING (
  has_role(auth.uid(), 'super_admin'::app_role)
  OR (
    company_id = user_company_id(auth.uid())
    AND (
      has_role(auth.uid(), 'hr'::app_role)
      OR has_role(auth.uid(), 'admin'::app_role)
      OR has_role(auth.uid(), 'director'::app_role)
    )
  )
);

-- =========================================================================
-- 3. profiles_public — internal directory view (id, name, avatar, company only)
--    No security_invoker: runs as view owner so its WHERE clause filters
--    company-wide visibility regardless of base-table RLS.
-- =========================================================================
DROP VIEW IF EXISTS public.profiles_public;
CREATE VIEW public.profiles_public
WITH (security_barrier = true) AS
SELECT
  p.id,
  p.full_name,
  p.avatar_url,
  p.company_id
FROM public.profiles p
WHERE p.company_id = public.user_company_id(auth.uid())
   OR public.has_role(auth.uid(), 'super_admin'::app_role);

REVOKE ALL ON public.profiles_public FROM PUBLIC, anon;
GRANT SELECT ON public.profiles_public TO authenticated;

-- =========================================================================
-- 4. employee_celebrations_public — birthdays & work anniversaries
--    Exposes only month/day for birthdays (no birth year).
-- =========================================================================
DROP VIEW IF EXISTS public.employee_celebrations_public;
CREATE VIEW public.employee_celebrations_public
WITH (security_barrier = true) AS
SELECT
  p.id,
  p.full_name,
  p.avatar_url,
  p.company_id,
  EXTRACT(MONTH FROM p.birth_date)::int AS birth_month,
  EXTRACT(DAY   FROM p.birth_date)::int AS birth_day,
  EXTRACT(MONTH FROM p.hire_date)::int  AS hire_month,
  EXTRACT(DAY   FROM p.hire_date)::int  AS hire_day,
  EXTRACT(YEAR  FROM p.hire_date)::int  AS hire_year
FROM public.profiles p
WHERE p.company_id = public.user_company_id(auth.uid())
   OR public.has_role(auth.uid(), 'super_admin'::app_role);

REVOKE ALL ON public.employee_celebrations_public FROM PUBLIC, anon;
GRANT SELECT ON public.employee_celebrations_public TO authenticated;

-- =========================================================================
-- 5. RPC: get_employee_pii — full personal data (HR/admin/director/super_admin/self)
-- =========================================================================
CREATE OR REPLACE FUNCTION public.get_employee_pii(_user_id uuid)
RETURNS TABLE (
  id                       uuid,
  company_id               uuid,
  full_name                text,
  email                    text,
  avatar_url               text,
  cover_url                text,
  bio                      text,
  cpf                      text,
  rg                       text,
  birth_date               date,
  gender                   text,
  nationality              text,
  height                   integer,
  phone                    text,
  emergency_contact_name   text,
  emergency_contact_phone  text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _company uuid;
BEGIN
  SELECT p.company_id INTO _company FROM public.profiles p WHERE p.id = _user_id;
  IF _company IS NULL THEN
    RETURN;
  END IF;

  IF NOT (
    _user_id = auth.uid()
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
    OR (
      _company = public.user_company_id(auth.uid())
      AND (
        public.has_role(auth.uid(), 'hr'::app_role)
        OR public.has_role(auth.uid(), 'admin'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
      )
    )
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT p.id, p.company_id, p.full_name, p.email, p.avatar_url,
         p.cover_url, p.bio, p.cpf, p.rg, p.birth_date, p.gender,
         p.nationality, p.height, p.phone,
         p.emergency_contact_name, p.emergency_contact_phone
  FROM public.profiles p
  WHERE p.id = _user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_employee_pii(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_employee_pii(uuid) TO authenticated;

-- =========================================================================
-- 6. RPC: get_employee_hr_profile — labor data (hire_date, status)
-- =========================================================================
CREATE OR REPLACE FUNCTION public.get_employee_hr_profile(_user_id uuid)
RETURNS TABLE (
  id         uuid,
  company_id uuid,
  full_name  text,
  hire_date  date,
  status     text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _company uuid;
BEGIN
  SELECT p.company_id INTO _company FROM public.profiles p WHERE p.id = _user_id;
  IF _company IS NULL THEN
    RETURN;
  END IF;

  IF NOT (
    _user_id = auth.uid()
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
    OR (
      _company = public.user_company_id(auth.uid())
      AND (
        public.has_role(auth.uid(), 'hr'::app_role)
        OR public.has_role(auth.uid(), 'admin'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
      )
    )
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT p.id, p.company_id, p.full_name, p.hire_date, p.status
  FROM public.profiles p
  WHERE p.id = _user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_employee_hr_profile(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_employee_hr_profile(uuid) TO authenticated;