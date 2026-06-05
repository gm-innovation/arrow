
CREATE TYPE public.quality_device_status AS ENUM ('active','in_calibration','out_of_service','retired','overdue');
CREATE TYPE public.quality_calibration_kind AS ENUM ('internal','external_lab','manufacturer','self_check');
CREATE TYPE public.quality_calibration_result AS ENUM ('approved','approved_with_restriction','reproved');

CREATE TABLE public.quality_measuring_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  description text,
  manufacturer text,
  model text,
  serial_number text,
  measurement_range text,
  unit text,
  resolution text,
  accuracy text,
  location text,
  responsible_user_id uuid,
  status public.quality_device_status NOT NULL DEFAULT 'active',
  criticality text NOT NULL DEFAULT 'medium',
  calibration_frequency_months integer NOT NULL DEFAULT 12,
  last_calibration_at date,
  next_calibration_due date,
  acquired_at date,
  retired_at date,
  notes text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, code)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_measuring_devices TO authenticated;
GRANT ALL ON public.quality_measuring_devices TO service_role;
ALTER TABLE public.quality_measuring_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "devices_select_company" ON public.quality_measuring_devices
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "devices_insert_master_or_responsible" ON public.quality_measuring_devices
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (public.quality_is_master(auth.uid()) OR responsible_user_id = auth.uid())
  );
CREATE POLICY "devices_update_master_or_responsible" ON public.quality_measuring_devices
  FOR UPDATE TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (public.quality_is_master(auth.uid()) OR responsible_user_id = auth.uid())
  );
CREATE POLICY "devices_delete_master" ON public.quality_measuring_devices
  FOR DELETE TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND public.quality_is_master(auth.uid())
  );

CREATE TRIGGER quality_measuring_devices_touch
  BEFORE UPDATE ON public.quality_measuring_devices
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE TABLE public.quality_calibrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  device_id uuid NOT NULL REFERENCES public.quality_measuring_devices(id) ON DELETE CASCADE,
  kind public.quality_calibration_kind NOT NULL DEFAULT 'external_lab',
  calibration_date date NOT NULL,
  result public.quality_calibration_result NOT NULL DEFAULT 'approved',
  provider_supplier_id uuid REFERENCES public.quality_suppliers(id) ON DELETE SET NULL,
  certificate_number text,
  certificate_file_url text,
  certificate_file_name text,
  cost numeric(12,2),
  measurement_uncertainty text,
  traceability text,
  valid_until date,
  restrictions text,
  next_due_at date,
  performed_by_user_id uuid,
  notes text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_calibrations TO authenticated;
GRANT ALL ON public.quality_calibrations TO service_role;
ALTER TABLE public.quality_calibrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "calibrations_select_company" ON public.quality_calibrations
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "calibrations_insert_master_or_responsible" ON public.quality_calibrations
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      public.quality_is_master(auth.uid())
      OR EXISTS (SELECT 1 FROM public.quality_measuring_devices d WHERE d.id = device_id AND d.responsible_user_id = auth.uid())
    )
  );
CREATE POLICY "calibrations_update_master_or_responsible" ON public.quality_calibrations
  FOR UPDATE TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND (
      public.quality_is_master(auth.uid())
      OR EXISTS (SELECT 1 FROM public.quality_measuring_devices d WHERE d.id = device_id AND d.responsible_user_id = auth.uid())
    )
  );
CREATE POLICY "calibrations_delete_master" ON public.quality_calibrations
  FOR DELETE TO authenticated
  USING (
    company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND public.quality_is_master(auth.uid())
  );

CREATE TRIGGER quality_calibrations_touch
  BEFORE UPDATE ON public.quality_calibrations
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE INDEX idx_quality_calibrations_device ON public.quality_calibrations(device_id, calibration_date DESC);

CREATE TABLE public.quality_calibration_checkpoints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  calibration_id uuid NOT NULL REFERENCES public.quality_calibrations(id) ON DELETE CASCADE,
  nominal_value numeric,
  measured_value numeric,
  error numeric,
  tolerance numeric,
  pass boolean,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_calibration_checkpoints TO authenticated;
GRANT ALL ON public.quality_calibration_checkpoints TO service_role;
ALTER TABLE public.quality_calibration_checkpoints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "checkpoints_select_company" ON public.quality_calibration_checkpoints
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.quality_calibrations c
    WHERE c.id = calibration_id AND c.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  ));
CREATE POLICY "checkpoints_write_master_or_responsible" ON public.quality_calibration_checkpoints
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.quality_calibrations c
    JOIN public.quality_measuring_devices d ON d.id = c.device_id
    WHERE c.id = calibration_id
      AND c.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
      AND (public.quality_is_master(auth.uid()) OR d.responsible_user_id = auth.uid())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.quality_calibrations c
    JOIN public.quality_measuring_devices d ON d.id = c.device_id
    WHERE c.id = calibration_id
      AND c.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
      AND (public.quality_is_master(auth.uid()) OR d.responsible_user_id = auth.uid())
  ));

CREATE TABLE public.quality_device_usage_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  device_id uuid NOT NULL REFERENCES public.quality_measuring_devices(id) ON DELETE CASCADE,
  service_order_id uuid,
  used_at timestamptz NOT NULL DEFAULT now(),
  used_by uuid,
  notes text
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_device_usage_log TO authenticated;
GRANT ALL ON public.quality_device_usage_log TO service_role;
ALTER TABLE public.quality_device_usage_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usage_log_select_company" ON public.quality_device_usage_log
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "usage_log_insert_company" ON public.quality_device_usage_log
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE OR REPLACE FUNCTION public.quality_device_before_insert_trigger()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.next_calibration_due IS NULL AND NEW.last_calibration_at IS NOT NULL THEN
    NEW.next_calibration_due := NEW.last_calibration_at + (NEW.calibration_frequency_months || ' months')::interval;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER quality_device_before_insert
  BEFORE INSERT ON public.quality_measuring_devices
  FOR EACH ROW EXECUTE FUNCTION public.quality_device_before_insert_trigger();

CREATE OR REPLACE FUNCTION public.quality_calibration_after_change_trigger()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_freq integer;
BEGIN
  SELECT calibration_frequency_months INTO v_freq FROM public.quality_measuring_devices WHERE id = NEW.device_id;
  IF NEW.result IN ('approved','approved_with_restriction') THEN
    UPDATE public.quality_measuring_devices
    SET last_calibration_at = NEW.calibration_date,
        next_calibration_due = COALESCE(NEW.valid_until, NEW.next_due_at, NEW.calibration_date + (COALESCE(v_freq,12) || ' months')::interval),
        status = 'active'
    WHERE id = NEW.device_id;
  ELSIF NEW.result = 'reproved' THEN
    UPDATE public.quality_measuring_devices SET status = 'out_of_service' WHERE id = NEW.device_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER quality_calibration_after_change
  AFTER INSERT OR UPDATE ON public.quality_calibrations
  FOR EACH ROW EXECUTE FUNCTION public.quality_calibration_after_change_trigger();

CREATE OR REPLACE FUNCTION public.quality_device_status_refresh()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.quality_measuring_devices
  SET status = 'overdue'
  WHERE status = 'active' AND next_calibration_due IS NOT NULL AND next_calibration_due < CURRENT_DATE;
END;
$$;
GRANT EXECUTE ON FUNCTION public.quality_device_status_refresh() TO authenticated;

CREATE OR REPLACE FUNCTION public.quality_device_block_usage(p_device_id uuid)
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_status public.quality_device_status; v_due date;
BEGIN
  SELECT status, next_calibration_due INTO v_status, v_due FROM public.quality_measuring_devices WHERE id = p_device_id;
  IF v_status IS NULL THEN RETURN false; END IF;
  IF v_status IN ('out_of_service','retired','overdue') THEN RETURN true; END IF;
  IF v_due IS NOT NULL AND v_due < CURRENT_DATE THEN RETURN true; END IF;
  RETURN false;
END;
$$;
GRANT EXECUTE ON FUNCTION public.quality_device_block_usage(uuid) TO authenticated;

CREATE POLICY "calibrations_storage_select" ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'quality-calibrations'
    AND EXISTS (
      SELECT 1 FROM public.quality_measuring_devices d
      WHERE d.id::text = (storage.foldername(name))[2]
        AND d.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
        AND (public.quality_is_master(auth.uid()) OR d.responsible_user_id = auth.uid())
    )
  );
CREATE POLICY "calibrations_storage_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'quality-calibrations'
    AND EXISTS (
      SELECT 1 FROM public.quality_measuring_devices d
      WHERE d.id::text = (storage.foldername(name))[2]
        AND d.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
        AND (public.quality_is_master(auth.uid()) OR d.responsible_user_id = auth.uid())
    )
  );
CREATE POLICY "calibrations_storage_update" ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'quality-calibrations'
    AND EXISTS (
      SELECT 1 FROM public.quality_measuring_devices d
      WHERE d.id::text = (storage.foldername(name))[2]
        AND d.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
        AND (public.quality_is_master(auth.uid()) OR d.responsible_user_id = auth.uid())
    )
  );
CREATE POLICY "calibrations_storage_delete" ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'quality-calibrations'
    AND EXISTS (
      SELECT 1 FROM public.quality_measuring_devices d
      WHERE d.id::text = (storage.foldername(name))[2]
        AND d.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
        AND (public.quality_is_master(auth.uid()) OR d.responsible_user_id = auth.uid())
    )
  );

CREATE OR REPLACE VIEW public.quality_alerts_v AS
WITH s AS (
  SELECT quality_settings.company_id,
         COALESCE((quality_settings.review_cycles ->> 'alert_window_days')::integer, 30) AS alert_window_days
  FROM quality_settings
)
SELECT source, category, entity_id, company_id, title, due_date, status, days_remaining
FROM (
  SELECT 'org_context'::text AS source, 'org_context'::text AS category, c.id AS entity_id, c.company_id,
         'Contexto da Organização'::text AS title, c.next_review_due_at AS due_date,
         CASE WHEN c.next_review_due_at IS NULL THEN NULL::text
              WHEN c.next_review_due_at < CURRENT_DATE THEN 'overdue'
              WHEN c.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = c.company_id),30)) THEN 'due_soon'
              ELSE 'up_to_date' END AS status,
         c.next_review_due_at - CURRENT_DATE AS days_remaining
  FROM quality_org_context c WHERE c.next_review_due_at IS NOT NULL
  UNION ALL
  SELECT 'interested_party','interested_party', p.id, p.company_id, p.name, p.next_review_due_at,
         CASE WHEN p.next_review_due_at IS NULL THEN NULL::text
              WHEN p.next_review_due_at < CURRENT_DATE THEN 'overdue'
              WHEN p.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = p.company_id),30)) THEN 'due_soon'
              ELSE 'up_to_date' END,
         p.next_review_due_at - CURRENT_DATE
  FROM quality_interested_parties p WHERE p.next_review_due_at IS NOT NULL AND p.status = 'ativo'
  UNION ALL
  SELECT 'party_evidence','party_evidence', e.id, p.company_id, (p.name || ' — ') || e.title, e.valid_until,
         CASE WHEN e.valid_until < CURRENT_DATE THEN 'overdue'
              WHEN e.valid_until <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = p.company_id),30)) THEN 'due_soon'
              ELSE 'up_to_date' END,
         e.valid_until - CURRENT_DATE
  FROM quality_interested_party_evidences e JOIN quality_interested_parties p ON p.id = e.party_id
  WHERE e.valid_until IS NOT NULL
  UNION ALL
  SELECT 'risk','risk_review', r.id, r.company_id,
         (('Revisão de risco: ' || r.code) || ' — ') || r.title, r.next_review_due_at,
         CASE WHEN r.next_review_due_at IS NULL THEN NULL::text
              WHEN r.next_review_due_at < CURRENT_DATE THEN 'overdue'
              WHEN r.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = r.company_id),30)) THEN 'due_soon'
              ELSE 'up_to_date' END,
         r.next_review_due_at - CURRENT_DATE
  FROM quality_risks r
  WHERE r.next_review_due_at IS NOT NULL AND r.status <> ALL (ARRAY['closed'::quality_risk_status,'accepted'::quality_risk_status])
  UNION ALL
  SELECT 'risk','risk_treatment', r.id, r.company_id,
         (('Tratamento atrasado: ' || r.code) || ' — ') || r.title, r.treatment_due_date,
         CASE WHEN r.treatment_due_date IS NULL THEN NULL::text
              WHEN r.treatment_due_date < CURRENT_DATE THEN 'overdue'
              WHEN r.treatment_due_date <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = r.company_id),30)) THEN 'due_soon'
              ELSE 'up_to_date' END,
         r.treatment_due_date - CURRENT_DATE
  FROM quality_risks r
  WHERE r.treatment_due_date IS NOT NULL AND r.status = ANY (ARRAY['analyzing'::quality_risk_status,'treating'::quality_risk_status])
  UNION ALL
  SELECT 'supplier','requalification', sup.id, sup.company_id, sup.name, sup.next_evaluation_due,
         CASE WHEN sup.next_evaluation_due IS NULL THEN NULL::text
              WHEN sup.next_evaluation_due < CURRENT_DATE THEN 'overdue'
              WHEN sup.next_evaluation_due <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = sup.company_id),30)) THEN 'due_soon'
              ELSE 'up_to_date' END,
         sup.next_evaluation_due - CURRENT_DATE
  FROM quality_suppliers sup
  WHERE sup.next_evaluation_due IS NOT NULL AND sup.status = ANY (ARRAY['approved'::quality_supplier_status,'conditional'::quality_supplier_status])
  UNION ALL
  SELECT 'supplier','pending_qualification', sup.id, sup.company_id, sup.name,
         (sup.created_at + interval '30 days')::date,
         CASE WHEN (sup.created_at + interval '30 days')::date < CURRENT_DATE THEN 'overdue' ELSE 'due_soon' END,
         (sup.created_at + interval '30 days')::date - CURRENT_DATE
  FROM quality_suppliers sup WHERE sup.status = 'pending'::quality_supplier_status
  UNION ALL
  SELECT 'device','calibration', d.id, d.company_id,
         ('Calibração: ' || d.code || ' — ' || d.name)::text, d.next_calibration_due,
         CASE WHEN d.next_calibration_due IS NULL THEN NULL::text
              WHEN d.next_calibration_due < CURRENT_DATE THEN 'overdue'
              WHEN d.next_calibration_due <= (CURRENT_DATE + COALESCE((SELECT s.alert_window_days FROM s WHERE s.company_id = d.company_id),30)) THEN 'due_soon'
              ELSE 'up_to_date' END,
         d.next_calibration_due - CURRENT_DATE
  FROM quality_measuring_devices d
  WHERE d.next_calibration_due IS NOT NULL
    AND d.status = ANY (ARRAY['active'::quality_device_status,'in_calibration'::quality_device_status,'overdue'::quality_device_status])
) u;

CREATE OR REPLACE VIEW public.quality_improvements_v AS
SELECT n.id, n.company_id, 'ncr'::text AS source,
       'NCR-' || lpad(n.ncr_number::text, 4, '0') AS source_label,
       n.title, n.description,
       CASE n.severity WHEN 'high' THEN 'high' WHEN 'low' THEN 'low' ELSE 'medium' END AS priority,
       CASE WHEN n.status = ANY (ARRAY['closed','cancelled']) THEN 'done' ELSE 'open' END AS status,
       n.created_at AS opened_at, n.deadline::date AS due_date, n.responsible_id AS owner_user_id,
       (SELECT ap.id FROM quality_action_plans ap WHERE ap.ncr_id = n.id ORDER BY ap.created_at LIMIT 1) AS action_plan_id,
       '/quality/ncrs'::text AS source_url
FROM quality_ncrs n WHERE n.status <> ALL (ARRAY['closed','cancelled'])
UNION ALL
SELECT f.id, a.company_id, 'audit_finding','Auditoria #' || a.audit_number,
       COALESCE(left(f.description,80),'Achado de auditoria'), f.description,
       CASE f.finding_type WHEN 'major_nc' THEN 'high' WHEN 'minor_nc' THEN 'medium' WHEN 'observation' THEN 'low' WHEN 'opportunity' THEN 'low' ELSE 'medium' END,
       CASE WHEN f.status = ANY (ARRAY['closed','verified']) THEN 'done' WHEN f.status = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       f.created_at, f.deadline, f.responsible_id, f.action_plan_id, '/quality/audits'
FROM quality_audit_findings f JOIN quality_audits a ON a.id = f.audit_id
WHERE COALESCE(f.status,'open') <> ALL (ARRAY['closed','verified','cancelled'])
UNION ALL
SELECT o.id, r.company_id, 'review_output',
       'Análise Crítica — ' || to_char(r.review_date::timestamptz,'DD/MM/YYYY'),
       COALESCE(left(o.description,80),'Saída de análise crítica'), o.description, 'medium',
       CASE WHEN o.status::text = ANY (ARRAY['closed','done','completed']) THEN 'done' WHEN o.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       o.created_at, o.due_date, o.responsible_user_id, o.linked_action_plan_id,
       '/quality/management-review/' || r.id
FROM quality_management_review_outputs o JOIN quality_management_reviews r ON r.id = o.review_id
WHERE o.status::text <> ALL (ARRAY['closed','done','completed','cancelled'])
UNION ALL
SELECT c.id, c.company_id, 'complaint',
       'Reclamação #' || lpad(c.complaint_number::text,4,'0'),
       COALESCE(c.title, left(c.description,80)), c.description, 'high',
       CASE WHEN c.status::text = ANY (ARRAY['resolved','closed','cancelled']) THEN 'done' WHEN c.status::text = 'in_progress' THEN 'in_progress' ELSE 'open' END,
       c.received_at, NULL::date, c.responsible_id,
       (SELECT ap.id FROM quality_action_plans ap WHERE ap.ncr_id = c.linked_ncr_id ORDER BY ap.created_at LIMIT 1),
       '/quality/complaints/' || c.id
FROM quality_complaints c WHERE c.status::text <> ALL (ARRAY['resolved','closed','cancelled'])
UNION ALL
SELECT m.id, m.company_id, 'manual',
       COALESCE(m.category,'Melhoria manual'), m.title, m.description, m.priority, m.status,
       m.created_at, m.due_date, m.responsible_id, m.action_plan_id, '/quality/improvements'
FROM quality_improvements_manual m WHERE m.status <> ALL (ARRAY['done','cancelled'])
UNION ALL
SELECT r.id, r.company_id, 'risk', 'Risco ' || r.code, r.title, r.description,
       CASE r.severity WHEN 'critical' THEN 'high' WHEN 'high' THEN 'high' WHEN 'medium' THEN 'medium' ELSE 'low' END,
       'open', r.created_at, r.treatment_due_date, r.owner_user_id, NULL::uuid, '/quality/risks'
FROM quality_risks r
WHERE r.status <> ALL (ARRAY['closed'::quality_risk_status,'accepted'::quality_risk_status])
  AND r.severity = ANY (ARRAY['high','critical']) AND r.treatment IS NULL
UNION ALL
SELECT sup.id, sup.company_id, 'supplier', 'Fornecedor ' || sup.status::text,
       sup.name, COALESCE(sup.notes, sup.scope_description),
       CASE WHEN sup.status = 'disqualified'::quality_supplier_status THEN 'high' ELSE 'medium' END,
       'open', sup.updated_at, sup.next_evaluation_due, sup.owner_user_id, NULL::uuid,
       '/quality/suppliers/' || sup.id
FROM quality_suppliers sup
WHERE sup.status = ANY (ARRAY['suspended'::quality_supplier_status,'disqualified'::quality_supplier_status])
UNION ALL
SELECT d.id, d.company_id, 'device', 'Instrumento ' || d.status::text,
       d.code || ' — ' || d.name, COALESCE(d.notes, d.description),
       CASE WHEN d.status = 'out_of_service'::quality_device_status THEN 'high' ELSE 'medium' END,
       'open', d.updated_at, d.next_calibration_due, d.responsible_user_id, NULL::uuid,
       '/quality/devices/' || d.id
FROM quality_measuring_devices d
WHERE d.status = ANY (ARRAY['out_of_service'::quality_device_status,'retired'::quality_device_status]);
