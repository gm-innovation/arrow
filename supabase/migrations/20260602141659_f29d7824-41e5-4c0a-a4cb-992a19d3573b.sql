ALTER TABLE public.companies
  ADD COLUMN IF NOT EXISTS careers_about_title text,
  ADD COLUMN IF NOT EXISTS careers_about_text text,
  ADD COLUMN IF NOT EXISTS careers_mission text,
  ADD COLUMN IF NOT EXISTS careers_values text[];

CREATE TABLE IF NOT EXISTS public.company_benefits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  icon text,
  display_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_company_benefits_company ON public.company_benefits(company_id, display_order);

GRANT SELECT ON public.company_benefits TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.company_benefits TO authenticated;
GRANT ALL ON public.company_benefits TO service_role;

ALTER TABLE public.company_benefits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active benefits"
ON public.company_benefits
FOR SELECT
USING (is_active = true);

CREATE POLICY "Staff can manage own company benefits"
ON public.company_benefits
FOR ALL
TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'hr')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'coordinator')
    OR public.has_role(auth.uid(), 'super_admin')
  )
)
WITH CHECK (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'hr')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'coordinator')
    OR public.has_role(auth.uid(), 'super_admin')
  )
);

CREATE TRIGGER update_company_benefits_updated_at
BEFORE UPDATE ON public.company_benefits
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();