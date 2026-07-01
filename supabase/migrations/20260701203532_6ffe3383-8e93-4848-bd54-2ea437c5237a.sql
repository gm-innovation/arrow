
CREATE TABLE public.quality_competitors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL,
  name TEXT NOT NULL,
  market_segment TEXT,
  size_category TEXT,
  positioning TEXT,
  estimated_market_share NUMERIC(5,2),
  price_range TEXT,
  strengths TEXT,
  weaknesses TEXT,
  notes TEXT,
  website TEXT,
  interested_party_id UUID REFERENCES public.quality_interested_parties(id) ON DELETE SET NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_competitors TO authenticated;
GRANT ALL ON public.quality_competitors TO service_role;
ALTER TABLE public.quality_competitors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "competitors_select_company" ON public.quality_competitors
  FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));

CREATE POLICY "competitors_write_quality" ON public.quality_competitors
  FOR ALL TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'qualidade'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  )
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'qualidade'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );

CREATE TRIGGER trg_quality_competitors_updated
  BEFORE UPDATE ON public.quality_competitors
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE INDEX idx_quality_competitors_company ON public.quality_competitors(company_id) WHERE is_active;

CREATE TABLE public.quality_competitor_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL,
  title TEXT NOT NULL,
  analysis_period TEXT,
  summary TEXT,
  methodology TEXT,
  conclusions TEXT,
  author_user_id UUID,
  performed_at DATE NOT NULL DEFAULT CURRENT_DATE,
  next_review_at DATE,
  status TEXT NOT NULL DEFAULT 'draft',
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_competitor_analyses TO authenticated;
GRANT ALL ON public.quality_competitor_analyses TO service_role;
ALTER TABLE public.quality_competitor_analyses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comp_analyses_select_company" ON public.quality_competitor_analyses
  FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));

CREATE POLICY "comp_analyses_write_quality" ON public.quality_competitor_analyses
  FOR ALL TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'qualidade'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  )
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'qualidade'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );

CREATE TRIGGER trg_quality_competitor_analyses_updated
  BEFORE UPDATE ON public.quality_competitor_analyses
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE TABLE public.quality_competitor_analysis_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id UUID NOT NULL REFERENCES public.quality_competitor_analyses(id) ON DELETE CASCADE,
  competitor_id UUID REFERENCES public.quality_competitors(id) ON DELETE CASCADE,
  dimension TEXT NOT NULL,
  our_position TEXT,
  competitor_position TEXT,
  gap_type TEXT,
  gap_description TEXT,
  recommended_action TEXT,
  linked_risk_id UUID REFERENCES public.quality_risks(id) ON DELETE SET NULL,
  linked_context_item_id UUID REFERENCES public.quality_context_items(id) ON DELETE SET NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_competitor_analysis_items TO authenticated;
GRANT ALL ON public.quality_competitor_analysis_items TO service_role;
ALTER TABLE public.quality_competitor_analysis_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comp_items_select_company" ON public.quality_competitor_analysis_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quality_competitor_analyses a
      WHERE a.id = analysis_id AND a.company_id = public.user_company_id(auth.uid())
    )
  );

CREATE POLICY "comp_items_write_quality" ON public.quality_competitor_analysis_items
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quality_competitor_analyses a
      WHERE a.id = analysis_id AND a.company_id = public.user_company_id(auth.uid())
    )
    AND (
      public.has_role(auth.uid(), 'qualidade'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.quality_competitor_analyses a
      WHERE a.id = analysis_id AND a.company_id = public.user_company_id(auth.uid())
    )
    AND (
      public.has_role(auth.uid(), 'qualidade'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );

CREATE TRIGGER trg_quality_competitor_analysis_items_updated
  BEFORE UPDATE ON public.quality_competitor_analysis_items
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE INDEX idx_comp_items_analysis ON public.quality_competitor_analysis_items(analysis_id);

ALTER TABLE public.quality_objectives
  ADD COLUMN IF NOT EXISTS objective_scope TEXT NOT NULL DEFAULT 'quality',
  ADD COLUMN IF NOT EXISTS time_horizon TEXT,
  ADD COLUMN IF NOT EXISTS linked_to TEXT,
  ADD COLUMN IF NOT EXISTS parent_objective_id UUID REFERENCES public.quality_objectives(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_quality_objectives_scope
  ON public.quality_objectives(company_id, objective_scope);
