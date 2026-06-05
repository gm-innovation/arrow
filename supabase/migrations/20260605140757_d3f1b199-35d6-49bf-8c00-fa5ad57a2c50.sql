
CREATE TYPE public.quality_review_status AS ENUM ('draft','in_progress','closed');
CREATE TYPE public.quality_review_input_type AS ENUM (
  'previous_actions_status','external_internal_changes','qms_performance',
  'resources_adequacy','stakeholder_feedback','improvement_opportunities','risks_opportunities'
);
CREATE TYPE public.quality_review_output_type AS ENUM (
  'improvement_opportunity','qms_change','resource_need','decision'
);
CREATE TYPE public.quality_review_output_status AS ENUM ('open','in_progress','done');
CREATE TYPE public.quality_review_participant_role AS ENUM ('chair','member','guest');

CREATE TABLE public.quality_management_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  review_date date NOT NULL,
  period_start date NOT NULL,
  period_end date NOT NULL,
  status public.quality_review_status NOT NULL DEFAULT 'draft',
  chair_user_id uuid REFERENCES public.profiles(id),
  summary text,
  minutes_document_id uuid REFERENCES public.quality_documents(id),
  signed_event_id uuid REFERENCES public.quality_signature_events(id),
  next_due_date date,
  closed_at timestamptz,
  closed_by uuid REFERENCES public.profiles(id),
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_management_reviews TO authenticated;
GRANT ALL ON public.quality_management_reviews TO service_role;
ALTER TABLE public.quality_management_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mr_select_company" ON public.quality_management_reviews FOR SELECT TO authenticated
USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "mr_insert_director" ON public.quality_management_reviews FOR INSERT TO authenticated
WITH CHECK (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "mr_update_director" ON public.quality_management_reviews FOR UPDATE TO authenticated
USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "mr_delete_director" ON public.quality_management_reviews FOR DELETE TO authenticated
USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()) AND status='draft'
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));

CREATE TRIGGER trg_mr_updated_at BEFORE UPDATE ON public.quality_management_reviews
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE public.quality_management_review_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id uuid NOT NULL REFERENCES public.quality_management_reviews(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  role_in_meeting public.quality_review_participant_role NOT NULL DEFAULT 'member',
  attended boolean NOT NULL DEFAULT false,
  confirmed_at timestamptz,
  signature_event_id uuid REFERENCES public.quality_signature_events(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(review_id, user_id)
);
COMMENT ON COLUMN public.quality_management_review_participants.attended IS 'Presença oficial registrada pelo presidente. Fonte de verdade.';
COMMENT ON COLUMN public.quality_management_review_participants.confirmed_at IS 'Auto-confirmação do participante. NÃO equivale a attended.';
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_management_review_participants TO authenticated;
GRANT ALL ON public.quality_management_review_participants TO service_role;
ALTER TABLE public.quality_management_review_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mrp_select" ON public.quality_management_review_participants FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid())));
CREATE POLICY "mrp_insert" ON public.quality_management_review_participants FOR INSERT TO authenticated
WITH CHECK (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id
  AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid())
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'))));
CREATE POLICY "mrp_update" ON public.quality_management_review_participants FOR UPDATE TO authenticated
USING (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid()))
  AND (user_id=auth.uid() OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "mrp_delete" ON public.quality_management_review_participants FOR DELETE TO authenticated
USING (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid()) AND r.status<>'closed'
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'))));

CREATE TRIGGER trg_mrp_updated_at BEFORE UPDATE ON public.quality_management_review_participants
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE public.quality_management_review_inputs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id uuid NOT NULL REFERENCES public.quality_management_reviews(id) ON DELETE CASCADE,
  input_type public.quality_review_input_type NOT NULL,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  notes text,
  is_snapshot boolean NOT NULL DEFAULT false,
  snapshot_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(review_id, input_type)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_management_review_inputs TO authenticated;
GRANT ALL ON public.quality_management_review_inputs TO service_role;
ALTER TABLE public.quality_management_review_inputs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mri_select" ON public.quality_management_review_inputs FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid())));
CREATE POLICY "mri_all" ON public.quality_management_review_inputs FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid())
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'))))
WITH CHECK (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid())
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'))));

CREATE TRIGGER trg_mri_updated_at BEFORE UPDATE ON public.quality_management_review_inputs
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.quality_mri_block_snapshot()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP='UPDATE' AND OLD.is_snapshot THEN
    RAISE EXCEPTION 'Entrada snapshotada — alteração não permitida';
  ELSIF TG_OP='DELETE' AND OLD.is_snapshot THEN
    RAISE EXCEPTION 'Entrada snapshotada — exclusão não permitida';
  END IF;
  RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END; $$;
CREATE TRIGGER trg_mri_block_snapshot BEFORE UPDATE OR DELETE ON public.quality_management_review_inputs
FOR EACH ROW EXECUTE FUNCTION public.quality_mri_block_snapshot();

CREATE TABLE public.quality_management_review_outputs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id uuid NOT NULL REFERENCES public.quality_management_reviews(id) ON DELETE CASCADE,
  output_type public.quality_review_output_type NOT NULL,
  description text NOT NULL,
  responsible_user_id uuid REFERENCES public.profiles(id),
  due_date date,
  linked_action_plan_id uuid UNIQUE REFERENCES public.quality_action_plans(id),
  status public.quality_review_output_status NOT NULL DEFAULT 'open',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_management_review_outputs TO authenticated;
GRANT ALL ON public.quality_management_review_outputs TO service_role;
ALTER TABLE public.quality_management_review_outputs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mro_select" ON public.quality_management_review_outputs FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid())));
CREATE POLICY "mro_all" ON public.quality_management_review_outputs FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid())
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'))))
WITH CHECK (EXISTS (SELECT 1 FROM public.quality_management_reviews r WHERE r.id=review_id AND r.company_id=(SELECT company_id FROM public.profiles WHERE id=auth.uid())
  AND (public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'))));

CREATE TRIGGER trg_mro_updated_at BEFORE UPDATE ON public.quality_management_review_outputs
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.quality_build_review_inputs(p_review_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.quality_management_reviews WHERE id=p_review_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reunião não encontrada'; END IF;
  IF r.status='closed' THEN RAISE EXCEPTION 'Reunião fechada — entradas imutáveis'; END IF;

  DELETE FROM public.quality_management_review_inputs
   WHERE review_id=p_review_id AND is_snapshot=false;

  INSERT INTO public.quality_management_review_inputs(review_id,input_type,content)
  SELECT p_review_id,'previous_actions_status', jsonb_build_object(
    'total', count(*),
    'open', count(*) FILTER (WHERE status NOT IN ('effective','closed')),
    'effective', count(*) FILTER (WHERE status='effective')
  ) FROM public.quality_action_plans
  WHERE company_id=r.company_id AND created_at::date BETWEEN r.period_start AND r.period_end;

  INSERT INTO public.quality_management_review_inputs(review_id,input_type,content)
  SELECT p_review_id,'external_internal_changes', jsonb_build_object(
    'internal_issues',internal_issues,'external_issues',external_issues,
    'last_reviewed_at',last_reviewed_at,'next_review_due_at',next_review_due_at)
  FROM public.quality_org_context WHERE company_id=r.company_id LIMIT 1;

  INSERT INTO public.quality_management_review_inputs(review_id,input_type,content)
  VALUES (p_review_id,'qms_performance', jsonb_build_object(
    'ncrs_total',(SELECT count(*) FROM public.quality_ncrs WHERE company_id=r.company_id AND created_at::date BETWEEN r.period_start AND r.period_end),
    'audits_total',(SELECT count(*) FROM public.quality_audits WHERE company_id=r.company_id AND planned_date BETWEEN r.period_start AND r.period_end)
  ));

  INSERT INTO public.quality_management_review_inputs(review_id,input_type,content) VALUES (p_review_id,'resources_adequacy','{}'::jsonb);

  INSERT INTO public.quality_management_review_inputs(review_id,input_type,content)
  VALUES (p_review_id,'stakeholder_feedback', jsonb_build_object(
    'parties_total',(SELECT count(*) FROM public.quality_interested_parties WHERE company_id=r.company_id AND status='ativo'),
    'evidences_in_period',(SELECT count(*) FROM public.quality_interested_party_evidences e JOIN public.quality_interested_parties p ON p.id=e.party_id WHERE p.company_id=r.company_id AND e.created_at::date BETWEEN r.period_start AND r.period_end)
  ));

  INSERT INTO public.quality_management_review_inputs(review_id,input_type,content) VALUES (p_review_id,'improvement_opportunities','{}'::jsonb);
  INSERT INTO public.quality_management_review_inputs(review_id,input_type,content) VALUES (p_review_id,'risks_opportunities','{}'::jsonb);
END; $$;
GRANT EXECUTE ON FUNCTION public.quality_build_review_inputs(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.quality_mr_on_close()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE cycle_months int;
BEGIN
  IF NEW.status='closed' AND COALESCE(OLD.status::text,'')<>'closed' THEN
    NEW.closed_at := COALESCE(NEW.closed_at, now());
    NEW.closed_by := COALESCE(NEW.closed_by, auth.uid());
    SELECT COALESCE((review_cycles->>'critical_review_months')::int,12) INTO cycle_months
    FROM public.quality_settings WHERE company_id=NEW.company_id LIMIT 1;
    cycle_months := COALESCE(cycle_months,12);
    NEW.next_due_date := (NEW.closed_at::date + (cycle_months || ' months')::interval)::date;
    UPDATE public.quality_management_review_inputs
       SET is_snapshot=true, snapshot_at=now()
     WHERE review_id=NEW.id AND is_snapshot=false;
  END IF;
  IF TG_OP='UPDATE' AND OLD.status='closed' THEN
    IF NEW.review_date IS DISTINCT FROM OLD.review_date
       OR NEW.period_start IS DISTINCT FROM OLD.period_start
       OR NEW.period_end IS DISTINCT FROM OLD.period_end
       OR NEW.status IS DISTINCT FROM OLD.status
       OR NEW.chair_user_id IS DISTINCT FROM OLD.chair_user_id
       OR NEW.summary IS DISTINCT FROM OLD.summary
       OR NEW.next_due_date IS DISTINCT FROM OLD.next_due_date
       OR NEW.closed_at IS DISTINCT FROM OLD.closed_at
       OR NEW.closed_by IS DISTINCT FROM OLD.closed_by THEN
      RAISE EXCEPTION 'Reunião fechada — apenas ata e assinatura podem ser anexadas';
    END IF;
  END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER trg_mr_on_close_before BEFORE UPDATE ON public.quality_management_reviews
FOR EACH ROW EXECUTE FUNCTION public.quality_mr_on_close();

CREATE OR REPLACE FUNCTION public.quality_mr_generate_action_plans()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE out_rec record; new_plan_id uuid;
BEGIN
  IF NEW.status='closed' AND COALESCE(OLD.status::text,'')<>'closed' THEN
    FOR out_rec IN
      SELECT * FROM public.quality_management_review_outputs
      WHERE review_id=NEW.id AND responsible_user_id IS NOT NULL
        AND due_date IS NOT NULL AND linked_action_plan_id IS NULL
    LOOP
      INSERT INTO public.quality_action_plans(company_id,title,description,plan_type,status,responsible_id,target_date,created_by)
      VALUES (NEW.company_id,
        'Análise Crítica ' || to_char(NEW.review_date,'DD/MM/YYYY') || ' — ' || left(out_rec.description,80),
        out_rec.description,
        CASE out_rec.output_type
          WHEN 'improvement_opportunity' THEN 'improvement'
          WHEN 'qms_change' THEN 'corrective'
          WHEN 'resource_need' THEN 'preventive'
          ELSE 'improvement' END,
        'draft', out_rec.responsible_user_id, out_rec.due_date, NEW.closed_by)
      RETURNING id INTO new_plan_id;
      UPDATE public.quality_management_review_outputs
         SET linked_action_plan_id=new_plan_id WHERE id=out_rec.id;
    END LOOP;
  END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER trg_mr_generate_action_plans AFTER UPDATE ON public.quality_management_reviews
FOR EACH ROW EXECUTE FUNCTION public.quality_mr_generate_action_plans();

CREATE OR REPLACE VIEW public.quality_alerts_v AS
WITH s AS (
  SELECT company_id, COALESCE((review_cycles->>'alert_window_days')::int,30) AS alert_window_days
  FROM public.quality_settings
)
SELECT 'org_context'::text AS source,'org_context'::text AS category, c.id AS entity_id, c.company_id,
  'Contexto da Organização'::text AS title, c.next_review_due_at AS due_date,
  CASE WHEN c.next_review_due_at IS NULL THEN NULL
       WHEN c.next_review_due_at < CURRENT_DATE THEN 'overdue'
       WHEN c.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id=c.company_id),30)) THEN 'due_soon'
       ELSE 'up_to_date' END AS status,
  (c.next_review_due_at - CURRENT_DATE) AS days_remaining
FROM public.quality_org_context c WHERE c.next_review_due_at IS NOT NULL
UNION ALL
SELECT 'interested_party','interested_party', p.id, p.company_id, p.name, p.next_review_due_at,
  CASE WHEN p.next_review_due_at IS NULL THEN NULL
       WHEN p.next_review_due_at < CURRENT_DATE THEN 'overdue'
       WHEN p.next_review_due_at <= (CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id=p.company_id),30)) THEN 'due_soon'
       ELSE 'up_to_date' END,
  (p.next_review_due_at - CURRENT_DATE)
FROM public.quality_interested_parties p WHERE p.next_review_due_at IS NOT NULL AND p.status='ativo'
UNION ALL
SELECT 'party_evidence','party_evidence', e.id, p.company_id, (p.name||' — '||e.title), e.valid_until,
  CASE WHEN e.valid_until < CURRENT_DATE THEN 'overdue'
       WHEN e.valid_until <= (CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id=p.company_id),30)) THEN 'due_soon'
       ELSE 'up_to_date' END,
  (e.valid_until - CURRENT_DATE)
FROM public.quality_interested_party_evidences e
JOIN public.quality_interested_parties p ON p.id=e.party_id WHERE e.valid_until IS NOT NULL
UNION ALL
SELECT 'document', d.origin::text, d.id, d.company_id, (d.code||' — '||d.title),
  COALESCE(d.validity_end, d.next_review_date),
  CASE WHEN COALESCE(d.validity_end,d.next_review_date) < CURRENT_DATE THEN 'overdue'
       WHEN COALESCE(d.validity_end,d.next_review_date) <= (CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id=d.company_id),30)) THEN 'due_soon'
       ELSE 'up_to_date' END,
  (COALESCE(d.validity_end,d.next_review_date) - CURRENT_DATE)
FROM public.quality_documents d
WHERE COALESCE(d.validity_end,d.next_review_date) IS NOT NULL AND d.status NOT IN ('obsolete','archived')
UNION ALL
SELECT 'management_review','management_review', mr.id, mr.company_id,
  'Próxima Análise Crítica', mr.next_due_date,
  CASE WHEN mr.next_due_date IS NULL THEN NULL
       WHEN mr.next_due_date < CURRENT_DATE THEN 'overdue'
       WHEN mr.next_due_date <= (CURRENT_DATE + COALESCE((SELECT alert_window_days FROM s WHERE company_id=mr.company_id),30)) THEN 'due_soon'
       ELSE 'up_to_date' END,
  (mr.next_due_date - CURRENT_DATE)
FROM public.quality_management_reviews mr
WHERE mr.status='closed' AND mr.next_due_date IS NOT NULL
  AND mr.id = (SELECT id FROM public.quality_management_reviews
               WHERE company_id=mr.company_id AND status='closed'
               ORDER BY closed_at DESC NULLS LAST LIMIT 1);
