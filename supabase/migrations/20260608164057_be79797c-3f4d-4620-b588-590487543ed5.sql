CREATE OR REPLACE VIEW public.quality_review_status_v AS
WITH cfg AS (
  SELECT company_id,
         COALESCE((review_cycles ->> 'alert_window_days')::int, 30) AS alert_window
    FROM public.quality_settings
)
SELECT 'org_context' AS entity_type, oc.id AS entity_id, oc.company_id,
       'Contexto da Organização'::text AS entity_label,
       oc.next_review_due_at,
       CASE
         WHEN oc.next_review_due_at IS NULL THEN 'no_cycle'
         WHEN oc.next_review_due_at < CURRENT_DATE THEN 'overdue'
         WHEN oc.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window FROM cfg WHERE company_id = oc.company_id), 30) THEN 'due_soon'
         ELSE 'up_to_date'
       END AS computed_status
  FROM public.quality_org_context oc
UNION ALL
SELECT 'document', d.id, d.company_id,
       (d.code || ' — ' || d.title)::text,
       d.next_review_date,
       CASE
         WHEN d.next_review_date IS NULL THEN 'no_cycle'
         WHEN d.next_review_date < CURRENT_DATE THEN 'overdue'
         WHEN d.next_review_date <= CURRENT_DATE + COALESCE((SELECT alert_window FROM cfg WHERE company_id = d.company_id), 30) THEN 'due_soon'
         ELSE 'up_to_date'
       END
  FROM public.quality_documents d
 WHERE d.status = 'published'::quality_document_status
UNION ALL
SELECT 'reference_norm', n.id, n.company_id,
       n.code || ' — ' || n.title,
       n.next_review_due_at,
       CASE
         WHEN n.next_review_due_at IS NULL THEN 'no_cycle'
         WHEN n.next_review_due_at < CURRENT_DATE THEN 'overdue'
         WHEN n.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window FROM cfg WHERE company_id = n.company_id), 30) THEN 'due_soon'
         ELSE 'up_to_date'
       END
  FROM public.quality_reference_norms n
 WHERE COALESCE(n.status, 'vigente') = 'vigente'
UNION ALL
SELECT 'term', t.id, t.company_id,
       t.term,
       t.next_review_due_at,
       CASE
         WHEN t.next_review_due_at IS NULL THEN 'no_cycle'
         WHEN t.next_review_due_at < CURRENT_DATE THEN 'overdue'
         WHEN t.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window FROM cfg WHERE company_id = t.company_id), 30) THEN 'due_soon'
         ELSE 'up_to_date'
       END
  FROM public.quality_terms t
 WHERE COALESCE(t.status, 'vigente') = 'vigente'
UNION ALL
SELECT 'interested_party', ip.id, ip.company_id,
       ip.name,
       ip.next_review_due_at,
       CASE
         WHEN ip.next_review_due_at IS NULL THEN 'no_cycle'
         WHEN ip.next_review_due_at < CURRENT_DATE THEN 'overdue'
         WHEN ip.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window FROM cfg WHERE company_id = ip.company_id), 30) THEN 'due_soon'
         ELSE 'up_to_date'
       END
  FROM public.quality_interested_parties ip
UNION ALL
SELECT 'risk', r.id, r.company_id,
       COALESCE(r.code, '') || ' — ' || r.title,
       r.next_review_due_at,
       CASE
         WHEN r.next_review_due_at IS NULL THEN 'no_cycle'
         WHEN r.next_review_due_at < CURRENT_DATE THEN 'overdue'
         WHEN r.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window FROM cfg WHERE company_id = r.company_id), 30) THEN 'due_soon'
         ELSE 'up_to_date'
       END
  FROM public.quality_risks r
 WHERE r.status NOT IN ('closed'::quality_risk_status, 'accepted'::quality_risk_status);

GRANT SELECT ON public.quality_review_status_v TO authenticated;