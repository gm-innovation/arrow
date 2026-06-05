
-- ============ 1. Função reutilizável para recalcular next_review_due_at ============
CREATE OR REPLACE FUNCTION public.quality_recalc_next_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.last_reviewed_at IS NULL OR NEW.review_frequency_months IS NULL THEN
    NEW.next_review_due_at := NULL;
  ELSE
    NEW.next_review_due_at := (NEW.last_reviewed_at::date + (NEW.review_frequency_months || ' months')::interval)::date;
  END IF;
  RETURN NEW;
END;
$$;

-- ============ 2. quality_reference_norms ============
CREATE TABLE public.quality_reference_norms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  code text NOT NULL,
  title text NOT NULL,
  issuer text,
  valid_from date,
  valid_until date,
  document_id uuid REFERENCES public.quality_documents(id) ON DELETE SET NULL,
  notes text,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, code)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_reference_norms TO authenticated;
GRANT ALL ON public.quality_reference_norms TO service_role;
ALTER TABLE public.quality_reference_norms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qrn_select" ON public.quality_reference_norms FOR SELECT TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
);
CREATE POLICY "qrn_master_write" ON public.quality_reference_norms FOR ALL TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
)
WITH CHECK (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
);

CREATE TRIGGER trg_qrn_updated BEFORE UPDATE ON public.quality_reference_norms
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============ 3. quality_terms ============
CREATE TABLE public.quality_terms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  term text NOT NULL,
  definition text NOT NULL,
  source_norm_id uuid REFERENCES public.quality_reference_norms(id) ON DELETE SET NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, term)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_terms TO authenticated;
GRANT ALL ON public.quality_terms TO service_role;
ALTER TABLE public.quality_terms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qt_select" ON public.quality_terms FOR SELECT TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
);
CREATE POLICY "qt_master_write" ON public.quality_terms FOR ALL TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
)
WITH CHECK (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
);

CREATE TRIGGER trg_qt_updated BEFORE UPDATE ON public.quality_terms
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============ 4. quality_org_context (singleton por empresa) ============
CREATE TABLE public.quality_org_context (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL UNIQUE REFERENCES public.companies(id) ON DELETE CASCADE,
  internal_issues text,
  external_issues text,
  applicable_scope text,
  review_frequency_months integer,
  last_reviewed_at timestamptz,
  last_reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  last_review_notes text,
  next_review_due_at date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_org_context TO authenticated;
GRANT ALL ON public.quality_org_context TO service_role;
ALTER TABLE public.quality_org_context ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qoc_select" ON public.quality_org_context FOR SELECT TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
);
CREATE POLICY "qoc_master_write" ON public.quality_org_context FOR ALL TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
)
WITH CHECK (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
);

CREATE TRIGGER trg_qoc_updated BEFORE UPDATE ON public.quality_org_context
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_qoc_recalc_review
BEFORE INSERT OR UPDATE OF last_reviewed_at, review_frequency_months
ON public.quality_org_context
FOR EACH ROW EXECUTE FUNCTION public.quality_recalc_next_review();

-- ============ 5. quality_settings (config por empresa, JSONB) ============
CREATE TABLE public.quality_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL UNIQUE REFERENCES public.companies(id) ON DELETE CASCADE,
  review_cycles jsonb NOT NULL DEFAULT jsonb_build_object(
    'org_context_months', 12,
    'interested_parties_months', 12,
    'critical_review_months', 12,
    'alert_window_days', 30
  ),
  critical_review_required_topics jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_settings TO authenticated;
GRANT ALL ON public.quality_settings TO service_role;
ALTER TABLE public.quality_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qs_select" ON public.quality_settings FOR SELECT TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
);
CREATE POLICY "qs_master_write" ON public.quality_settings FOR ALL TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
)
WITH CHECK (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (has_role(auth.uid(), 'qualidade'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role))
);

CREATE TRIGGER trg_qs_updated BEFORE UPDATE ON public.quality_settings
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============ 6. view consolidada de status de revisão ============
CREATE OR REPLACE VIEW public.quality_review_status_v
WITH (security_invoker = true)
AS
SELECT
  'org_context'::text AS entity_type,
  oc.id AS entity_id,
  oc.company_id,
  'Contexto da Organização'::text AS entity_label,
  oc.next_review_due_at,
  CASE
    WHEN oc.next_review_due_at IS NULL THEN 'no_cycle'
    WHEN oc.next_review_due_at < CURRENT_DATE THEN 'overdue'
    WHEN oc.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT (review_cycles->>'alert_window_days')::int FROM public.quality_settings WHERE company_id = oc.company_id), 30)
      THEN 'due_soon'
    ELSE 'up_to_date'
  END AS computed_status
FROM public.quality_org_context oc

UNION ALL

SELECT
  'document'::text AS entity_type,
  d.id AS entity_id,
  d.company_id,
  (d.code || ' — ' || d.title) AS entity_label,
  d.next_review_date AS next_review_due_at,
  CASE
    WHEN d.next_review_date IS NULL THEN 'no_cycle'
    WHEN d.next_review_date < CURRENT_DATE THEN 'overdue'
    WHEN d.next_review_date <= CURRENT_DATE + COALESCE((SELECT (review_cycles->>'alert_window_days')::int FROM public.quality_settings WHERE company_id = d.company_id), 30)
      THEN 'due_soon'
    ELSE 'up_to_date'
  END AS computed_status
FROM public.quality_documents d
WHERE d.status = 'published';

GRANT SELECT ON public.quality_review_status_v TO authenticated;
