
-- ============================================================
-- SPRINT 3.5 — Riscos & Oportunidades + Pré-requisitos + SGQ Feed
-- ============================================================

-- ============ ENUMS ============
DO $$ BEGIN CREATE TYPE public.quality_risk_kind AS ENUM ('risk','opportunity'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.quality_risk_status AS ENUM ('identified','analyzing','treating','monitoring','accepted','closed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.quality_risk_treatment AS ENUM ('avoid','mitigate','transfer','accept','exploit','enhance','share','ignore'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.quality_risk_source AS ENUM ('context','interested_party','process','audit','ncr','management_review','manual'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.quality_risk_action_status AS ENUM ('open','in_progress','done','cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============ HELPER (utilitária) ============
CREATE OR REPLACE FUNCTION public.quality_compute_risk_severity(p_score smallint)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN p_score IS NULL THEN NULL
    WHEN p_score BETWEEN 1 AND 4 THEN 'low'
    WHEN p_score BETWEEN 5 AND 9 THEN 'medium'
    WHEN p_score BETWEEN 10 AND 15 THEN 'high'
    WHEN p_score BETWEEN 16 AND 25 THEN 'critical'
    ELSE NULL
  END
$$;

-- ============ TABELA: quality_risks ============
CREATE TABLE IF NOT EXISTS public.quality_risks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  code text,
  kind public.quality_risk_kind NOT NULL DEFAULT 'risk',
  title text NOT NULL,
  description text,
  source public.quality_risk_source NOT NULL DEFAULT 'manual',
  source_ref_id uuid,
  category text,
  owner_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  probability smallint NOT NULL CHECK (probability BETWEEN 1 AND 5),
  impact smallint NOT NULL CHECK (impact BETWEEN 1 AND 5),
  score smallint GENERATED ALWAYS AS (probability * impact) STORED,
  severity text GENERATED ALWAYS AS (
    CASE
      WHEN probability * impact BETWEEN 1 AND 4 THEN 'low'
      WHEN probability * impact BETWEEN 5 AND 9 THEN 'medium'
      WHEN probability * impact BETWEEN 10 AND 15 THEN 'high'
      WHEN probability * impact BETWEEN 16 AND 25 THEN 'critical'
      ELSE NULL
    END
  ) STORED,
  residual_probability smallint CHECK (residual_probability IS NULL OR residual_probability BETWEEN 1 AND 5),
  residual_impact smallint CHECK (residual_impact IS NULL OR residual_impact BETWEEN 1 AND 5),
  residual_score smallint GENERATED ALWAYS AS (
    CASE WHEN residual_probability IS NULL OR residual_impact IS NULL THEN NULL
         ELSE residual_probability * residual_impact END
  ) STORED,
  residual_severity text GENERATED ALWAYS AS (
    CASE
      WHEN residual_probability IS NULL OR residual_impact IS NULL THEN NULL
      WHEN residual_probability * residual_impact BETWEEN 1 AND 4 THEN 'low'
      WHEN residual_probability * residual_impact BETWEEN 5 AND 9 THEN 'medium'
      WHEN residual_probability * residual_impact BETWEEN 10 AND 15 THEN 'high'
      WHEN residual_probability * residual_impact BETWEEN 16 AND 25 THEN 'critical'
      ELSE NULL
    END
  ) STORED,
  treatment public.quality_risk_treatment,
  treatment_plan text,
  treatment_due_date date,
  status public.quality_risk_status NOT NULL DEFAULT 'identified',
  status_changed_at timestamptz NOT NULL DEFAULT now(),
  review_frequency_months int NOT NULL DEFAULT 12 CHECK (review_frequency_months > 0),
  last_reviewed_at timestamptz,
  next_review_due_at date,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  closed_at timestamptz,
  closure_notes text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quality_risks_company ON public.quality_risks(company_id);
CREATE INDEX IF NOT EXISTS idx_quality_risks_status ON public.quality_risks(status);
CREATE INDEX IF NOT EXISTS idx_quality_risks_owner ON public.quality_risks(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_quality_risks_next_review ON public.quality_risks(next_review_due_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_risks TO authenticated;
GRANT ALL ON public.quality_risks TO service_role;
ALTER TABLE public.quality_risks ENABLE ROW LEVEL SECURITY;

CREATE POLICY qr_select ON public.quality_risks FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY qr_insert ON public.quality_risks FOR INSERT TO authenticated
  WITH CHECK (company_id = public.user_company_id(auth.uid())
              AND (public.quality_is_master(auth.uid()) OR owner_user_id = auth.uid()));
CREATE POLICY qr_update ON public.quality_risks FOR UPDATE TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
         AND (public.quality_is_master(auth.uid()) OR owner_user_id = auth.uid()))
  WITH CHECK (company_id = public.user_company_id(auth.uid()));
CREATE POLICY qr_delete ON public.quality_risks FOR DELETE TO authenticated
  USING (company_id = public.user_company_id(auth.uid()) AND public.quality_is_master(auth.uid()));

-- ============ TABELA: quality_risk_actions ============
CREATE TABLE IF NOT EXISTS public.quality_risk_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  risk_id uuid NOT NULL REFERENCES public.quality_risks(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  description text NOT NULL,
  responsible_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  due_date date,
  status public.quality_risk_action_status NOT NULL DEFAULT 'open',
  completed_at timestamptz,
  evidence_url text,
  notes text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_quality_risk_actions_risk ON public.quality_risk_actions(risk_id);
CREATE INDEX IF NOT EXISTS idx_quality_risk_actions_company ON public.quality_risk_actions(company_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_risk_actions TO authenticated;
GRANT ALL ON public.quality_risk_actions TO service_role;
ALTER TABLE public.quality_risk_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY qra_select ON public.quality_risk_actions FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY qra_insert ON public.quality_risk_actions FOR INSERT TO authenticated
  WITH CHECK (company_id = public.user_company_id(auth.uid())
              AND (public.quality_is_master(auth.uid())
                   OR EXISTS (SELECT 1 FROM public.quality_risks r WHERE r.id = risk_id AND r.owner_user_id = auth.uid())));
CREATE POLICY qra_update ON public.quality_risk_actions FOR UPDATE TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
         AND (public.quality_is_master(auth.uid())
              OR responsible_id = auth.uid()
              OR EXISTS (SELECT 1 FROM public.quality_risks r WHERE r.id = risk_id AND r.owner_user_id = auth.uid())));
CREATE POLICY qra_delete ON public.quality_risk_actions FOR DELETE TO authenticated
  USING (company_id = public.user_company_id(auth.uid()) AND public.quality_is_master(auth.uid()));

-- ============ TABELA: quality_risk_events ============
CREATE TABLE IF NOT EXISTS public.quality_risk_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  risk_id uuid NOT NULL REFERENCES public.quality_risks(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  old_value jsonb,
  new_value jsonb,
  by_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_quality_risk_events_risk ON public.quality_risk_events(risk_id, at DESC);

GRANT SELECT, INSERT ON public.quality_risk_events TO authenticated;
GRANT ALL ON public.quality_risk_events TO service_role;
ALTER TABLE public.quality_risk_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY qre_select ON public.quality_risk_events FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY qre_insert ON public.quality_risk_events FOR INSERT TO authenticated
  WITH CHECK (company_id = public.user_company_id(auth.uid()));

-- ============ FUNÇÕES E TRIGGERS ============

-- gerar próximo código por ano e empresa
CREATE OR REPLACE FUNCTION public.quality_risk_next_code(p_company_id uuid, p_kind public.quality_risk_kind)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_prefix text := CASE WHEN p_kind = 'opportunity' THEN 'O' ELSE 'R' END;
  v_year text := to_char(now(), 'YYYY');
  v_n int;
BEGIN
  SELECT COALESCE(MAX( (regexp_match(code, '^[RO]-\d{4}-(\d+)$'))[1]::int ), 0) + 1
    INTO v_n
    FROM public.quality_risks
   WHERE company_id = p_company_id
     AND code LIKE v_prefix || '-' || v_year || '-%';
  RETURN v_prefix || '-' || v_year || '-' || lpad(v_n::text, 3, '0');
END $$;

-- BEFORE INSERT/UPDATE: gera code, status_changed_at, closed_at, next_review_due_at
CREATE OR REPLACE FUNCTION public.quality_risks_before_save()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.code IS NULL OR NEW.code = '' THEN
      NEW.code := public.quality_risk_next_code(NEW.company_id, NEW.kind);
    END IF;
    NEW.status_changed_at := now();
    IF NEW.last_reviewed_at IS NOT NULL THEN
      NEW.next_review_due_at := (NEW.last_reviewed_at + (NEW.review_frequency_months || ' months')::interval)::date;
    END IF;
    IF NEW.status = 'closed' AND NEW.closed_at IS NULL THEN
      NEW.closed_at := now();
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
      NEW.status_changed_at := now();
      IF NEW.status = 'closed' AND NEW.closed_at IS NULL THEN
        NEW.closed_at := now();
      END IF;
      IF NEW.status <> 'closed' THEN
        NEW.closed_at := NULL;
      END IF;
    END IF;
    IF (NEW.last_reviewed_at IS DISTINCT FROM OLD.last_reviewed_at
        OR NEW.review_frequency_months IS DISTINCT FROM OLD.review_frequency_months)
       AND NEW.last_reviewed_at IS NOT NULL THEN
      NEW.next_review_due_at := (NEW.last_reviewed_at + (NEW.review_frequency_months || ' months')::interval)::date;
    END IF;
    NEW.updated_at := now();
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_quality_risks_before_save ON public.quality_risks;
CREATE TRIGGER trg_quality_risks_before_save
  BEFORE INSERT OR UPDATE ON public.quality_risks
  FOR EACH ROW EXECUTE FUNCTION public.quality_risks_before_save();

-- AFTER INSERT/UPDATE: registra evento
CREATE OR REPLACE FUNCTION public.quality_risks_after_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.quality_risk_events (risk_id, company_id, event_type, new_value, by_user_id)
    VALUES (NEW.id, NEW.company_id, 'created',
            jsonb_build_object('score', NEW.score, 'status', NEW.status, 'severity', NEW.severity), v_uid);
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.score IS DISTINCT FROM OLD.score THEN
      INSERT INTO public.quality_risk_events (risk_id, company_id, event_type, old_value, new_value, by_user_id)
      VALUES (NEW.id, NEW.company_id, 'reassessed',
              jsonb_build_object('score', OLD.score, 'severity', OLD.severity),
              jsonb_build_object('score', NEW.score, 'severity', NEW.severity), v_uid);
    END IF;
    IF NEW.status IS DISTINCT FROM OLD.status THEN
      INSERT INTO public.quality_risk_events (risk_id, company_id, event_type, old_value, new_value, by_user_id)
      VALUES (NEW.id, NEW.company_id, 'status_changed',
              jsonb_build_object('status', OLD.status),
              jsonb_build_object('status', NEW.status), v_uid);
    END IF;
    IF NEW.last_reviewed_at IS DISTINCT FROM OLD.last_reviewed_at THEN
      INSERT INTO public.quality_risk_events (risk_id, company_id, event_type, new_value, by_user_id)
      VALUES (NEW.id, NEW.company_id, 'reviewed',
              jsonb_build_object('last_reviewed_at', NEW.last_reviewed_at, 'next_review_due_at', NEW.next_review_due_at), v_uid);
    END IF;
  END IF;
  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS trg_quality_risks_after_change ON public.quality_risks;
CREATE TRIGGER trg_quality_risks_after_change
  AFTER INSERT OR UPDATE ON public.quality_risks
  FOR EACH ROW EXECUTE FUNCTION public.quality_risks_after_change();

-- updated_at trigger para risk_actions
CREATE OR REPLACE FUNCTION public.quality_risk_actions_before_save()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    NEW.updated_at := now();
    IF NEW.status = 'done' AND OLD.status <> 'done' AND NEW.completed_at IS NULL THEN
      NEW.completed_at := now();
    END IF;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_quality_risk_actions_before_save ON public.quality_risk_actions;
CREATE TRIGGER trg_quality_risk_actions_before_save
  BEFORE UPDATE ON public.quality_risk_actions
  FOR EACH ROW EXECUTE FUNCTION public.quality_risk_actions_before_save();

-- ============ ESTENDER quality_alerts_v ============
CREATE OR REPLACE VIEW public.quality_alerts_v AS
WITH s AS (
  SELECT quality_settings.company_id,
    COALESCE((quality_settings.review_cycles ->> 'alert_window_days')::int, 30) AS alert_window_days
  FROM public.quality_settings
)
SELECT * FROM (
  -- bloco original
  SELECT 'org_context'::text AS source, 'org_context'::text AS category, c.id AS entity_id, c.company_id,
    'Contexto da Organização'::text AS title, c.next_review_due_at AS due_date,
    CASE
      WHEN c.next_review_due_at IS NULL THEN NULL
      WHEN c.next_review_due_at < CURRENT_DATE THEN 'overdue'
      WHEN c.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = c.company_id), 30)) THEN 'due_soon'
      ELSE 'up_to_date'
    END AS status,
    c.next_review_due_at - CURRENT_DATE AS days_remaining
  FROM public.quality_org_context c
  WHERE c.next_review_due_at IS NOT NULL
  UNION ALL
  SELECT 'interested_party','interested_party', p.id, p.company_id, p.name, p.next_review_due_at,
    CASE
      WHEN p.next_review_due_at IS NULL THEN NULL
      WHEN p.next_review_due_at < CURRENT_DATE THEN 'overdue'
      WHEN p.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = p.company_id), 30)) THEN 'due_soon'
      ELSE 'up_to_date'
    END,
    p.next_review_due_at - CURRENT_DATE
  FROM public.quality_interested_parties p
  WHERE p.next_review_due_at IS NOT NULL AND p.status = 'ativo'
  UNION ALL
  SELECT 'party_evidence','party_evidence', e.id, p.company_id, (p.name || ' — ') || e.title, e.valid_until,
    CASE
      WHEN e.valid_until < CURRENT_DATE THEN 'overdue'
      WHEN e.valid_until <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = p.company_id), 30)) THEN 'due_soon'
      ELSE 'up_to_date'
    END,
    e.valid_until - CURRENT_DATE
  FROM public.quality_interested_party_evidences e
  JOIN public.quality_interested_parties p ON p.id = e.party_id
  WHERE e.valid_until IS NOT NULL
  UNION ALL
  -- NOVO: riscos com revisão vencida ou próxima
  SELECT 'risk', 'risk_review', r.id, r.company_id,
    'Revisão de risco: ' || r.code || ' — ' || r.title, r.next_review_due_at,
    CASE
      WHEN r.next_review_due_at IS NULL THEN NULL
      WHEN r.next_review_due_at < CURRENT_DATE THEN 'overdue'
      WHEN r.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = r.company_id), 30)) THEN 'due_soon'
      ELSE 'up_to_date'
    END,
    r.next_review_due_at - CURRENT_DATE
  FROM public.quality_risks r
  WHERE r.next_review_due_at IS NOT NULL AND r.status NOT IN ('closed','accepted')
  UNION ALL
  -- NOVO: tratamento de risco atrasado
  SELECT 'risk', 'risk_treatment', r.id, r.company_id,
    'Tratamento atrasado: ' || r.code || ' — ' || r.title, r.treatment_due_date,
    CASE
      WHEN r.treatment_due_date IS NULL THEN NULL
      WHEN r.treatment_due_date < CURRENT_DATE THEN 'overdue'
      WHEN r.treatment_due_date <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = r.company_id), 30)) THEN 'due_soon'
      ELSE 'up_to_date'
    END,
    r.treatment_due_date - CURRENT_DATE
  FROM public.quality_risks r
  WHERE r.treatment_due_date IS NOT NULL AND r.status IN ('analyzing','treating')
) u;

GRANT SELECT ON public.quality_alerts_v TO authenticated;

-- ============ ESTENDER quality_improvements_v ============
CREATE OR REPLACE VIEW public.quality_improvements_v AS
SELECT n.id, n.company_id, 'ncr'::text AS source,
  'NCR-' || lpad(n.ncr_number::text, 4, '0') AS source_label,
  n.title, n.description,
  CASE n.severity WHEN 'high' THEN 'high' WHEN 'low' THEN 'low' ELSE 'medium' END AS priority,
  CASE WHEN n.status IN ('closed','cancelled') THEN 'done' ELSE 'open' END AS status,
  n.created_at AS opened_at, n.deadline::date AS due_date, n.responsible_id AS owner_user_id,
  (SELECT ap.id FROM public.quality_action_plans ap WHERE ap.ncr_id = n.id ORDER BY ap.created_at LIMIT 1) AS action_plan_id,
  '/quality/ncrs'::text AS source_url
FROM public.quality_ncrs n
WHERE n.status NOT IN ('closed','cancelled')
UNION ALL
SELECT f.id, a.company_id, 'audit_finding',
  'Auditoria #' || a.audit_number,
  COALESCE(left(f.description,80),'Achado de auditoria'), f.description,
  CASE f.finding_type WHEN 'major_nc' THEN 'high' WHEN 'minor_nc' THEN 'medium' WHEN 'observation' THEN 'low' WHEN 'opportunity' THEN 'low' ELSE 'medium' END,
  CASE WHEN f.status IN ('closed','verified') THEN 'done' WHEN f.status = 'in_progress' THEN 'in_progress' ELSE 'open' END,
  f.created_at, f.deadline, f.responsible_id, f.action_plan_id, '/quality/audits'
FROM public.quality_audit_findings f JOIN public.quality_audits a ON a.id = f.audit_id
WHERE COALESCE(f.status,'open') NOT IN ('closed','verified','cancelled')
UNION ALL
SELECT o.id, r.company_id, 'review_output',
  'Análise Crítica — ' || to_char(r.review_date::timestamptz, 'DD/MM/YYYY'),
  COALESCE(left(o.description,80),'Saída de análise crítica'), o.description,
  'medium',
  CASE WHEN o.status::text IN ('closed','done','completed') THEN 'done' WHEN o.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
  o.created_at, o.due_date, o.responsible_user_id, o.linked_action_plan_id, '/quality/management-review/' || r.id
FROM public.quality_management_review_outputs o JOIN public.quality_management_reviews r ON r.id = o.review_id
WHERE o.status::text NOT IN ('closed','done','completed','cancelled')
UNION ALL
SELECT c.id, c.company_id, 'complaint',
  'Reclamação #' || lpad(c.complaint_number::text, 4, '0'),
  COALESCE(c.title, left(c.description,80)), c.description, 'high',
  CASE WHEN c.status::text IN ('resolved','closed','cancelled') THEN 'done' WHEN c.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
  c.received_at, NULL::date, c.responsible_id,
  (SELECT ap.id FROM public.quality_action_plans ap WHERE ap.ncr_id = c.linked_ncr_id ORDER BY ap.created_at LIMIT 1),
  '/quality/complaints/' || c.id
FROM public.quality_complaints c
WHERE c.status::text NOT IN ('resolved','closed','cancelled')
UNION ALL
SELECT m.id, m.company_id, 'manual', COALESCE(m.category,'Melhoria manual'),
  m.title, m.description, m.priority, m.status, m.created_at, m.due_date,
  m.responsible_id, m.action_plan_id, '/quality/improvements'
FROM public.quality_improvements_manual m
WHERE m.status NOT IN ('done','cancelled')
UNION ALL
-- NOVO: riscos críticos/altos sem tratamento entram em melhorias
SELECT r.id, r.company_id, 'risk'::text,
  'Risco ' || r.code,
  r.title, r.description,
  CASE r.severity WHEN 'critical' THEN 'high' WHEN 'high' THEN 'high' WHEN 'medium' THEN 'medium' ELSE 'low' END,
  'open'::text,
  r.created_at, r.treatment_due_date, r.owner_user_id,
  NULL::uuid, '/quality/risks'
FROM public.quality_risks r
WHERE r.status NOT IN ('closed','accepted')
  AND r.severity IN ('high','critical')
  AND r.treatment IS NULL;

GRANT SELECT ON public.quality_improvements_v TO authenticated;

-- ============ PARTE B1: PRÉ-REQUISITOS DOC × CURSO ============
CREATE TABLE IF NOT EXISTS public.quality_document_required_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  document_id uuid NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  course_id uuid REFERENCES public.university_courses(id) ON DELETE CASCADE,
  trail_id uuid REFERENCES public.university_trails(id) ON DELETE CASCADE,
  is_mandatory boolean NOT NULL DEFAULT true,
  notes text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((course_id IS NOT NULL) <> (trail_id IS NOT NULL))
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_qdrc_course ON public.quality_document_required_courses(company_id, document_id, course_id) WHERE course_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_qdrc_trail ON public.quality_document_required_courses(company_id, document_id, trail_id) WHERE trail_id IS NOT NULL;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_document_required_courses TO authenticated;
GRANT ALL ON public.quality_document_required_courses TO service_role;
ALTER TABLE public.quality_document_required_courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY qdrc_select ON public.quality_document_required_courses FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY qdrc_master_all ON public.quality_document_required_courses FOR ALL TO authenticated
  USING (company_id = public.user_company_id(auth.uid()) AND public.quality_is_master(auth.uid()))
  WITH CHECK (company_id = public.user_company_id(auth.uid()) AND public.quality_is_master(auth.uid()));

-- Função: lista pré-requisitos faltantes
CREATE OR REPLACE FUNCTION public.quality_user_missing_prerequisites(p_user_id uuid, p_document_id uuid)
RETURNS TABLE (
  required_id uuid,
  kind text,
  ref_id uuid,
  label text
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  -- cursos não concluídos
  SELECT q.id, 'course'::text, q.course_id, c.title
  FROM public.quality_document_required_courses q
  JOIN public.university_courses c ON c.id = q.course_id
  WHERE q.document_id = p_document_id
    AND q.is_mandatory = true
    AND q.course_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM public.university_enrollments e
      WHERE e.user_id = p_user_id AND e.course_id = q.course_id AND e.status = 'completed'
    )
  UNION ALL
  -- trilhas com ao menos um curso pendente
  SELECT q.id, 'trail'::text, q.trail_id, t.title
  FROM public.quality_document_required_courses q
  JOIN public.university_trails t ON t.id = q.trail_id
  WHERE q.document_id = p_document_id
    AND q.is_mandatory = true
    AND q.trail_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.university_trail_courses tc
      WHERE tc.trail_id = q.trail_id
        AND NOT EXISTS (
          SELECT 1 FROM public.university_enrollments e
          WHERE e.user_id = p_user_id AND e.course_id = tc.course_id AND e.status = 'completed'
        )
    );
$$;

CREATE OR REPLACE FUNCTION public.quality_user_has_completed_prerequisites(p_user_id uuid, p_document_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT NOT EXISTS (SELECT 1 FROM public.quality_user_missing_prerequisites(p_user_id, p_document_id));
$$;

-- Atualizar quality_register_acknowledgement com gate de pré-requisito
CREATE OR REPLACE FUNCTION public.quality_register_acknowledgement(p_assignment_id uuid, p_ip text DEFAULT NULL, p_user_agent text DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_assignment public.quality_document_acknowledgement_assignments%ROWTYPE;
  v_doc public.quality_documents%ROWTYPE;
  v_signature public.quality_signatures%ROWTYPE;
  v_event_id uuid;
  v_full_name text;
  v_role_label text;
  v_signature_path text := NULL;
  v_pending_remaining int;
  v_master_id uuid;
  v_missing text;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;

  SELECT * INTO v_assignment FROM public.quality_document_acknowledgement_assignments WHERE id = p_assignment_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'assignment_not_found'; END IF;
  IF v_assignment.user_id <> v_uid THEN RAISE EXCEPTION 'forbidden_not_assignee'; END IF;
  IF v_assignment.status = 'acknowledged' THEN RETURN v_assignment.signature_event_id; END IF;
  IF v_assignment.status = 'cancelled' THEN RAISE EXCEPTION 'assignment_cancelled'; END IF;

  SELECT * INTO v_doc FROM public.quality_documents WHERE id = v_assignment.document_id;

  -- NOVO: gate de pré-requisitos de treinamento
  SELECT string_agg(label, '; ') INTO v_missing
    FROM public.quality_user_missing_prerequisites(v_uid, v_assignment.document_id);
  IF v_missing IS NOT NULL AND v_missing <> '' THEN
    RAISE EXCEPTION 'PREREQUISITES_MISSING: %', v_missing;
  END IF;

  IF v_doc.requires_strong_acknowledgement THEN
    SELECT * INTO v_signature FROM public.quality_signatures
     WHERE user_id = v_uid AND is_active = true ORDER BY created_at DESC LIMIT 1;
    IF NOT FOUND THEN RAISE EXCEPTION 'signature_required_but_missing'; END IF;
    v_signature_path := v_signature.signature_image_path;
  END IF;

  SELECT full_name INTO v_full_name FROM public.profiles WHERE id = v_uid;
  SELECT string_agg(role::text, ',') INTO v_role_label FROM public.user_roles WHERE user_id = v_uid;

  INSERT INTO public.quality_signature_events (
    document_id, version_id, user_id, action,
    signature_image_path, full_name_snapshot, role_snapshot,
    signed_at, ip_address, user_agent, notes
  ) VALUES (
    v_assignment.document_id, v_assignment.version_id, v_uid, 'acknowledgment',
    v_signature_path, v_full_name, v_role_label,
    now(), p_ip, p_user_agent,
    CASE WHEN v_doc.requires_strong_acknowledgement
         THEN 'Ciência registrada com assinatura eletrônica'
         ELSE 'Ciência registrada (Li e estou ciente)' END
  ) RETURNING id INTO v_event_id;

  UPDATE public.quality_document_acknowledgement_assignments
     SET status = 'acknowledged', acknowledged_at = now(), signature_event_id = v_event_id, updated_at = now()
   WHERE id = p_assignment_id;

  SELECT count(*) INTO v_pending_remaining
    FROM public.quality_document_acknowledgement_assignments
   WHERE document_id = v_assignment.document_id AND version_id = v_assignment.version_id AND status = 'pending';

  IF v_pending_remaining = 0 THEN
    FOR v_master_id IN
      SELECT DISTINCT assigned_by FROM public.quality_document_acknowledgement_assignments
       WHERE document_id = v_assignment.document_id AND version_id = v_assignment.version_id AND assigned_by IS NOT NULL
    LOOP
      INSERT INTO public.notifications (user_id, title, message, type, link, metadata)
      VALUES (v_master_id, 'Conscientização 100% concluída',
              coalesce(v_doc.code,'') || ' — ' || coalesce(v_doc.title,'') || ' — todos os destinatários deram ciência',
              'quality_acknowledgement_complete',
              '/quality/documents/' || v_doc.id,
              jsonb_build_object('document_id', v_doc.id, 'version_id', v_assignment.version_id));
    END LOOP;
  END IF;

  RETURN v_event_id;
END;
$function$;

-- ============ PARTE B2: TAG SGQ NO FEED ============
ALTER TABLE public.corp_feed_posts
  ADD COLUMN IF NOT EXISTS sgq_tag boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS quality_document_id uuid REFERENCES public.quality_documents(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_corp_feed_posts_sgq ON public.corp_feed_posts(company_id, sgq_tag) WHERE sgq_tag = true;

ALTER TABLE public.quality_documents
  ADD COLUMN IF NOT EXISTS notify_on_publish boolean NOT NULL DEFAULT false;

-- Permitir Master (qualidade) também inserir posts SGQ (mantém política antiga, adiciona uma extra)
DROP POLICY IF EXISTS cfp_insert_sgq_master ON public.corp_feed_posts;
CREATE POLICY cfp_insert_sgq_master ON public.corp_feed_posts FOR INSERT TO authenticated
  WITH CHECK (company_id = public.user_company_id(auth.uid())
              AND author_id = auth.uid()
              AND public.quality_is_master(auth.uid()));

-- Trigger automático: novo post SGQ quando version published e doc.notify_on_publish = true
CREATE OR REPLACE FUNCTION public.corp_feed_post_from_quality()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_doc public.quality_documents%ROWTYPE;
  v_author uuid;
BEGIN
  -- só dispara em publicação (status passou para 'published' nesta versão atual)
  IF NEW.status IS DISTINCT FROM 'published' THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' AND OLD.status = 'published' THEN RETURN NEW; END IF;

  SELECT * INTO v_doc FROM public.quality_documents WHERE id = NEW.document_id;
  IF v_doc.notify_on_publish IS NOT TRUE THEN RETURN NEW; END IF;

  v_author := COALESCE(NEW.created_by, v_doc.created_by);
  IF v_author IS NULL THEN RETURN NEW; END IF;

  INSERT INTO public.corp_feed_posts (company_id, author_id, title, content, post_type, sgq_tag, quality_document_id)
  VALUES (
    v_doc.company_id, v_author,
    'SGQ — ' || coalesce(v_doc.code,'') || ' ' || coalesce(v_doc.title,''),
    'Nova versão publicada do documento controlado ' || coalesce(v_doc.code,'') || ' — ' || coalesce(v_doc.title,'') || '. Acesse e dê ciência se aplicável.',
    'announcement', true, v_doc.id
  );
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_corp_feed_post_from_quality ON public.quality_document_versions;
CREATE TRIGGER trg_corp_feed_post_from_quality
  AFTER INSERT OR UPDATE OF status ON public.quality_document_versions
  FOR EACH ROW EXECUTE FUNCTION public.corp_feed_post_from_quality();
