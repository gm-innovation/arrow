CREATE OR REPLACE VIEW public.quality_improvements_v AS
SELECT n.id, n.company_id, 'ncr'::text AS source,
       'NCR-'::text || lpad(n.ncr_number::text, 4, '0') AS source_label,
       n.title, n.description,
       CASE n.severity WHEN 'high' THEN 'high' WHEN 'low' THEN 'low' ELSE 'medium' END AS priority,
       CASE WHEN n.status = ANY (ARRAY['closed','cancelled']) THEN 'done' ELSE 'open' END AS status,
       n.created_at AS opened_at, n.deadline::date AS due_date,
       n.responsible_id AS owner_user_id,
       (SELECT ap.id FROM quality_action_plans ap WHERE ap.ncr_id = n.id ORDER BY ap.created_at LIMIT 1) AS action_plan_id,
       '/quality/ncrs'::text AS source_url,
       NULL::text AS effectiveness_status
  FROM quality_ncrs n
 WHERE n.status <> ALL (ARRAY['closed','cancelled'])
UNION ALL
SELECT f.id, a.company_id, 'audit_finding',
       'Auditoria #'::text || a.audit_number,
       COALESCE(left(f.description, 80), 'Achado de auditoria'),
       f.description,
       CASE f.finding_type WHEN 'major_nc' THEN 'high' WHEN 'minor_nc' THEN 'medium' WHEN 'observation' THEN 'low' WHEN 'opportunity' THEN 'low' ELSE 'medium' END,
       CASE WHEN f.status = ANY (ARRAY['closed','verified']) THEN 'done' WHEN f.status = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       f.created_at, f.deadline, f.responsible_id, f.action_plan_id,
       '/quality/audits'::text,
       NULL::text
  FROM quality_audit_findings f
  JOIN quality_audits a ON a.id = f.audit_id
 WHERE COALESCE(f.status, 'open') <> ALL (ARRAY['closed','verified','cancelled'])
UNION ALL
SELECT o.id, r.company_id, 'review_output',
       'Análise Crítica — '::text || to_char(r.review_date::timestamptz, 'DD/MM/YYYY'),
       COALESCE(left(o.description, 80), 'Saída de análise crítica'),
       o.description, 'medium',
       CASE WHEN o.status::text = ANY (ARRAY['closed','done','completed']) THEN 'done' WHEN o.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       o.created_at, o.due_date, o.responsible_user_id, o.linked_action_plan_id,
       '/quality/management-review/'::text || r.id,
       NULL::text
  FROM quality_management_review_outputs o
  JOIN quality_management_reviews r ON r.id = o.review_id
 WHERE o.status::text <> ALL (ARRAY['closed','done','completed','cancelled'])
UNION ALL
SELECT c.id, c.company_id, 'complaint',
       'Reclamação #'::text || lpad(c.complaint_number::text, 4, '0'),
       COALESCE(c.title, left(c.description, 80)), c.description, 'high',
       CASE WHEN c.status::text = ANY (ARRAY['resolved','closed','cancelled']) THEN 'done' WHEN c.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       c.received_at, NULL::date, c.responsible_id,
       (SELECT ap.id FROM quality_action_plans ap WHERE ap.ncr_id = c.linked_ncr_id ORDER BY ap.created_at LIMIT 1),
       '/quality/complaints/'::text || c.id,
       NULL::text
  FROM quality_complaints c
 WHERE c.status::text <> ALL (ARRAY['resolved','closed','cancelled'])
UNION ALL
SELECT m.id, m.company_id, 'manual',
       COALESCE(m.category, 'Melhoria manual'),
       m.title, m.description, m.priority, m.status,
       m.created_at, m.due_date, m.responsible_id, m.action_plan_id,
       '/quality/improvements'::text,
       m.effectiveness_status
  FROM quality_improvements_manual m
 WHERE m.status <> ALL (ARRAY['done','cancelled'])
UNION ALL
SELECT r.id, r.company_id, 'risk',
       'Risco '::text || r.code, r.title, r.description,
       CASE r.severity WHEN 'critical' THEN 'high' WHEN 'high' THEN 'high' WHEN 'medium' THEN 'medium' ELSE 'low' END,
       'open', r.created_at, r.treatment_due_date, r.owner_user_id, NULL::uuid,
       '/quality/risks'::text, NULL::text
  FROM quality_risks r
 WHERE r.status <> ALL (ARRAY['closed'::quality_risk_status, 'accepted'::quality_risk_status])
   AND r.severity = ANY (ARRAY['high','critical']) AND r.treatment IS NULL
UNION ALL
SELECT sup.id, sup.company_id, 'supplier',
       'Fornecedor '::text || sup.status::text, sup.name,
       COALESCE(sup.notes, sup.scope_description),
       CASE WHEN sup.status = 'disqualified'::quality_supplier_status THEN 'high' ELSE 'medium' END,
       'open', sup.updated_at, sup.next_evaluation_due, sup.owner_user_id, NULL::uuid,
       '/quality/suppliers/'::text || sup.id, NULL::text
  FROM quality_suppliers sup
 WHERE sup.status = ANY (ARRAY['suspended'::quality_supplier_status, 'disqualified'::quality_supplier_status])
UNION ALL
SELECT d.id, d.company_id, 'device',
       'Instrumento '::text || d.status::text,
       (d.code || ' — ') || d.name, COALESCE(d.notes, d.description),
       CASE WHEN d.status = 'out_of_service'::quality_device_status THEN 'high' ELSE 'medium' END,
       'open', d.updated_at, d.next_calibration_due, d.responsible_user_id, NULL::uuid,
       '/quality/devices/'::text || d.id, NULL::text
  FROM quality_measuring_devices d
 WHERE d.status = ANY (ARRAY['out_of_service'::quality_device_status, 'retired'::quality_device_status]);

GRANT SELECT ON public.quality_improvements_v TO authenticated;