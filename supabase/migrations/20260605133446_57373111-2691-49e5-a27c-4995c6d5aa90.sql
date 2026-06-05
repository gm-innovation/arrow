
DO $$ BEGIN
  CREATE TYPE public.quality_origin AS ENUM (
    'internal','client','external_norm','external_law','external_certificate','safety'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.quality_document_control_mode AS ENUM ('full_control','received_only');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'quality_alert';

ALTER TABLE public.quality_documents
  ADD COLUMN IF NOT EXISTS origin public.quality_origin NOT NULL DEFAULT 'internal',
  ADD COLUMN IF NOT EXISTS external_source text,
  ADD COLUMN IF NOT EXISTS validity_start date,
  ADD COLUMN IF NOT EXISTS validity_end date,
  ADD COLUMN IF NOT EXISTS auto_renewal boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS document_control_mode public.quality_document_control_mode NOT NULL DEFAULT 'full_control';

COMMENT ON COLUMN public.quality_documents.validity_start IS 'Informativo apenas; nao participa de alertas/validacoes na Sprint 2.2.';
COMMENT ON COLUMN public.quality_documents.auto_renewal IS 'Flag informativa apenas; nao automatiza renovacao na Sprint 2.2.';

CREATE TABLE IF NOT EXISTS public.quality_interested_parties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  name text NOT NULL,
  category text NOT NULL,
  needs_expectations text,
  monitoring_method text,
  relevance text NOT NULL DEFAULT 'media',
  owner_user_id uuid,
  status text NOT NULL DEFAULT 'ativo',
  review_frequency_months integer,
  last_reviewed_at timestamptz,
  last_reviewed_by uuid,
  last_review_notes text,
  next_review_due_at date,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_interested_parties TO authenticated;
GRANT ALL ON public.quality_interested_parties TO service_role;
ALTER TABLE public.quality_interested_parties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qip_select_company" ON public.quality_interested_parties
  FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));

CREATE POLICY "qip_write_qualidade" ON public.quality_interested_parties
  FOR ALL TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'qualidade')
      OR public.has_role(auth.uid(), 'director')
      OR public.has_role(auth.uid(), 'super_admin')
    )
  )
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'qualidade')
      OR public.has_role(auth.uid(), 'director')
      OR public.has_role(auth.uid(), 'super_admin')
    )
  );

CREATE TABLE IF NOT EXISTS public.quality_interested_party_evidences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id uuid NOT NULL REFERENCES public.quality_interested_parties(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  evidence_type text NOT NULL DEFAULT 'documento',
  document_id uuid REFERENCES public.quality_documents(id) ON DELETE SET NULL,
  external_file_path text,
  evidence_date date,
  valid_until date,
  uploaded_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_interested_party_evidences TO authenticated;
GRANT ALL ON public.quality_interested_party_evidences TO service_role;
ALTER TABLE public.quality_interested_party_evidences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qipe_select_company" ON public.quality_interested_party_evidences
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.quality_interested_parties p
    WHERE p.id = party_id AND p.company_id = public.user_company_id(auth.uid())
  ));

CREATE POLICY "qipe_write_qualidade" ON public.quality_interested_party_evidences
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.quality_interested_parties p
    WHERE p.id = party_id
      AND p.company_id = public.user_company_id(auth.uid())
      AND (
        public.has_role(auth.uid(), 'qualidade')
        OR public.has_role(auth.uid(), 'director')
        OR public.has_role(auth.uid(), 'super_admin')
      )
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.quality_interested_parties p
    WHERE p.id = party_id
      AND p.company_id = public.user_company_id(auth.uid())
      AND (
        public.has_role(auth.uid(), 'qualidade')
        OR public.has_role(auth.uid(), 'director')
        OR public.has_role(auth.uid(), 'super_admin')
      )
  ));

CREATE TABLE IF NOT EXISTS public.quality_alert_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  source text NOT NULL,
  entity_id uuid NOT NULL,
  status text NOT NULL,
  notified_at timestamptz NOT NULL DEFAULT now(),
  notification_id uuid,
  UNIQUE (source, entity_id, status)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_alert_history TO authenticated;
GRANT ALL ON public.quality_alert_history TO service_role;
ALTER TABLE public.quality_alert_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qah_select_company" ON public.quality_alert_history
  FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));

CREATE POLICY "qah_service" ON public.quality_alert_history
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE TRIGGER quality_ip_recalc_review
BEFORE INSERT OR UPDATE OF last_reviewed_at, review_frequency_months
ON public.quality_interested_parties
FOR EACH ROW EXECUTE FUNCTION public.quality_recalc_next_review();

CREATE TRIGGER quality_ip_set_updated_at
BEFORE UPDATE ON public.quality_interested_parties
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_timestamp();

CREATE TRIGGER quality_ipe_set_updated_at
BEFORE UPDATE ON public.quality_interested_party_evidences
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_timestamp();

CREATE OR REPLACE FUNCTION public.quality_cleanup_alert_history()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_source text := TG_ARGV[0];
BEGIN
  DELETE FROM public.quality_alert_history
   WHERE source = v_source AND entity_id = NEW.id;
  RETURN NEW;
END;
$fn$;

CREATE TRIGGER quality_ip_cleanup_history
AFTER UPDATE OF last_reviewed_at, next_review_due_at
ON public.quality_interested_parties
FOR EACH ROW EXECUTE FUNCTION public.quality_cleanup_alert_history('interested_party');

CREATE TRIGGER quality_ipe_cleanup_history
AFTER UPDATE OF valid_until
ON public.quality_interested_party_evidences
FOR EACH ROW EXECUTE FUNCTION public.quality_cleanup_alert_history('party_evidence');

CREATE TRIGGER quality_doc_cleanup_history
AFTER UPDATE OF validity_end, next_review_date
ON public.quality_documents
FOR EACH ROW EXECUTE FUNCTION public.quality_cleanup_alert_history('document');

CREATE TRIGGER quality_ctx_cleanup_history
AFTER UPDATE OF last_reviewed_at, next_review_due_at
ON public.quality_org_context
FOR EACH ROW EXECUTE FUNCTION public.quality_cleanup_alert_history('org_context');

CREATE OR REPLACE VIEW public.quality_alerts_v
WITH (security_invoker = on) AS
WITH s AS (
  SELECT
    company_id,
    COALESCE((review_cycles->>'alert_window_days')::int, 30) AS alert_window_days
  FROM public.quality_settings
)
SELECT
  'org_context'::text AS source,
  'org_context'::text AS category,
  c.id AS entity_id,
  c.company_id,
  'Contexto da Organização'::text AS title,
  c.next_review_due_at AS due_date,
  CASE
    WHEN c.next_review_due_at IS NULL THEN NULL
    WHEN c.next_review_due_at < CURRENT_DATE THEN 'overdue'
    WHEN c.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE s.company_id = c.company_id), 30)
      THEN 'due_soon'
    ELSE 'up_to_date'
  END AS status,
  (c.next_review_due_at - CURRENT_DATE) AS days_remaining
FROM public.quality_org_context c
WHERE c.next_review_due_at IS NOT NULL

UNION ALL
SELECT
  'interested_party'::text,
  'interested_party'::text,
  p.id,
  p.company_id,
  p.name,
  p.next_review_due_at,
  CASE
    WHEN p.next_review_due_at IS NULL THEN NULL
    WHEN p.next_review_due_at < CURRENT_DATE THEN 'overdue'
    WHEN p.next_review_due_at <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE s.company_id = p.company_id), 30)
      THEN 'due_soon'
    ELSE 'up_to_date'
  END,
  (p.next_review_due_at - CURRENT_DATE)
FROM public.quality_interested_parties p
WHERE p.next_review_due_at IS NOT NULL AND p.status = 'ativo'

UNION ALL
SELECT
  'party_evidence'::text,
  'party_evidence'::text,
  e.id,
  p.company_id,
  (p.name || ' — ' || e.title),
  e.valid_until,
  CASE
    WHEN e.valid_until < CURRENT_DATE THEN 'overdue'
    WHEN e.valid_until <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE s.company_id = p.company_id), 30)
      THEN 'due_soon'
    ELSE 'up_to_date'
  END,
  (e.valid_until - CURRENT_DATE)
FROM public.quality_interested_party_evidences e
JOIN public.quality_interested_parties p ON p.id = e.party_id
WHERE e.valid_until IS NOT NULL

UNION ALL
SELECT
  'document'::text,
  d.origin::text,
  d.id,
  d.company_id,
  (d.code || ' — ' || d.title),
  COALESCE(d.validity_end, d.next_review_date),
  CASE
    WHEN COALESCE(d.validity_end, d.next_review_date) < CURRENT_DATE THEN 'overdue'
    WHEN COALESCE(d.validity_end, d.next_review_date) <= CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE s.company_id = d.company_id), 30)
      THEN 'due_soon'
    ELSE 'up_to_date'
  END,
  (COALESCE(d.validity_end, d.next_review_date) - CURRENT_DATE)
FROM public.quality_documents d
WHERE COALESCE(d.validity_end, d.next_review_date) IS NOT NULL
  AND d.status NOT IN ('obsolete','archived');

GRANT SELECT ON public.quality_alerts_v TO authenticated;

CREATE OR REPLACE FUNCTION public.quality_generate_alert_notifications()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  alert_rec record;
  user_rec record;
  new_notification_id uuid;
  inserted_count int := 0;
BEGIN
  FOR alert_rec IN
    SELECT av.*
    FROM public.quality_alerts_v av
    WHERE av.status IN ('due_soon','overdue')
  LOOP
    IF EXISTS (
      SELECT 1 FROM public.quality_alert_history h
      WHERE h.source = alert_rec.source
        AND h.entity_id = alert_rec.entity_id
        AND h.status = alert_rec.status
    ) THEN
      CONTINUE;
    END IF;

    DELETE FROM public.quality_alert_history
      WHERE source = alert_rec.source AND entity_id = alert_rec.entity_id;

    FOR user_rec IN
      SELECT DISTINCT ur.user_id
      FROM public.user_roles ur
      JOIN public.profiles pr ON pr.id = ur.user_id
      WHERE ur.role = 'qualidade'
        AND pr.company_id = alert_rec.company_id
    LOOP
      INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id)
      VALUES (
        user_rec.user_id,
        'quality_alert',
        CASE WHEN alert_rec.status = 'overdue' THEN 'Item vencido — SGQ' ELSE 'Item próximo do vencimento — SGQ' END,
        alert_rec.title || ' (' ||
          CASE WHEN alert_rec.days_remaining < 0
            THEN 'venceu há ' || abs(alert_rec.days_remaining) || ' dias'
            ELSE 'vence em ' || alert_rec.days_remaining || ' dias'
          END || ')',
        alert_rec.entity_id
      )
      RETURNING id INTO new_notification_id;
    END LOOP;

    INSERT INTO public.quality_alert_history (company_id, source, entity_id, status, notification_id)
    VALUES (alert_rec.company_id, alert_rec.source, alert_rec.entity_id, alert_rec.status, new_notification_id);

    inserted_count := inserted_count + 1;
  END LOOP;
  RETURN inserted_count;
END;
$fn$;

GRANT EXECUTE ON FUNCTION public.quality_generate_alert_notifications() TO authenticated;
