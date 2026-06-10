
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS position TEXT;

CREATE TABLE public.hr_document_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL,
  name TEXT NOT NULL,
  code TEXT,
  description TEXT,
  category TEXT NOT NULL DEFAULT 'outro',
  is_required BOOLEAN NOT NULL DEFAULT true,
  has_expiry BOOLEAN NOT NULL DEFAULT false,
  default_validity_months INTEGER,
  renewal_warning_days INTEGER NOT NULL DEFAULT 30,
  responsible_role TEXT NOT NULL DEFAULT 'hr',
  applies_to_all BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.hr_document_catalog TO authenticated;
GRANT ALL ON public.hr_document_catalog TO service_role;
ALTER TABLE public.hr_document_catalog ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Catalog viewable by company members"
ON public.hr_document_catalog FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));

CREATE POLICY "Catalog managed by HR/Director/SuperAdmin"
ON public.hr_document_catalog FOR ALL TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'super_admin'))
)
WITH CHECK (
  company_id = public.user_company_id(auth.uid())
  AND (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'super_admin'))
);

CREATE TRIGGER trg_hr_document_catalog_updated_at
BEFORE UPDATE ON public.hr_document_catalog
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE public.hr_document_catalog_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  catalog_id UUID NOT NULL REFERENCES public.hr_document_catalog(id) ON DELETE CASCADE,
  position TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (catalog_id, position)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.hr_document_catalog_positions TO authenticated;
GRANT ALL ON public.hr_document_catalog_positions TO service_role;
ALTER TABLE public.hr_document_catalog_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Catalog positions viewable by company members"
ON public.hr_document_catalog_positions FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.hr_document_catalog c
  WHERE c.id = catalog_id AND c.company_id = public.user_company_id(auth.uid())
));

CREATE POLICY "Catalog positions managed by HR/Director/SuperAdmin"
ON public.hr_document_catalog_positions FOR ALL TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.hr_document_catalog c
  WHERE c.id = catalog_id
    AND c.company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'super_admin'))
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.hr_document_catalog c
  WHERE c.id = catalog_id
    AND c.company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'super_admin'))
));

CREATE OR REPLACE FUNCTION public.hr_catalog_clear_positions_if_all()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.applies_to_all = true AND (TG_OP = 'INSERT' OR OLD.applies_to_all = false) THEN
    DELETE FROM public.hr_document_catalog_positions WHERE catalog_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_hr_catalog_clear_positions
AFTER INSERT OR UPDATE OF applies_to_all ON public.hr_document_catalog
FOR EACH ROW EXECUTE FUNCTION public.hr_catalog_clear_positions_if_all();
