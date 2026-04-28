-- 1. Helper para roles operacionais
CREATE OR REPLACE FUNCTION public.is_operational_role(_user_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT
    public.has_role(_user_id, 'coordinator'::app_role) OR
    public.has_role(_user_id, 'director'::app_role)    OR
    public.has_role(_user_id, 'commercial'::app_role)  OR
    public.has_role(_user_id, 'super_admin'::app_role)
$$;

-- 2. Limpar policies legadas com roles inexistentes
DROP POLICY IF EXISTS "Admins can manage vessels in their company" ON public.vessels;
DROP POLICY IF EXISTS "Managers can view all company vessels"      ON public.vessels;

-- 3. INSERT
CREATE POLICY "Operational roles can insert vessels"
ON public.vessels FOR INSERT TO authenticated
WITH CHECK (
  public.is_operational_role(auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.clients c
    WHERE c.id = vessels.client_id
      AND c.company_id = public.user_company_id(auth.uid())
  )
);

-- 4. UPDATE (USING e WITH CHECK simétricos)
CREATE POLICY "Operational roles can update vessels"
ON public.vessels FOR UPDATE TO authenticated
USING (
  public.is_operational_role(auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.clients c
    WHERE c.id = vessels.client_id
      AND c.company_id = public.user_company_id(auth.uid())
  )
)
WITH CHECK (
  public.is_operational_role(auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.clients c
    WHERE c.id = vessels.client_id
      AND c.company_id = public.user_company_id(auth.uid())
  )
);

-- 5. DELETE
CREATE POLICY "Privileged roles can delete vessels"
ON public.vessels FOR DELETE TO authenticated
USING (
  (
    public.has_role(auth.uid(), 'coordinator'::app_role) OR
    public.has_role(auth.uid(), 'director'::app_role)    OR
    public.has_role(auth.uid(), 'super_admin'::app_role)
  )
  AND EXISTS (
    SELECT 1 FROM public.clients c
    WHERE c.id = vessels.client_id
      AND c.company_id = public.user_company_id(auth.uid())
  )
);