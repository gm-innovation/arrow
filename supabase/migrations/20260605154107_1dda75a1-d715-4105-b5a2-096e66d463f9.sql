
ALTER TABLE public.quality_action_plans
  ADD COLUMN IF NOT EXISTS source text,
  ADD COLUMN IF NOT EXISTS source_id uuid;

CREATE INDEX IF NOT EXISTS idx_quality_action_plans_source
  ON public.quality_action_plans(source, source_id);

CREATE TABLE IF NOT EXISTS public.quality_improvements_manual (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  category text,
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('high','medium','low')),
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','in_progress','done','cancelled')),
  responsible_id uuid,
  due_date date,
  action_plan_id uuid REFERENCES public.quality_action_plans(id) ON DELETE SET NULL,
  submitted_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_qim_company ON public.quality_improvements_manual(company_id);
CREATE INDEX IF NOT EXISTS idx_qim_status ON public.quality_improvements_manual(status);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_improvements_manual TO authenticated;
GRANT ALL ON public.quality_improvements_manual TO service_role;

ALTER TABLE public.quality_improvements_manual ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qim_select_own_or_privileged" ON public.quality_improvements_manual
FOR SELECT TO authenticated
USING (
  submitted_by = auth.uid()
  OR has_role(auth.uid(), 'coordinator'::app_role)
  OR has_role(auth.uid(), 'director'::app_role)
  OR has_role(auth.uid(), 'super_admin'::app_role)
);

CREATE POLICY "qim_insert_self_company" ON public.quality_improvements_manual
FOR INSERT TO authenticated
WITH CHECK (
  submitted_by = auth.uid()
  AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
);

CREATE POLICY "qim_update_privileged" ON public.quality_improvements_manual
FOR UPDATE TO authenticated
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  OR has_role(auth.uid(), 'director'::app_role)
  OR has_role(auth.uid(), 'super_admin'::app_role)
);

CREATE POLICY "qim_delete_privileged" ON public.quality_improvements_manual
FOR DELETE TO authenticated
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  OR has_role(auth.uid(), 'director'::app_role)
  OR has_role(auth.uid(), 'super_admin'::app_role)
);

CREATE TRIGGER trg_qim_updated_at
BEFORE UPDATE ON public.quality_improvements_manual
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE VIEW public.quality_improvements_v AS
-- 13 cols: id, company_id, source, source_label, title, description, priority, status, opened_at, due_date, owner_user_id, action_plan_id, source_url
SELECT
  n.id, n.company_id, 'ncr'::text AS source,
  ('NCR-' || lpad(n.ncr_number::text, 4, '0')) AS source_label,
  n.title, n.description,
  CASE n.severity WHEN 'high' THEN 'high' WHEN 'low' THEN 'low' ELSE 'medium' END AS priority,
  CASE WHEN n.status IN ('closed','cancelled') THEN 'done' ELSE 'open' END AS status,
  n.created_at AS opened_at,
  n.deadline::date AS due_date,
  n.responsible_id AS owner_user_id,
  (SELECT ap.id FROM public.quality_action_plans ap WHERE ap.ncr_id = n.id ORDER BY ap.created_at LIMIT 1) AS action_plan_id,
  '/quality/ncrs'::text AS source_url
FROM public.quality_ncrs n
WHERE n.status NOT IN ('closed','cancelled')
UNION ALL
SELECT
  f.id, a.company_id, 'audit_finding'::text,
  ('Auditoria #' || a.audit_number),
  coalesce(left(f.description, 80), 'Achado de auditoria') AS title,
  f.description,
  CASE f.finding_type
    WHEN 'major_nc' THEN 'high'
    WHEN 'minor_nc' THEN 'medium'
    WHEN 'observation' THEN 'low'
    WHEN 'opportunity' THEN 'low'
    ELSE 'medium' END,
  CASE WHEN f.status IN ('closed','verified') THEN 'done'
       WHEN f.status = 'in_progress' THEN 'in_progress'
       ELSE 'open' END,
  f.created_at, f.deadline, f.responsible_id, f.action_plan_id,
  '/quality/audits'::text
FROM public.quality_audit_findings f
JOIN public.quality_audits a ON a.id = f.audit_id
WHERE coalesce(f.status,'open') NOT IN ('closed','verified','cancelled')
UNION ALL
SELECT
  o.id, r.company_id, 'review_output'::text,
  ('Análise Crítica — ' || to_char(r.review_date, 'DD/MM/YYYY')),
  coalesce(left(o.description, 80), 'Saída de análise crítica') AS title,
  o.description,
  'medium'::text,
  CASE WHEN o.status::text IN ('closed','done','completed') THEN 'done'
       WHEN o.status::text = 'in_progress' THEN 'in_progress'
       ELSE 'open' END,
  o.created_at, o.due_date, o.responsible_user_id, o.linked_action_plan_id,
  ('/quality/management-review/' || r.id::text)
FROM public.quality_management_review_outputs o
JOIN public.quality_management_reviews r ON r.id = o.review_id
WHERE o.status::text NOT IN ('closed','done','completed','cancelled')
UNION ALL
SELECT
  c.id, c.company_id, 'complaint'::text,
  ('Reclamação #' || lpad(c.complaint_number::text, 4, '0')),
  coalesce(c.title, left(c.description, 80)) AS title,
  c.description,
  'high'::text,
  CASE WHEN c.status::text IN ('resolved','closed','cancelled') THEN 'done'
       WHEN c.status::text = 'in_progress' THEN 'in_progress'
       ELSE 'open' END,
  c.received_at, NULL::date, c.responsible_id,
  (SELECT ap.id FROM public.quality_action_plans ap WHERE ap.ncr_id = c.linked_ncr_id ORDER BY ap.created_at LIMIT 1),
  ('/quality/complaints/' || c.id::text)
FROM public.quality_complaints c
WHERE c.status::text NOT IN ('resolved','closed','cancelled')
UNION ALL
SELECT
  m.id, m.company_id, 'manual'::text,
  coalesce(m.category, 'Melhoria manual'),
  m.title, m.description, m.priority, m.status,
  m.created_at, m.due_date, m.responsible_id, m.action_plan_id,
  '/quality/improvements'::text
FROM public.quality_improvements_manual m
WHERE m.status NOT IN ('done','cancelled');

GRANT SELECT ON public.quality_improvements_v TO authenticated;
GRANT SELECT ON public.quality_improvements_v TO service_role;
