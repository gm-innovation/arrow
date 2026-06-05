
-- Sprint 2.4 — KPIs e indicadores do SGQ

-- Índices
CREATE INDEX IF NOT EXISTS idx_quality_ncrs_company_created ON public.quality_ncrs (company_id, created_at);
CREATE INDEX IF NOT EXISTS idx_quality_ncrs_company_closed ON public.quality_ncrs (company_id, closed_at);
CREATE INDEX IF NOT EXISTS idx_quality_action_plans_company_created ON public.quality_action_plans (company_id, created_at);
CREATE INDEX IF NOT EXISTS idx_quality_action_plans_company_target ON public.quality_action_plans (company_id, target_date);
CREATE INDEX IF NOT EXISTS idx_quality_audits_company_created ON public.quality_audits (company_id, created_at);
CREATE INDEX IF NOT EXISTS idx_quality_audits_company_planned ON public.quality_audits (company_id, planned_date);
CREATE INDEX IF NOT EXISTS idx_quality_documents_company_created ON public.quality_documents (company_id, created_at);
CREATE INDEX IF NOT EXISTS idx_quality_documents_company_review ON public.quality_documents (company_id, next_review_date);
CREATE INDEX IF NOT EXISTS idx_quality_doc_versions_approved ON public.quality_document_versions (document_id, created_at, approved_at);
CREATE INDEX IF NOT EXISTS idx_quality_mr_company_created ON public.quality_management_reviews (company_id, created_at);

-- Snapshot view
CREATE OR REPLACE VIEW public.quality_kpi_snapshot_v
WITH (security_invoker = true) AS
SELECT
  c.id AS company_id,
  (SELECT count(*) FROM public.quality_ncrs n
    WHERE n.company_id = c.id AND n.status NOT IN ('closed','cancelled')) AS ncrs_open,
  (SELECT count(*) FROM public.quality_ncrs n
    WHERE n.company_id = c.id
      AND n.status NOT IN ('closed','cancelled')
      AND n.deadline IS NOT NULL AND n.deadline < CURRENT_DATE) AS ncrs_overdue,
  (SELECT count(*) FROM public.quality_action_plans p
    WHERE p.company_id = c.id
      AND p.status NOT IN ('closed','effective','ineffective','cancelled')
      AND p.target_date IS NOT NULL AND p.target_date < CURRENT_DATE) AS plans_overdue,
  (SELECT count(*) FROM public.quality_action_plans p
    WHERE p.company_id = c.id AND p.status = 'effective') AS plans_effective,
  (SELECT count(*) FROM public.quality_action_plans p
    WHERE p.company_id = c.id AND p.status IN ('effective','ineffective')) AS plans_evaluated,
  (SELECT count(*) FROM public.quality_documents d
    WHERE d.company_id = c.id AND d.status = 'published') AS documents_published,
  (SELECT count(*) FROM public.quality_documents d
    WHERE d.company_id = c.id
      AND d.next_review_date IS NOT NULL
      AND d.next_review_date <= CURRENT_DATE + INTERVAL '30 days'
      AND d.status = 'published') AS documents_expiring_30d,
  (SELECT count(*) FROM public.quality_documents d
    WHERE d.company_id = c.id AND d.status = 'pending_approval') AS documents_pending_approval,
  (SELECT round(avg(EXTRACT(epoch FROM (v.approved_at - v.created_at)) / 86400.0)::numeric, 1)
     FROM public.quality_document_versions v
     JOIN public.quality_documents d ON d.id = v.document_id
    WHERE d.company_id = c.id
      AND v.approved_at IS NOT NULL
      AND v.approved_at >= now() - INTERVAL '12 months') AS avg_approval_days,
  (SELECT round(avg(EXTRACT(epoch FROM (n.closed_at - n.created_at)) / 86400.0)::numeric, 1)
     FROM public.quality_ncrs n
    WHERE n.company_id = c.id
      AND n.closed_at IS NOT NULL
      AND n.closed_at >= now() - INTERVAL '12 months') AS avg_ncr_resolution_days,
  (SELECT count(*) FROM public.quality_management_reviews r
    WHERE r.company_id = c.id AND r.status = 'closed'
      AND r.closed_at >= now() - INTERVAL '12 months') AS reviews_closed_12m,
  (SELECT count(*) FROM public.quality_management_review_outputs o
     JOIN public.quality_management_reviews r ON r.id = o.review_id
    WHERE r.company_id = c.id
      AND o.status::text <> 'done') AS review_outputs_open,
  (SELECT count(*) FROM public.quality_audit_findings f
     JOIN public.quality_audits a ON a.id = f.audit_id
    WHERE a.company_id = c.id AND f.finding_type = 'major'
      AND f.created_at >= now() - INTERVAL '12 months') AS findings_major_12m,
  (SELECT count(*) FROM public.quality_audit_findings f
     JOIN public.quality_audits a ON a.id = f.audit_id
    WHERE a.company_id = c.id AND f.finding_type = 'minor'
      AND f.created_at >= now() - INTERVAL '12 months') AS findings_minor_12m,
  (SELECT count(*) FROM public.quality_audit_findings f
     JOIN public.quality_audits a ON a.id = f.audit_id
    WHERE a.company_id = c.id AND f.finding_type = 'observation'
      AND f.created_at >= now() - INTERVAL '12 months') AS findings_observation_12m,
  (SELECT count(*) FROM public.quality_audit_findings f
     JOIN public.quality_audits a ON a.id = f.audit_id
    WHERE a.company_id = c.id AND f.finding_type = 'opportunity'
      AND f.created_at >= now() - INTERVAL '12 months') AS findings_opportunity_12m
FROM public.companies c;

GRANT SELECT ON public.quality_kpi_snapshot_v TO authenticated, service_role;

-- Timeseries view (12 monthly buckets)
CREATE OR REPLACE VIEW public.quality_kpi_timeseries_v
WITH (security_invoker = true) AS
WITH buckets AS (
  SELECT generate_series(
    date_trunc('month', now()) - INTERVAL '11 months',
    date_trunc('month', now()),
    INTERVAL '1 month'
  )::date AS bucket
)
SELECT
  c.id AS company_id,
  b.bucket AS month,
  (SELECT count(*) FROM public.quality_ncrs n
    WHERE n.company_id = c.id
      AND n.created_at >= b.bucket
      AND n.created_at <  b.bucket + INTERVAL '1 month') AS ncrs_opened,
  (SELECT count(*) FROM public.quality_ncrs n
    WHERE n.company_id = c.id
      AND n.closed_at IS NOT NULL
      AND n.closed_at >= b.bucket
      AND n.closed_at <  b.bucket + INTERVAL '1 month') AS ncrs_closed,
  (SELECT count(*) FROM public.quality_action_plans p
    WHERE p.company_id = c.id AND p.status = 'effective'
      AND p.verified_at >= b.bucket
      AND p.verified_at <  b.bucket + INTERVAL '1 month') AS plans_effective,
  (SELECT count(*) FROM public.quality_action_plans p
    WHERE p.company_id = c.id AND p.status = 'ineffective'
      AND p.verified_at >= b.bucket
      AND p.verified_at <  b.bucket + INTERVAL '1 month') AS plans_ineffective,
  (SELECT count(*) FROM public.quality_audits a
    WHERE a.company_id = c.id
      AND a.planned_date >= b.bucket
      AND a.planned_date <  b.bucket + INTERVAL '1 month') AS audits_planned,
  (SELECT count(*) FROM public.quality_audits a
    WHERE a.company_id = c.id
      AND a.actual_date >= b.bucket
      AND a.actual_date <  b.bucket + INTERVAL '1 month') AS audits_executed,
  (SELECT count(*) FROM public.quality_documents d
    WHERE d.company_id = c.id
      AND d.published_at >= b.bucket
      AND d.published_at <  b.bucket + INTERVAL '1 month') AS documents_published
FROM public.companies c
CROSS JOIN buckets b;

GRANT SELECT ON public.quality_kpi_timeseries_v TO authenticated, service_role;

-- Recurrence view
CREATE OR REPLACE VIEW public.quality_kpi_recurrence_v
WITH (security_invoker = true) AS
SELECT
  n.company_id,
  lower(trim(n.root_cause)) AS root_cause_key,
  min(n.root_cause) AS root_cause_sample,
  count(*) AS occurrences
FROM public.quality_ncrs n
WHERE n.root_cause IS NOT NULL
  AND trim(n.root_cause) <> ''
  AND n.created_at >= now() - INTERVAL '12 months'
GROUP BY n.company_id, lower(trim(n.root_cause));

GRANT SELECT ON public.quality_kpi_recurrence_v TO authenticated, service_role;

-- RPC agregadora
CREATE OR REPLACE FUNCTION public.quality_kpi_get_overview(p_company_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'cards', (SELECT to_jsonb(s) FROM public.quality_kpi_snapshot_v s WHERE s.company_id = p_company_id),
    'series', COALESCE(
      (SELECT jsonb_agg(to_jsonb(t) ORDER BY t.month)
         FROM public.quality_kpi_timeseries_v t
        WHERE t.company_id = p_company_id),
      '[]'::jsonb
    ),
    'recurrence', COALESCE(
      (SELECT jsonb_agg(to_jsonb(r))
         FROM (
           SELECT root_cause_sample, occurrences
             FROM public.quality_kpi_recurrence_v
            WHERE company_id = p_company_id
            ORDER BY occurrences DESC
            LIMIT 10
         ) r),
      '[]'::jsonb
    ),
    'generated_at', now()
  );
$$;

GRANT EXECUTE ON FUNCTION public.quality_kpi_get_overview(uuid) TO authenticated, service_role;
