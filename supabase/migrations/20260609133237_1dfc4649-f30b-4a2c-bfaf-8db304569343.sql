
-- ============================================================
-- Sprint Fechamento: P0.3 + P1.1 + P1.3 + P2.1 + P3.1
-- ============================================================

-- P0.3: Eficácia em Mudanças Planejadas
ALTER TABLE public.quality_planned_changes
  ADD COLUMN IF NOT EXISTS effectiveness_status text
    CHECK (effectiveness_status IN ('pendente','eficaz','parcial','nao_eficaz'))
    DEFAULT 'pendente',
  ADD COLUMN IF NOT EXISTS effectiveness_reviewed_at timestamptz,
  ADD COLUMN IF NOT EXISTS effectiveness_reviewed_by uuid,
  ADD COLUMN IF NOT EXISTS effectiveness_notes text,
  ADD COLUMN IF NOT EXISTS resources_assessment text;

-- ============================================================
-- P2.1: Histórico de tratativas de Partes Interessadas
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quality_party_treatments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id uuid NOT NULL REFERENCES public.quality_interested_parties(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('pendente','em_andamento','atendida','nao_aplicavel')),
  notes text,
  decided_by uuid,
  decided_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_party_treatments TO authenticated;
GRANT ALL ON public.quality_party_treatments TO service_role;
ALTER TABLE public.quality_party_treatments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Party treatments scoped by company"
  ON public.quality_party_treatments FOR ALL
  USING (EXISTS (SELECT 1 FROM public.quality_interested_parties p
                  JOIN public.profiles pr ON pr.company_id = p.company_id
                  WHERE p.id = quality_party_treatments.party_id AND pr.id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.quality_interested_parties p
                       JOIN public.profiles pr ON pr.company_id = p.company_id
                       WHERE p.id = quality_party_treatments.party_id AND pr.id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_qpt_party ON public.quality_party_treatments(party_id, decided_at DESC);

-- Trigger: capturar histórico ao mudar treatment_status
CREATE OR REPLACE FUNCTION public.quality_log_party_treatment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (TG_OP = 'UPDATE' AND COALESCE(NEW.treatment_status,'') <> COALESCE(OLD.treatment_status,''))
     OR (TG_OP = 'INSERT' AND NEW.treatment_status IS NOT NULL) THEN
    INSERT INTO public.quality_party_treatments (party_id, status, decided_by, decided_at)
    VALUES (NEW.id, NEW.treatment_status, auth.uid(), now());
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_quality_log_party_treatment ON public.quality_interested_parties;
CREATE TRIGGER trg_quality_log_party_treatment
  AFTER INSERT OR UPDATE OF treatment_status ON public.quality_interested_parties
  FOR EACH ROW EXECUTE FUNCTION public.quality_log_party_treatment();

-- ============================================================
-- P3.1: N:N Objetivo ↔ Risco / Parte
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quality_objective_risks (
  objective_id uuid NOT NULL REFERENCES public.quality_objectives(id) ON DELETE CASCADE,
  risk_id uuid NOT NULL REFERENCES public.quality_risks(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  PRIMARY KEY (objective_id, risk_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_objective_risks TO authenticated;
GRANT ALL ON public.quality_objective_risks TO service_role;
ALTER TABLE public.quality_objective_risks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Objective-risk scoped by company"
  ON public.quality_objective_risks FOR ALL
  USING (EXISTS (SELECT 1 FROM public.quality_objectives o
                  JOIN public.profiles pr ON pr.company_id = o.company_id
                  WHERE o.id = quality_objective_risks.objective_id AND pr.id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.quality_objectives o
                       JOIN public.profiles pr ON pr.company_id = o.company_id
                       WHERE o.id = quality_objective_risks.objective_id AND pr.id = auth.uid()));
CREATE INDEX IF NOT EXISTS idx_qor_risk ON public.quality_objective_risks(risk_id);

CREATE TABLE IF NOT EXISTS public.quality_objective_parties (
  objective_id uuid NOT NULL REFERENCES public.quality_objectives(id) ON DELETE CASCADE,
  party_id uuid NOT NULL REFERENCES public.quality_interested_parties(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  PRIMARY KEY (objective_id, party_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_objective_parties TO authenticated;
GRANT ALL ON public.quality_objective_parties TO service_role;
ALTER TABLE public.quality_objective_parties ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Objective-party scoped by company"
  ON public.quality_objective_parties FOR ALL
  USING (EXISTS (SELECT 1 FROM public.quality_objectives o
                  JOIN public.profiles pr ON pr.company_id = o.company_id
                  WHERE o.id = quality_objective_parties.objective_id AND pr.id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.quality_objectives o
                       JOIN public.profiles pr ON pr.company_id = o.company_id
                       WHERE o.id = quality_objective_parties.objective_id AND pr.id = auth.uid()));
CREATE INDEX IF NOT EXISTS idx_qop_party ON public.quality_objective_parties(party_id);

-- ============================================================
-- P1.1: Triggers de origem automática para Melhorias
-- ============================================================
CREATE OR REPLACE FUNCTION public.quality_improvement_from_supplier_incident()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  sup_name text;
BEGIN
  SELECT name INTO sup_name FROM public.quality_suppliers WHERE id = NEW.supplier_id;
  INSERT INTO public.quality_improvements_manual
    (company_id, title, description, category, priority, status, submitted_by, origin_type, origin_id)
  VALUES
    (NEW.company_id,
     'Incidente fornecedor: ' || COALESCE(sup_name,'(sem nome)'),
     NEW.description,
     'supplier_incident',
     CASE WHEN NEW.severity IN ('high','critical') THEN 'high' ELSE 'medium' END,
     'open',
     COALESCE(NEW.reported_by, auth.uid()),
     'supplier_incident',
     NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_qimp_from_supplier_incident ON public.quality_supplier_incidents;
CREATE TRIGGER trg_qimp_from_supplier_incident
  AFTER INSERT ON public.quality_supplier_incidents
  FOR EACH ROW EXECUTE FUNCTION public.quality_improvement_from_supplier_incident();

CREATE OR REPLACE FUNCTION public.quality_improvement_from_calibration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  dev_code text;
  dev_name text;
BEGIN
  IF NEW.result::text <> 'reproved' THEN
    RETURN NEW;
  END IF;
  SELECT code, name INTO dev_code, dev_name FROM public.quality_measuring_devices WHERE id = NEW.device_id;
  INSERT INTO public.quality_improvements_manual
    (company_id, title, description, category, priority, status, submitted_by, origin_type, origin_id)
  VALUES
    (NEW.company_id,
     'Calibração reprovada: ' || COALESCE(dev_code,'?') || ' — ' || COALESCE(dev_name,''),
     COALESCE(NEW.notes,'Calibração reprovada'),
     'device_failure',
     'high',
     'open',
     COALESCE(NEW.performed_by_user_id, auth.uid()),
     'device_failure',
     NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_qimp_from_calibration ON public.quality_calibrations;
CREATE TRIGGER trg_qimp_from_calibration
  AFTER INSERT ON public.quality_calibrations
  FOR EACH ROW EXECUTE FUNCTION public.quality_improvement_from_calibration();

-- ============================================================
-- P1.3: View consolidada com effectiveness_status via action_plan
-- ============================================================
DROP VIEW IF EXISTS public.quality_improvements_v;
CREATE VIEW public.quality_improvements_v AS
SELECT n.id, n.company_id, 'ncr'::text AS source,
  ('NCR-' || lpad(n.ncr_number::text, 4, '0')) AS source_label,
  n.title, n.description,
  CASE n.severity WHEN 'high' THEN 'high' WHEN 'low' THEN 'low' ELSE 'medium' END AS priority,
  CASE WHEN n.status IN ('closed','cancelled') THEN 'done' ELSE 'open' END AS status,
  n.created_at AS opened_at,
  n.deadline::date AS due_date,
  n.responsible_id AS owner_user_id,
  ap.id AS action_plan_id,
  '/quality/ncrs' AS source_url,
  CASE
    WHEN ap.effectiveness_verified IS TRUE THEN 'eficaz'
    WHEN ap.status = 'ineffective' THEN 'ineficaz'
    WHEN ap.id IS NOT NULL THEN 'pendente'
    ELSE NULL
  END AS effectiveness_status
FROM public.quality_ncrs n
LEFT JOIN LATERAL (
  SELECT id, effectiveness_verified, status FROM public.quality_action_plans
  WHERE ncr_id = n.id ORDER BY created_at LIMIT 1
) ap ON true
WHERE n.status NOT IN ('closed','cancelled')

UNION ALL
SELECT f.id, a.company_id, 'audit_finding',
  ('Auditoria #' || a.audit_number),
  COALESCE(left(f.description,80),'Achado de auditoria'),
  f.description,
  CASE f.finding_type WHEN 'major_nc' THEN 'high' WHEN 'minor_nc' THEN 'medium' ELSE 'low' END,
  CASE WHEN f.status IN ('closed','verified') THEN 'done'
       WHEN f.status = 'in_progress' THEN 'in_progress' ELSE 'open' END,
  f.created_at, f.deadline, f.responsible_id, f.action_plan_id,
  '/quality/audits',
  CASE
    WHEN ap.effectiveness_verified IS TRUE THEN 'eficaz'
    WHEN ap.status = 'ineffective' THEN 'ineficaz'
    WHEN ap.id IS NOT NULL THEN 'pendente'
    ELSE NULL
  END
FROM public.quality_audit_findings f
JOIN public.quality_audits a ON a.id = f.audit_id
LEFT JOIN public.quality_action_plans ap ON ap.id = f.action_plan_id
WHERE COALESCE(f.status,'open') NOT IN ('closed','verified','cancelled')

UNION ALL
SELECT o.id, r.company_id, 'review_output',
  ('Análise Crítica — ' || to_char(r.review_date::timestamptz,'DD/MM/YYYY')),
  COALESCE(left(o.description,80),'Saída de análise crítica'),
  o.description, 'medium',
  CASE WHEN o.status::text IN ('closed','done','completed') THEN 'done'
       WHEN o.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
  o.created_at, o.due_date, o.responsible_user_id, o.linked_action_plan_id,
  ('/quality/management-review/' || r.id),
  CASE
    WHEN ap.effectiveness_verified IS TRUE THEN 'eficaz'
    WHEN ap.status = 'ineffective' THEN 'ineficaz'
    WHEN ap.id IS NOT NULL THEN 'pendente'
    ELSE NULL
  END
FROM public.quality_management_review_outputs o
JOIN public.quality_management_reviews r ON r.id = o.review_id
LEFT JOIN public.quality_action_plans ap ON ap.id = o.linked_action_plan_id
WHERE o.status::text NOT IN ('closed','done','completed','cancelled')

UNION ALL
SELECT c.id, c.company_id, 'complaint',
  ('Reclamação #' || lpad(c.complaint_number::text,4,'0')),
  COALESCE(c.title, left(c.description,80)), c.description, 'high',
  CASE WHEN c.status::text IN ('resolved','closed','cancelled') THEN 'done'
       WHEN c.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
  c.received_at, NULL::date, c.responsible_id, ap.id,
  ('/quality/complaints/' || c.id),
  CASE
    WHEN ap.effectiveness_verified IS TRUE THEN 'eficaz'
    WHEN ap.status = 'ineffective' THEN 'ineficaz'
    WHEN ap.id IS NOT NULL THEN 'pendente'
    ELSE NULL
  END
FROM public.quality_complaints c
LEFT JOIN LATERAL (
  SELECT id, effectiveness_verified, status FROM public.quality_action_plans
  WHERE ncr_id = c.linked_ncr_id ORDER BY created_at LIMIT 1
) ap ON true
WHERE c.status::text NOT IN ('resolved','closed','cancelled')

UNION ALL
SELECT m.id, m.company_id, 'manual', COALESCE(m.category,'Melhoria manual'),
  m.title, m.description, m.priority, m.status,
  m.created_at, m.due_date, m.responsible_id, m.action_plan_id,
  '/quality/improvements', m.effectiveness_status
FROM public.quality_improvements_manual m
WHERE m.status NOT IN ('done','cancelled')

UNION ALL
SELECT r.id, r.company_id, 'risk', ('Risco ' || r.code), r.title, r.description,
  CASE r.severity WHEN 'critical' THEN 'high' WHEN 'high' THEN 'high'
       WHEN 'medium' THEN 'medium' ELSE 'low' END,
  'open', r.created_at, r.treatment_due_date, r.owner_user_id, NULL::uuid,
  '/quality/risks', NULL::text
FROM public.quality_risks r
WHERE r.status NOT IN ('closed'::quality_risk_status,'accepted'::quality_risk_status)
  AND r.severity IN ('high','critical') AND r.treatment IS NULL

UNION ALL
SELECT sup.id, sup.company_id, 'supplier', ('Fornecedor ' || sup.status::text),
  sup.name, COALESCE(sup.notes, sup.scope_description),
  CASE WHEN sup.status = 'disqualified'::quality_supplier_status THEN 'high' ELSE 'medium' END,
  'open', sup.updated_at, sup.next_evaluation_due, sup.owner_user_id, NULL::uuid,
  ('/quality/suppliers/' || sup.id), NULL::text
FROM public.quality_suppliers sup
WHERE sup.status IN ('suspended'::quality_supplier_status,'disqualified'::quality_supplier_status)

UNION ALL
SELECT d.id, d.company_id, 'device', ('Instrumento ' || d.status::text),
  (d.code || ' — ' || d.name), COALESCE(d.notes, d.description),
  CASE WHEN d.status = 'out_of_service'::quality_device_status THEN 'high' ELSE 'medium' END,
  'open', d.updated_at, d.next_calibration_due, d.responsible_user_id, NULL::uuid,
  ('/quality/devices/' || d.id), NULL::text
FROM public.quality_measuring_devices d
WHERE d.status IN ('out_of_service'::quality_device_status,'retired'::quality_device_status);

GRANT SELECT ON public.quality_improvements_v TO authenticated;
GRANT ALL ON public.quality_improvements_v TO service_role;
