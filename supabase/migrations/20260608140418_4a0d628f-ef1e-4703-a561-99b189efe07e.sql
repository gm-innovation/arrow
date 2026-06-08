
ALTER TABLE public.quality_org_context
  ADD COLUMN IF NOT EXISTS next_review_due_at date;

CREATE TABLE public.quality_context_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  category text NOT NULL CHECK (category IN (
    'swot_strength','swot_weakness','swot_opportunity','swot_threat',
    'pestal_political','pestal_economic','pestal_social',
    'pestal_technological','pestal_environmental','pestal_legal'
  )),
  title text NOT NULL,
  description text,
  impact_level text CHECK (impact_level IN ('low','medium','high')),
  position integer NOT NULL DEFAULT 0,
  linked_risk_id uuid REFERENCES public.quality_risks(id) ON DELETE SET NULL,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_context_items TO authenticated;
GRANT ALL ON public.quality_context_items TO service_role;
ALTER TABLE public.quality_context_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qci_select" ON public.quality_context_items FOR SELECT
  USING (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role)
      OR public.has_role(auth.uid(),'director'::app_role)
      OR public.has_role(auth.uid(),'super_admin'::app_role)));

CREATE POLICY "qci_write" ON public.quality_context_items FOR ALL
  USING (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role) OR public.has_role(auth.uid(),'super_admin'::app_role)))
  WITH CHECK (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role) OR public.has_role(auth.uid(),'super_admin'::app_role)));

CREATE TRIGGER trg_qci_updated_at BEFORE UPDATE ON public.quality_context_items
  FOR EACH ROW EXECUTE FUNCTION public.quality_set_updated_at();

CREATE INDEX idx_qci_company_category ON public.quality_context_items(company_id, category, position);

CREATE TABLE public.quality_context_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  version_number integer NOT NULL,
  scope text,
  internal_issues text,
  external_issues text,
  items_snapshot jsonb NOT NULL DEFAULT '[]'::jsonb,
  reviewed_by uuid,
  reviewed_at timestamptz NOT NULL DEFAULT now(),
  review_notes text,
  approved boolean NOT NULL DEFAULT false,
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, version_number)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_context_versions TO authenticated;
GRANT ALL ON public.quality_context_versions TO service_role;
ALTER TABLE public.quality_context_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qcv_select" ON public.quality_context_versions FOR SELECT
  USING (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role)
      OR public.has_role(auth.uid(),'director'::app_role)
      OR public.has_role(auth.uid(),'super_admin'::app_role)));

CREATE POLICY "qcv_write" ON public.quality_context_versions FOR ALL
  USING (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role) OR public.has_role(auth.uid(),'super_admin'::app_role)))
  WITH CHECK (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role) OR public.has_role(auth.uid(),'super_admin'::app_role)));

CREATE INDEX idx_qcv_company_version ON public.quality_context_versions(company_id, version_number DESC);

CREATE OR REPLACE FUNCTION public.set_quality_context_version_number()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.version_number IS NULL OR NEW.version_number = 0 THEN
    SELECT COALESCE(MAX(version_number), 0) + 1
      INTO NEW.version_number
      FROM public.quality_context_versions
      WHERE company_id = NEW.company_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_qcv_version_number BEFORE INSERT ON public.quality_context_versions
  FOR EACH ROW EXECUTE FUNCTION public.set_quality_context_version_number();
