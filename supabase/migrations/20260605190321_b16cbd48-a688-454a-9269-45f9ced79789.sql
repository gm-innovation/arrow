
-- =========== ENUMS ===========
DO $$ BEGIN
  CREATE TYPE public.quality_supplier_category AS ENUM ('material','service','calibration','training','software','logistics','other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.quality_supplier_status AS ENUM ('pending','approved','conditional','suspended','disqualified');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.quality_supplier_evaluation_kind AS ENUM ('initial','periodic','incident','requalification');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.quality_supplier_criticality AS ENUM ('low','medium','high','critical');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =========== TABLE: quality_suppliers ===========
CREATE TABLE IF NOT EXISTS public.quality_suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  tax_id text,
  category public.quality_supplier_category NOT NULL DEFAULT 'material',
  criticality public.quality_supplier_criticality NOT NULL DEFAULT 'medium',
  status public.quality_supplier_status NOT NULL DEFAULT 'pending',
  contact_name text,
  contact_email text,
  contact_phone text,
  scope_description text,
  notes text,
  requalification_frequency_months int NOT NULL DEFAULT 12,
  last_evaluation_at date,
  next_evaluation_due date,
  current_score numeric(5,2),
  current_grade text,
  owner_user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS quality_suppliers_company_tax_unique
  ON public.quality_suppliers (company_id, tax_id) WHERE tax_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_quality_suppliers_company ON public.quality_suppliers(company_id);
CREATE INDEX IF NOT EXISTS idx_quality_suppliers_status ON public.quality_suppliers(company_id, status);
CREATE INDEX IF NOT EXISTS idx_quality_suppliers_owner ON public.quality_suppliers(owner_user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_suppliers TO authenticated;
GRANT ALL ON public.quality_suppliers TO service_role;
ALTER TABLE public.quality_suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "suppliers_select_company" ON public.quality_suppliers
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "suppliers_insert_master_or_owner" ON public.quality_suppliers
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (public.quality_is_master(auth.uid()) OR owner_user_id = auth.uid() OR created_by = auth.uid())
  );

CREATE POLICY "suppliers_update_master_or_owner" ON public.quality_suppliers
  FOR UPDATE TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (public.quality_is_master(auth.uid()) OR owner_user_id = auth.uid())
  );

CREATE POLICY "suppliers_delete_master" ON public.quality_suppliers
  FOR DELETE TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND public.quality_is_master(auth.uid())
  );

-- =========== TABLE: quality_supplier_evaluations ===========
CREATE TABLE IF NOT EXISTS public.quality_supplier_evaluations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  supplier_id uuid NOT NULL REFERENCES public.quality_suppliers(id) ON DELETE CASCADE,
  kind public.quality_supplier_evaluation_kind NOT NULL DEFAULT 'periodic',
  evaluation_date date NOT NULL DEFAULT CURRENT_DATE,
  period_start date,
  period_end date,
  score numeric(5,2),
  grade text,
  status_after public.quality_supplier_status,
  evaluator_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  summary text,
  recommendations text,
  next_due_at date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qse_supplier ON public.quality_supplier_evaluations(supplier_id);
CREATE INDEX IF NOT EXISTS idx_qse_company ON public.quality_supplier_evaluations(company_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_supplier_evaluations TO authenticated;
GRANT ALL ON public.quality_supplier_evaluations TO service_role;
ALTER TABLE public.quality_supplier_evaluations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qse_select_company" ON public.quality_supplier_evaluations
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "qse_write_master_or_owner" ON public.quality_supplier_evaluations
  FOR ALL TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      public.quality_is_master(auth.uid())
      OR EXISTS (SELECT 1 FROM public.quality_suppliers s WHERE s.id = supplier_id AND s.owner_user_id = auth.uid())
    )
  )
  WITH CHECK (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      public.quality_is_master(auth.uid())
      OR EXISTS (SELECT 1 FROM public.quality_suppliers s WHERE s.id = supplier_id AND s.owner_user_id = auth.uid())
    )
  );

-- =========== TABLE: quality_supplier_evaluation_criteria ===========
CREATE TABLE IF NOT EXISTS public.quality_supplier_evaluation_criteria (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  evaluation_id uuid NOT NULL REFERENCES public.quality_supplier_evaluations(id) ON DELETE CASCADE,
  criterion_code text NOT NULL CHECK (criterion_code IN ('quality','delivery','price','support','compliance','safety')),
  weight numeric(5,2) NOT NULL DEFAULT 1,
  score numeric(5,2) NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qsec_eval ON public.quality_supplier_evaluation_criteria(evaluation_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_supplier_evaluation_criteria TO authenticated;
GRANT ALL ON public.quality_supplier_evaluation_criteria TO service_role;
ALTER TABLE public.quality_supplier_evaluation_criteria ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qsec_select_company" ON public.quality_supplier_evaluation_criteria
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "qsec_write_master_or_owner" ON public.quality_supplier_evaluation_criteria
  FOR ALL TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      public.quality_is_master(auth.uid())
      OR EXISTS (
        SELECT 1 FROM public.quality_supplier_evaluations e
        JOIN public.quality_suppliers s ON s.id = e.supplier_id
        WHERE e.id = evaluation_id AND s.owner_user_id = auth.uid()
      )
    )
  )
  WITH CHECK (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- =========== TABLE: quality_supplier_documents ===========
CREATE TABLE IF NOT EXISTS public.quality_supplier_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  supplier_id uuid NOT NULL REFERENCES public.quality_suppliers(id) ON DELETE CASCADE,
  document_type text NOT NULL,
  file_url text NOT NULL,
  file_name text NOT NULL,
  valid_until date,
  uploaded_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qsd_supplier ON public.quality_supplier_documents(supplier_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_supplier_documents TO authenticated;
GRANT ALL ON public.quality_supplier_documents TO service_role;
ALTER TABLE public.quality_supplier_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qsd_select_company" ON public.quality_supplier_documents
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "qsd_write_master_or_owner" ON public.quality_supplier_documents
  FOR ALL TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      public.quality_is_master(auth.uid())
      OR EXISTS (SELECT 1 FROM public.quality_suppliers s WHERE s.id = supplier_id AND s.owner_user_id = auth.uid())
    )
  )
  WITH CHECK (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- =========== TABLE: quality_supplier_incidents ===========
CREATE TABLE IF NOT EXISTS public.quality_supplier_incidents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  supplier_id uuid NOT NULL REFERENCES public.quality_suppliers(id) ON DELETE CASCADE,
  incident_date date NOT NULL DEFAULT CURRENT_DATE,
  severity text NOT NULL DEFAULT 'medium' CHECK (severity IN ('low','medium','high','critical')),
  description text NOT NULL,
  linked_ncr_id uuid REFERENCES public.quality_ncrs(id) ON DELETE SET NULL,
  resolved_at timestamptz,
  resolved_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reported_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qsi_supplier ON public.quality_supplier_incidents(supplier_id);
CREATE INDEX IF NOT EXISTS idx_qsi_open ON public.quality_supplier_incidents(supplier_id) WHERE resolved_at IS NULL;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_supplier_incidents TO authenticated;
GRANT ALL ON public.quality_supplier_incidents TO service_role;
ALTER TABLE public.quality_supplier_incidents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qsi_select_company" ON public.quality_supplier_incidents
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "qsi_insert_any_company" ON public.quality_supplier_incidents
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "qsi_update_master" ON public.quality_supplier_incidents
  FOR UPDATE TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND public.quality_is_master(auth.uid())
  );

CREATE POLICY "qsi_delete_master" ON public.quality_supplier_incidents
  FOR DELETE TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND public.quality_is_master(auth.uid())
  );

-- =========== Integração: purchase_requests.supplier_id ===========
ALTER TABLE public.purchase_requests
  ADD COLUMN IF NOT EXISTS supplier_id uuid REFERENCES public.quality_suppliers(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_purchase_requests_supplier ON public.purchase_requests(supplier_id);

-- =========== FUNÇÕES ===========
CREATE OR REPLACE FUNCTION public.quality_supplier_compute_score(p_evaluation_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_score numeric(5,2);
  v_grade text;
BEGIN
  SELECT CASE WHEN SUM(weight) > 0 THEN ROUND(SUM(score * weight)::numeric / SUM(weight)::numeric, 2) ELSE NULL END
    INTO v_score
  FROM public.quality_supplier_evaluation_criteria
  WHERE evaluation_id = p_evaluation_id;

  v_grade := CASE
    WHEN v_score IS NULL THEN NULL
    WHEN v_score >= 90 THEN 'A'
    WHEN v_score >= 75 THEN 'B'
    WHEN v_score >= 60 THEN 'C'
    ELSE 'D'
  END;

  UPDATE public.quality_supplier_evaluations
     SET score = v_score, grade = v_grade, updated_at = now()
   WHERE id = p_evaluation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.quality_supplier_next_status(p_score numeric, p_open_critical_incidents int)
RETURNS public.quality_supplier_status
LANGUAGE sql IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_score IS NULL THEN 'pending'::public.quality_supplier_status
    WHEN p_open_critical_incidents > 0 THEN 'suspended'::public.quality_supplier_status
    WHEN p_score >= 75 THEN 'approved'::public.quality_supplier_status
    WHEN p_score >= 60 THEN 'conditional'::public.quality_supplier_status
    ELSE 'suspended'::public.quality_supplier_status
  END;
$$;

CREATE OR REPLACE FUNCTION public.quality_supplier_after_evaluation_trigger()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_open_critical int;
  v_status public.quality_supplier_status;
  v_freq int;
BEGIN
  SELECT COUNT(*) INTO v_open_critical
    FROM public.quality_supplier_incidents
   WHERE supplier_id = NEW.supplier_id
     AND severity = 'critical'
     AND resolved_at IS NULL;

  v_status := public.quality_supplier_next_status(NEW.score, v_open_critical);

  IF NEW.status_after IS NULL THEN
    UPDATE public.quality_supplier_evaluations SET status_after = v_status WHERE id = NEW.id;
  END IF;

  SELECT requalification_frequency_months INTO v_freq
    FROM public.quality_suppliers WHERE id = NEW.supplier_id;

  UPDATE public.quality_suppliers
     SET current_score = NEW.score,
         current_grade = NEW.grade,
         status = COALESCE(NEW.status_after, v_status),
         last_evaluation_at = NEW.evaluation_date,
         next_evaluation_due = (NEW.evaluation_date + (COALESCE(v_freq, 12) || ' months')::interval)::date,
         updated_at = now()
   WHERE id = NEW.supplier_id;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.quality_supplier_before_insert()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NEW.next_evaluation_due IS NULL THEN
    NEW.next_evaluation_due := (CURRENT_DATE + interval '6 months')::date;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.quality_supplier_after_criteria_change()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_eval uuid;
BEGIN
  v_eval := COALESCE(NEW.evaluation_id, OLD.evaluation_id);
  PERFORM public.quality_supplier_compute_score(v_eval);
  UPDATE public.quality_supplier_evaluations SET updated_at = now() WHERE id = v_eval;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.quality_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

-- =========== TRIGGERS ===========
DROP TRIGGER IF EXISTS trg_qse_after_change ON public.quality_supplier_evaluations;
CREATE TRIGGER trg_qse_after_change
AFTER INSERT OR UPDATE ON public.quality_supplier_evaluations
FOR EACH ROW EXECUTE FUNCTION public.quality_supplier_after_evaluation_trigger();

DROP TRIGGER IF EXISTS trg_qsuppliers_before_insert ON public.quality_suppliers;
CREATE TRIGGER trg_qsuppliers_before_insert
BEFORE INSERT ON public.quality_suppliers
FOR EACH ROW EXECUTE FUNCTION public.quality_supplier_before_insert();

DROP TRIGGER IF EXISTS trg_qsec_after_change ON public.quality_supplier_evaluation_criteria;
CREATE TRIGGER trg_qsec_after_change
AFTER INSERT OR UPDATE OR DELETE ON public.quality_supplier_evaluation_criteria
FOR EACH ROW EXECUTE FUNCTION public.quality_supplier_after_criteria_change();

DROP TRIGGER IF EXISTS trg_qsuppliers_touch ON public.quality_suppliers;
CREATE TRIGGER trg_qsuppliers_touch BEFORE UPDATE ON public.quality_suppliers
FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

DROP TRIGGER IF EXISTS trg_qse_touch ON public.quality_supplier_evaluations;
CREATE TRIGGER trg_qse_touch BEFORE UPDATE ON public.quality_supplier_evaluations
FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

-- =========== VIEWS (extensão preservando colunas existentes) ===========
DROP VIEW IF EXISTS public.quality_alerts_v CASCADE;
CREATE VIEW public.quality_alerts_v
WITH (security_invoker = true) AS
WITH s AS (
  SELECT quality_settings.company_id,
         COALESCE((quality_settings.review_cycles ->> 'alert_window_days')::integer, 30) AS alert_window_days
    FROM quality_settings
)
SELECT source, category, entity_id, company_id, title, due_date, status, days_remaining FROM (
  -- org_context
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
  SELECT 'risk','risk_review', r.id, r.company_id,
         ('Revisão de risco: ' || r.code) || ' — ' || r.title, r.next_review_due_at,
         CASE
           WHEN r.next_review_due_at IS NULL THEN NULL
           WHEN r.next_review_due_at < CURRENT_DATE THEN 'overdue'
           WHEN r.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = r.company_id), 30)) THEN 'due_soon'
           ELSE 'up_to_date'
         END,
         r.next_review_due_at - CURRENT_DATE
    FROM public.quality_risks r
   WHERE r.next_review_due_at IS NOT NULL
     AND r.status NOT IN ('closed','accepted')
  UNION ALL
  SELECT 'risk','risk_treatment', r.id, r.company_id,
         ('Tratamento atrasado: ' || r.code) || ' — ' || r.title, r.treatment_due_date,
         CASE
           WHEN r.treatment_due_date IS NULL THEN NULL
           WHEN r.treatment_due_date < CURRENT_DATE THEN 'overdue'
           WHEN r.treatment_due_date <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = r.company_id), 30)) THEN 'due_soon'
           ELSE 'up_to_date'
         END,
         r.treatment_due_date - CURRENT_DATE
    FROM public.quality_risks r
   WHERE r.treatment_due_date IS NOT NULL
     AND r.status IN ('analyzing','treating')
  UNION ALL
  -- supplier requalification
  SELECT 'supplier','requalification', sup.id, sup.company_id, sup.name, sup.next_evaluation_due,
         CASE
           WHEN sup.next_evaluation_due IS NULL THEN NULL
           WHEN sup.next_evaluation_due < CURRENT_DATE THEN 'overdue'
           WHEN sup.next_evaluation_due <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = sup.company_id), 30)) THEN 'due_soon'
           ELSE 'up_to_date'
         END,
         sup.next_evaluation_due - CURRENT_DATE
    FROM public.quality_suppliers sup
   WHERE sup.next_evaluation_due IS NOT NULL
     AND sup.status IN ('approved','conditional')
  UNION ALL
  -- supplier pending qualification > 30 days
  SELECT 'supplier','pending_qualification', sup.id, sup.company_id, sup.name,
         (sup.created_at + interval '30 days')::date,
         CASE
           WHEN (sup.created_at + interval '30 days')::date < CURRENT_DATE THEN 'overdue'
           ELSE 'due_soon'
         END,
         ((sup.created_at + interval '30 days')::date - CURRENT_DATE)
    FROM public.quality_suppliers sup
   WHERE sup.status = 'pending'
) u;

GRANT SELECT ON public.quality_alerts_v TO authenticated;

-- quality_improvements_v: re-cria preservando estrutura + nova branch 'supplier'
DROP VIEW IF EXISTS public.quality_improvements_v CASCADE;
CREATE VIEW public.quality_improvements_v
WITH (security_invoker = true) AS
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
       COALESCE(LEFT(f.description, 80), 'Achado de auditoria'),
       f.description,
       CASE f.finding_type WHEN 'major_nc' THEN 'high' WHEN 'minor_nc' THEN 'medium' WHEN 'observation' THEN 'low' WHEN 'opportunity' THEN 'low' ELSE 'medium' END,
       CASE WHEN f.status IN ('closed','verified') THEN 'done' WHEN f.status = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       f.created_at, f.deadline, f.responsible_id, f.action_plan_id,
       '/quality/audits'
  FROM public.quality_audit_findings f
  JOIN public.quality_audits a ON a.id = f.audit_id
 WHERE COALESCE(f.status,'open') NOT IN ('closed','verified','cancelled')
UNION ALL
SELECT o.id, r.company_id, 'review_output',
       'Análise Crítica — ' || to_char(r.review_date::timestamptz, 'DD/MM/YYYY'),
       COALESCE(LEFT(o.description, 80), 'Saída de análise crítica'),
       o.description, 'medium',
       CASE WHEN o.status::text IN ('closed','done','completed') THEN 'done' WHEN o.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       o.created_at, o.due_date, o.responsible_user_id, o.linked_action_plan_id,
       '/quality/management-review/' || r.id
  FROM public.quality_management_review_outputs o
  JOIN public.quality_management_reviews r ON r.id = o.review_id
 WHERE o.status::text NOT IN ('closed','done','completed','cancelled')
UNION ALL
SELECT c.id, c.company_id, 'complaint',
       'Reclamação #' || lpad(c.complaint_number::text, 4, '0'),
       COALESCE(c.title, LEFT(c.description, 80)),
       c.description, 'high',
       CASE WHEN c.status::text IN ('resolved','closed','cancelled') THEN 'done' WHEN c.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       c.received_at, NULL::date, c.responsible_id,
       (SELECT ap.id FROM public.quality_action_plans ap WHERE ap.ncr_id = c.linked_ncr_id ORDER BY ap.created_at LIMIT 1),
       '/quality/complaints/' || c.id
  FROM public.quality_complaints c
 WHERE c.status::text NOT IN ('resolved','closed','cancelled')
UNION ALL
SELECT m.id, m.company_id, 'manual',
       COALESCE(m.category,'Melhoria manual'),
       m.title, m.description, m.priority, m.status,
       m.created_at, m.due_date, m.responsible_id, m.action_plan_id,
       '/quality/improvements'
  FROM public.quality_improvements_manual m
 WHERE m.status NOT IN ('done','cancelled')
UNION ALL
SELECT r.id, r.company_id, 'risk',
       'Risco ' || r.code, r.title, r.description,
       CASE r.severity WHEN 'critical' THEN 'high' WHEN 'high' THEN 'high' WHEN 'medium' THEN 'medium' ELSE 'low' END,
       'open', r.created_at, r.treatment_due_date, r.owner_user_id, NULL::uuid,
       '/quality/risks'
  FROM public.quality_risks r
 WHERE r.status NOT IN ('closed','accepted')
   AND r.severity IN ('high','critical')
   AND r.treatment IS NULL
UNION ALL
-- nova fonte: fornecedores suspensos/desqualificados
SELECT sup.id, sup.company_id, 'supplier',
       'Fornecedor ' || sup.status::text,
       sup.name,
       COALESCE(sup.notes, sup.scope_description),
       CASE WHEN sup.status = 'disqualified' THEN 'high' ELSE 'medium' END,
       'open',
       sup.updated_at, sup.next_evaluation_due, sup.owner_user_id, NULL::uuid,
       '/quality/suppliers/' || sup.id
  FROM public.quality_suppliers sup
 WHERE sup.status IN ('suspended','disqualified');

GRANT SELECT ON public.quality_improvements_v TO authenticated;
