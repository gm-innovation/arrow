
CREATE TABLE public.quality_objectives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  code TEXT,
  title TEXT NOT NULL,
  description TEXT,
  owner_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  policy_version_id UUID REFERENCES public.quality_policy_versions(id) ON DELETE SET NULL,
  period_start DATE,
  period_end DATE,
  status TEXT NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','ativo','concluido','cancelado')),
  target_value NUMERIC,
  unit TEXT,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_qobj_company ON public.quality_objectives(company_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_objectives TO authenticated;
GRANT ALL ON public.quality_objectives TO service_role;
ALTER TABLE public.quality_objectives ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qobj_select" ON public.quality_objectives FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "qobj_manage" ON public.quality_objectives FOR ALL TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (
  public.has_role(auth.uid(), 'qualidade'::app_role) OR
  public.has_role(auth.uid(), 'director'::app_role) OR
  public.has_role(auth.uid(), 'super_admin'::app_role)
))
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND (
  public.has_role(auth.uid(), 'qualidade'::app_role) OR
  public.has_role(auth.uid(), 'director'::app_role) OR
  public.has_role(auth.uid(), 'super_admin'::app_role)
));
CREATE TRIGGER trg_qobj_updated_at BEFORE UPDATE ON public.quality_objectives
FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE TABLE public.quality_indicators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  objective_id UUID REFERENCES public.quality_objectives(id) ON DELETE SET NULL,
  code TEXT,
  name TEXT NOT NULL,
  unit TEXT,
  target_value NUMERIC,
  formula TEXT,
  frequency TEXT NOT NULL DEFAULT 'mensal' CHECK (frequency IN ('mensal','trimestral','semestral','anual')),
  responsible_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo','pausado','arquivado')),
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_qind_company ON public.quality_indicators(company_id);
CREATE INDEX idx_qind_objective ON public.quality_indicators(objective_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_indicators TO authenticated;
GRANT ALL ON public.quality_indicators TO service_role;
ALTER TABLE public.quality_indicators ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qind_select" ON public.quality_indicators FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "qind_manage" ON public.quality_indicators FOR ALL TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (
  public.has_role(auth.uid(), 'qualidade'::app_role) OR
  public.has_role(auth.uid(), 'director'::app_role) OR
  public.has_role(auth.uid(), 'super_admin'::app_role)
))
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND (
  public.has_role(auth.uid(), 'qualidade'::app_role) OR
  public.has_role(auth.uid(), 'director'::app_role) OR
  public.has_role(auth.uid(), 'super_admin'::app_role)
));
CREATE TRIGGER trg_qind_updated_at BEFORE UPDATE ON public.quality_indicators
FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE TABLE public.quality_indicator_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  indicator_id UUID NOT NULL REFERENCES public.quality_indicators(id) ON DELETE CASCADE,
  period_label TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  value NUMERIC NOT NULL,
  note TEXT,
  measured_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (indicator_id, period_start, period_end)
);
CREATE INDEX idx_qindm_company ON public.quality_indicator_measurements(company_id);
CREATE INDEX idx_qindm_indicator ON public.quality_indicator_measurements(indicator_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_indicator_measurements TO authenticated;
GRANT ALL ON public.quality_indicator_measurements TO service_role;
ALTER TABLE public.quality_indicator_measurements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qindm_select" ON public.quality_indicator_measurements FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "qindm_manage" ON public.quality_indicator_measurements FOR ALL TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (
  public.has_role(auth.uid(), 'qualidade'::app_role) OR
  public.has_role(auth.uid(), 'director'::app_role) OR
  public.has_role(auth.uid(), 'super_admin'::app_role)
))
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND (
  public.has_role(auth.uid(), 'qualidade'::app_role) OR
  public.has_role(auth.uid(), 'director'::app_role) OR
  public.has_role(auth.uid(), 'super_admin'::app_role)
));
CREATE TRIGGER trg_qindm_updated_at BEFORE UPDATE ON public.quality_indicator_measurements
FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE TABLE public.quality_planned_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  code TEXT,
  title TEXT NOT NULL,
  description TEXT,
  change_type TEXT NOT NULL DEFAULT 'processo' CHECK (change_type IN ('processo','documento','recurso','estrutura','sistema','outro')),
  justification TEXT,
  impact_assessment TEXT,
  planned_for DATE,
  status TEXT NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','em_analise','aprovada','implementada','rejeitada')),
  requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  implemented_at TIMESTAMPTZ,
  linked_risk_ids UUID[] NOT NULL DEFAULT ARRAY[]::UUID[],
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_qpchg_company ON public.quality_planned_changes(company_id);
CREATE INDEX idx_qpchg_status ON public.quality_planned_changes(status);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_planned_changes TO authenticated;
GRANT ALL ON public.quality_planned_changes TO service_role;
ALTER TABLE public.quality_planned_changes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qpchg_select" ON public.quality_planned_changes FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "qpchg_manage" ON public.quality_planned_changes FOR ALL TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (
  public.has_role(auth.uid(), 'qualidade'::app_role) OR
  public.has_role(auth.uid(), 'director'::app_role) OR
  public.has_role(auth.uid(), 'super_admin'::app_role)
))
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND (
  public.has_role(auth.uid(), 'qualidade'::app_role) OR
  public.has_role(auth.uid(), 'director'::app_role) OR
  public.has_role(auth.uid(), 'super_admin'::app_role)
));
CREATE TRIGGER trg_qpchg_updated_at BEFORE UPDATE ON public.quality_planned_changes
FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

ALTER TABLE public.quality_action_plans
  ADD COLUMN IF NOT EXISTS objective_id UUID REFERENCES public.quality_objectives(id) ON DELETE SET NULL;
ALTER TABLE public.quality_risk_actions
  ADD COLUMN IF NOT EXISTS objective_id UUID REFERENCES public.quality_objectives(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_qap_objective ON public.quality_action_plans(objective_id);
CREATE INDEX IF NOT EXISTS idx_qra_objective ON public.quality_risk_actions(objective_id);
