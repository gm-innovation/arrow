
-- ============================================================
-- ONDA 6 — Quick wins + Lacunas §7
-- ============================================================

-- 1) §4.3 — Exclusões de escopo estruturadas
ALTER TABLE public.quality_org_context
  ADD COLUMN IF NOT EXISTS excluded_clauses jsonb NOT NULL DEFAULT '[]'::jsonb;

CREATE OR REPLACE FUNCTION public.quality_validate_excluded_clauses()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  item jsonb;
BEGIN
  IF NEW.excluded_clauses IS NULL THEN
    NEW.excluded_clauses := '[]'::jsonb;
    RETURN NEW;
  END IF;
  IF jsonb_typeof(NEW.excluded_clauses) <> 'array' THEN
    RAISE EXCEPTION 'excluded_clauses deve ser um array JSON';
  END IF;
  FOR item IN SELECT * FROM jsonb_array_elements(NEW.excluded_clauses)
  LOOP
    IF jsonb_typeof(item) <> 'object' THEN
      RAISE EXCEPTION 'Cada exclusão deve ser um objeto JSON';
    END IF;
    IF NOT (item ? 'clause') OR length(coalesce(item->>'clause','')) = 0 THEN
      RAISE EXCEPTION 'Exclusão sem campo "clause"';
    END IF;
    IF NOT (item ? 'title') OR length(coalesce(item->>'title','')) = 0 THEN
      RAISE EXCEPTION 'Exclusão sem campo "title"';
    END IF;
    IF NOT (item ? 'justification') OR length(coalesce(item->>'justification','')) = 0 THEN
      RAISE EXCEPTION 'Exclusão sem campo "justification"';
    END IF;
    IF NOT (item ? 'approved_at') OR length(coalesce(item->>'approved_at','')) = 0 THEN
      RAISE EXCEPTION 'Exclusão sem campo "approved_at"';
    END IF;
    IF NOT (item ? 'approved_by') OR length(coalesce(item->>'approved_by','')) = 0 THEN
      RAISE EXCEPTION 'Exclusão sem campo "approved_by"';
    END IF;
  END LOOP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_qoc_validate_excluded ON public.quality_org_context;
CREATE TRIGGER trg_qoc_validate_excluded
  BEFORE INSERT OR UPDATE OF excluded_clauses ON public.quality_org_context
  FOR EACH ROW EXECUTE FUNCTION public.quality_validate_excluded_clauses();

-- 2) §10.3 — Eficácia de melhorias com prazo
ALTER TABLE public.quality_improvements_manual
  ADD COLUMN IF NOT EXISTS effectiveness_review_due_at date,
  ADD COLUMN IF NOT EXISTS effectiveness_review_period_days integer;

-- 3) Push notifications atrás de feature flag
ALTER TABLE public.quality_settings
  ADD COLUMN IF NOT EXISTS enable_push_notifications boolean NOT NULL DEFAULT false;

-- 4) §7.1.6 — Conhecimento Organizacional
CREATE TABLE IF NOT EXISTS public.quality_knowledge_articles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL DEFAULT '',
  category text,
  tags text[] NOT NULL DEFAULT '{}',
  source_type text,
  source_id uuid,
  author_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','archived')),
  version integer NOT NULL DEFAULT 1,
  published_at timestamptz,
  review_period_months integer NOT NULL DEFAULT 12,
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  review_due_at date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_knowledge_articles TO authenticated;
GRANT ALL ON public.quality_knowledge_articles TO service_role;
ALTER TABLE public.quality_knowledge_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qka_select" ON public.quality_knowledge_articles
  FOR SELECT TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  );

CREATE POLICY "qka_write" ON public.quality_knowledge_articles
  FOR ALL TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  )
  WITH CHECK (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  );

CREATE INDEX IF NOT EXISTS idx_qka_company ON public.quality_knowledge_articles (company_id);
CREATE INDEX IF NOT EXISTS idx_qka_source ON public.quality_knowledge_articles (source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_qka_review_due ON public.quality_knowledge_articles (review_due_at);

CREATE OR REPLACE FUNCTION public.quality_knowledge_recalc_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.reviewed_at IS NOT NULL AND NEW.review_period_months IS NOT NULL THEN
    NEW.review_due_at := (NEW.reviewed_at + (NEW.review_period_months || ' months')::interval)::date;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_qka_recalc_review
  BEFORE INSERT OR UPDATE OF reviewed_at, review_period_months
  ON public.quality_knowledge_articles
  FOR EACH ROW EXECUTE FUNCTION public.quality_knowledge_recalc_review();

CREATE TRIGGER trg_qka_updated_at
  BEFORE UPDATE ON public.quality_knowledge_articles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 5) §7.4 — Plano de Comunicação
DO $$ BEGIN
  CREATE TYPE public.quality_communication_type AS ENUM (
    'training','quality_policy','meeting','campaign','alert','management_review','other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.quality_communication_plan (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  subject text NOT NULL,
  communication_type public.quality_communication_type NOT NULL DEFAULT 'other',
  target_audience text NOT NULL DEFAULT '',
  channel text NOT NULL DEFAULT '',
  frequency text NOT NULL DEFAULT '',
  owner_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  next_scheduled_at timestamptz,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','paused','archived')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_communication_plan TO authenticated;
GRANT ALL ON public.quality_communication_plan TO service_role;
ALTER TABLE public.quality_communication_plan ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qcp_select" ON public.quality_communication_plan
  FOR SELECT TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  );

CREATE POLICY "qcp_write" ON public.quality_communication_plan
  FOR ALL TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  )
  WITH CHECK (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  );

CREATE INDEX IF NOT EXISTS idx_qcp_company ON public.quality_communication_plan (company_id);
CREATE INDEX IF NOT EXISTS idx_qcp_next ON public.quality_communication_plan (next_scheduled_at);

CREATE TRIGGER trg_qcp_updated_at
  BEFORE UPDATE ON public.quality_communication_plan
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE IF NOT EXISTS public.quality_communication_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.quality_communication_plan(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  executed_at timestamptz NOT NULL DEFAULT now(),
  executed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  evidence_url text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_communication_log TO authenticated;
GRANT ALL ON public.quality_communication_log TO service_role;
ALTER TABLE public.quality_communication_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qcl_select" ON public.quality_communication_log
  FOR SELECT TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  );

CREATE POLICY "qcl_write" ON public.quality_communication_log
  FOR ALL TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  )
  WITH CHECK (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      has_role(auth.uid(),'qualidade'::app_role)
      OR has_role(auth.uid(),'coordinator'::app_role)
      OR has_role(auth.uid(),'director'::app_role)
      OR has_role(auth.uid(),'super_admin'::app_role)
    )
  );

CREATE INDEX IF NOT EXISTS idx_qcl_plan ON public.quality_communication_log (plan_id, executed_at DESC);

-- 6) Estender quality_alerts_v com novas fontes
CREATE OR REPLACE VIEW public.quality_alerts_v AS
WITH s AS (
  SELECT company_id,
    COALESCE((review_cycles->>'alert_window_days')::int, 30) AS alert_window_days
  FROM public.quality_settings
)
SELECT source, category, entity_id, company_id, title, due_date, status, days_remaining FROM (

  SELECT 'org_context'::text AS source, 'org_context'::text AS category,
    c.id AS entity_id, c.company_id,
    'Contexto da Organização'::text AS title,
    c.next_review_due_at AS due_date,
    CASE
      WHEN c.next_review_due_at IS NULL THEN NULL
      WHEN c.next_review_due_at < CURRENT_DATE THEN 'overdue'
      WHEN c.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id = c.company_id),30) THEN 'due_soon'
      ELSE 'up_to_date' END AS status,
    (c.next_review_due_at - CURRENT_DATE) AS days_remaining
  FROM public.quality_org_context c WHERE c.next_review_due_at IS NOT NULL

  UNION ALL
  SELECT 'interested_party','interested_party', p.id, p.company_id, p.name, p.next_review_due_at,
    CASE WHEN p.next_review_due_at IS NULL THEN NULL
      WHEN p.next_review_due_at < CURRENT_DATE THEN 'overdue'
      WHEN p.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id = p.company_id),30) THEN 'due_soon'
      ELSE 'up_to_date' END,
    (p.next_review_due_at - CURRENT_DATE)
  FROM public.quality_interested_parties p
  WHERE p.next_review_due_at IS NOT NULL AND p.status = 'ativo'

  UNION ALL
  SELECT 'party_evidence','party_evidence', e.id, p.company_id,
    (p.name || ' — ' || e.title), e.valid_until,
    CASE WHEN e.valid_until < CURRENT_DATE THEN 'overdue'
      WHEN e.valid_until <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id = p.company_id),30) THEN 'due_soon'
      ELSE 'up_to_date' END,
    (e.valid_until - CURRENT_DATE)
  FROM public.quality_interested_party_evidences e
  JOIN public.quality_interested_parties p ON p.id = e.party_id
  WHERE e.valid_until IS NOT NULL

  UNION ALL
  SELECT 'risk','risk_review', r.id, r.company_id,
    ('Revisão de risco: ' || r.code || ' — ' || r.title), r.next_review_due_at,
    CASE WHEN r.next_review_due_at IS NULL THEN NULL
      WHEN r.next_review_due_at < CURRENT_DATE THEN 'overdue'
      WHEN r.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id = r.company_id),30) THEN 'due_soon'
      ELSE 'up_to_date' END,
    (r.next_review_due_at - CURRENT_DATE)
  FROM public.quality_risks r
  WHERE r.next_review_due_at IS NOT NULL
    AND r.status NOT IN ('closed'::quality_risk_status,'accepted'::quality_risk_status)

  UNION ALL
  SELECT 'risk','risk_treatment', r.id, r.company_id,
    ('Tratamento atrasado: ' || r.code || ' — ' || r.title), r.treatment_due_date,
    CASE WHEN r.treatment_due_date IS NULL THEN NULL
      WHEN r.treatment_due_date < CURRENT_DATE THEN 'overdue'
      WHEN r.treatment_due_date <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id = r.company_id),30) THEN 'due_soon'
      ELSE 'up_to_date' END,
    (r.treatment_due_date - CURRENT_DATE)
  FROM public.quality_risks r
  WHERE r.treatment_due_date IS NOT NULL
    AND r.status IN ('analyzing'::quality_risk_status,'treating'::quality_risk_status)

  UNION ALL
  SELECT 'supplier','requalification', sup.id, sup.company_id, sup.name, sup.next_evaluation_due,
    CASE WHEN sup.next_evaluation_due IS NULL THEN NULL
      WHEN sup.next_evaluation_due < CURRENT_DATE THEN 'overdue'
      WHEN sup.next_evaluation_due <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id = sup.company_id),30) THEN 'due_soon'
      ELSE 'up_to_date' END,
    (sup.next_evaluation_due - CURRENT_DATE)
  FROM public.quality_suppliers sup
  WHERE sup.next_evaluation_due IS NOT NULL
    AND sup.status IN ('approved'::quality_supplier_status,'conditional'::quality_supplier_status)

  UNION ALL
  SELECT 'supplier','pending_qualification', sup.id, sup.company_id, sup.name,
    (sup.created_at + interval '30 days')::date,
    CASE WHEN (sup.created_at + interval '30 days')::date < CURRENT_DATE THEN 'overdue' ELSE 'due_soon' END,
    ((sup.created_at + interval '30 days')::date - CURRENT_DATE)
  FROM public.quality_suppliers sup
  WHERE sup.status = 'pending'::quality_supplier_status

  UNION ALL
  SELECT 'device','calibration', d.id, d.company_id,
    ('Calibração: ' || d.code || ' — ' || d.name), d.next_calibration_due,
    CASE WHEN d.next_calibration_due IS NULL THEN NULL
      WHEN d.next_calibration_due < CURRENT_DATE THEN 'overdue'
      WHEN d.next_calibration_due <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id = d.company_id),30) THEN 'due_soon'
      ELSE 'up_to_date' END,
    (d.next_calibration_due - CURRENT_DATE)
  FROM public.quality_measuring_devices d
  WHERE d.next_calibration_due IS NOT NULL
    AND d.status IN ('active'::quality_device_status,'in_calibration'::quality_device_status,'overdue'::quality_device_status)

  -- NOVO: calibração reprovada (alerta crítico)
  UNION ALL
  SELECT 'calibration_reproved','calibration_reproved', cal.id, cal.company_id,
    ('Calibração REPROVADA — ' || d.code || ' — ' || d.name),
    cal.calibration_date,
    'overdue'::text,
    (cal.calibration_date - CURRENT_DATE)
  FROM public.quality_calibrations cal
  JOIN public.quality_measuring_devices d ON d.id = cal.device_id
  WHERE cal.result = 'reproved'::quality_calibration_result
    AND cal.calibration_date >= CURRENT_DATE - interval '180 days'

  -- NOVO: eficácia de melhoria vencida
  UNION ALL
  SELECT 'improvement','effectiveness_due', m.id, m.company_id,
    ('Avaliar eficácia: ' || m.title),
    m.effectiveness_review_due_at,
    CASE WHEN m.effectiveness_review_due_at < CURRENT_DATE THEN 'overdue' ELSE 'due_soon' END,
    (m.effectiveness_review_due_at - CURRENT_DATE)
  FROM public.quality_improvements_manual m
  WHERE m.effectiveness_review_due_at IS NOT NULL
    AND m.effectiveness_status = 'pendente'
    AND m.status IN ('done','in_progress')

  -- NOVO: revisão de artigo de conhecimento atrasada
  UNION ALL
  SELECT 'knowledge','knowledge_review', k.id, k.company_id,
    ('Revisar conhecimento: ' || k.title),
    k.review_due_at,
    CASE WHEN k.review_due_at IS NULL THEN NULL
      WHEN k.review_due_at < CURRENT_DATE THEN 'overdue'
      WHEN k.review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id = k.company_id),30) THEN 'due_soon'
      ELSE 'up_to_date' END,
    (k.review_due_at - CURRENT_DATE)
  FROM public.quality_knowledge_articles k
  WHERE k.review_due_at IS NOT NULL AND k.status = 'published'

) u;

GRANT SELECT ON public.quality_alerts_v TO authenticated;
GRANT SELECT ON public.quality_alerts_v TO service_role;
