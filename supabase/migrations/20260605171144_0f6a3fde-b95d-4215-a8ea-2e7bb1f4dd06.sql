
-- =========================================
-- ENUMS
-- =========================================
CREATE TYPE public.quality_competency_level AS ENUM ('none','basic','intermediate','advanced','expert');
CREATE TYPE public.quality_competency_category AS ENUM ('technical','behavioral','regulatory','safety','management');
CREATE TYPE public.quality_evidence_type AS ENUM ('university_course','university_trail','hr_certificate','acknowledgement','manual');
CREATE TYPE public.quality_training_plan_status AS ENUM ('proposed','in_progress','completed','cancelled');

-- helper to convert level enum to integer for arithmetic
CREATE OR REPLACE FUNCTION public.quality_level_to_int(p_level public.quality_competency_level)
RETURNS integer LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE p_level
    WHEN 'none' THEN 0
    WHEN 'basic' THEN 1
    WHEN 'intermediate' THEN 2
    WHEN 'advanced' THEN 3
    WHEN 'expert' THEN 4
  END
$$;

CREATE OR REPLACE FUNCTION public.quality_int_to_level(p_int integer)
RETURNS public.quality_competency_level LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE GREATEST(0, LEAST(4, COALESCE(p_int,0)))
    WHEN 0 THEN 'none'::public.quality_competency_level
    WHEN 1 THEN 'basic'::public.quality_competency_level
    WHEN 2 THEN 'intermediate'::public.quality_competency_level
    WHEN 3 THEN 'advanced'::public.quality_competency_level
    WHEN 4 THEN 'expert'::public.quality_competency_level
  END
$$;

-- =========================================
-- HELPER: master da qualidade
-- =========================================
CREATE OR REPLACE FUNCTION public.quality_is_master(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.has_role(_user_id, 'super_admin')
      OR public.has_role(_user_id, 'director')
      OR public.has_role(_user_id, 'coordinator')
      OR public.has_role(_user_id, 'qualidade')
$$;

-- =========================================
-- TABLE: quality_competencies
-- =========================================
CREATE TABLE public.quality_competencies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  category public.quality_competency_category NOT NULL DEFAULT 'technical',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, name)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_competencies TO authenticated;
GRANT ALL ON public.quality_competencies TO service_role;
ALTER TABLE public.quality_competencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "competencies_select_company" ON public.quality_competencies FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "competencies_master_cud" ON public.quality_competencies FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- =========================================
-- TABLE: quality_role_requirements
-- =========================================
CREATE TABLE public.quality_role_requirements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  competency_id uuid NOT NULL REFERENCES public.quality_competencies(id) ON DELETE CASCADE,
  required_level public.quality_competency_level NOT NULL DEFAULT 'basic',
  is_mandatory boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, role, competency_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_role_requirements TO authenticated;
GRANT ALL ON public.quality_role_requirements TO service_role;
ALTER TABLE public.quality_role_requirements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "req_select_company" ON public.quality_role_requirements FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "req_master_cud" ON public.quality_role_requirements FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- =========================================
-- TABLE: quality_user_competencies
-- =========================================
CREATE TABLE public.quality_user_competencies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  competency_id uuid NOT NULL REFERENCES public.quality_competencies(id) ON DELETE CASCADE,
  current_level public.quality_competency_level NOT NULL DEFAULT 'none',
  manual_override boolean NOT NULL DEFAULT false,
  auto_suggested_level public.quality_competency_level NOT NULL DEFAULT 'none',
  auto_suggestion_reason text,
  last_assessed_at timestamptz,
  assessed_by uuid,
  assessment_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, user_id, competency_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_user_competencies TO authenticated;
GRANT ALL ON public.quality_user_competencies TO service_role;
ALTER TABLE public.quality_user_competencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "uc_select_self" ON public.quality_user_competencies FOR SELECT TO authenticated
  USING (user_id = auth.uid());
CREATE POLICY "uc_select_master" ON public.quality_user_competencies FOR SELECT TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "uc_master_cud" ON public.quality_user_competencies FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- =========================================
-- TABLE: quality_competency_evidences
-- =========================================
CREATE TABLE public.quality_competency_evidences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_competency_id uuid NOT NULL REFERENCES public.quality_user_competencies(id) ON DELETE CASCADE,
  evidence_type public.quality_evidence_type NOT NULL,
  source_id uuid,
  source_label text,
  evidence_date timestamptz NOT NULL DEFAULT now(),
  level_contribution public.quality_competency_level NOT NULL DEFAULT 'basic',
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_competency_evidences TO authenticated;
GRANT ALL ON public.quality_competency_evidences TO service_role;
ALTER TABLE public.quality_competency_evidences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ev_select_self" ON public.quality_competency_evidences FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.quality_user_competencies uc WHERE uc.id = user_competency_id AND uc.user_id = auth.uid()));
CREATE POLICY "ev_select_master" ON public.quality_competency_evidences FOR SELECT TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "ev_master_cud" ON public.quality_competency_evidences FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- =========================================
-- TABLE: quality_competency_mappings
-- =========================================
CREATE TABLE public.quality_competency_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  competency_id uuid NOT NULL REFERENCES public.quality_competencies(id) ON DELETE CASCADE,
  evidence_type public.quality_evidence_type NOT NULL,
  source_id uuid,
  source_label text,
  grants_level public.quality_competency_level NOT NULL DEFAULT 'basic',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, competency_id, evidence_type, source_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_competency_mappings TO authenticated;
GRANT ALL ON public.quality_competency_mappings TO service_role;
ALTER TABLE public.quality_competency_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "map_select_company" ON public.quality_competency_mappings FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "map_master_cud" ON public.quality_competency_mappings FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- =========================================
-- TABLE: quality_training_plans
-- =========================================
CREATE TABLE public.quality_training_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  competency_id uuid NOT NULL REFERENCES public.quality_competencies(id) ON DELETE CASCADE,
  current_level public.quality_competency_level NOT NULL,
  required_level public.quality_competency_level NOT NULL,
  target_level public.quality_competency_level NOT NULL,
  status public.quality_training_plan_status NOT NULL DEFAULT 'proposed',
  due_date date,
  responsible_id uuid,
  notes text,
  linked_course_id uuid,
  linked_trail_id uuid,
  auto_generated boolean NOT NULL DEFAULT true,
  generated_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  completed_evidence_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_tplans_user ON public.quality_training_plans(user_id, status);
CREATE INDEX idx_tplans_company ON public.quality_training_plans(company_id, status);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_training_plans TO authenticated;
GRANT ALL ON public.quality_training_plans TO service_role;
ALTER TABLE public.quality_training_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tp_select_self" ON public.quality_training_plans FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR responsible_id = auth.uid());
CREATE POLICY "tp_select_master" ON public.quality_training_plans FOR SELECT TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "tp_master_cud" ON public.quality_training_plans FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "tp_responsible_update" ON public.quality_training_plans FOR UPDATE TO authenticated
  USING (responsible_id = auth.uid()) WITH CHECK (responsible_id = auth.uid());

-- =========================================
-- updated_at triggers (reuse existing helper if exists)
-- =========================================
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname='quality_set_updated_at') THEN
    CREATE OR REPLACE FUNCTION public.quality_set_updated_at()
    RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $f$
    BEGIN NEW.updated_at = now(); RETURN NEW; END $f$;
  END IF;
END $$;

CREATE TRIGGER trg_comp_upd BEFORE UPDATE ON public.quality_competencies FOR EACH ROW EXECUTE FUNCTION public.quality_set_updated_at();
CREATE TRIGGER trg_req_upd BEFORE UPDATE ON public.quality_role_requirements FOR EACH ROW EXECUTE FUNCTION public.quality_set_updated_at();
CREATE TRIGGER trg_uc_upd BEFORE UPDATE ON public.quality_user_competencies FOR EACH ROW EXECUTE FUNCTION public.quality_set_updated_at();
CREATE TRIGGER trg_map_upd BEFORE UPDATE ON public.quality_competency_mappings FOR EACH ROW EXECUTE FUNCTION public.quality_set_updated_at();
CREATE TRIGGER trg_tp_upd BEFORE UPDATE ON public.quality_training_plans FOR EACH ROW EXECUTE FUNCTION public.quality_set_updated_at();

-- =========================================
-- FUNCTION: quality_recompute_user_competency
-- =========================================
CREATE OR REPLACE FUNCTION public.quality_recompute_user_competency(p_user_id uuid, p_competency_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_company uuid;
  v_max_int integer := 0;
  v_reason text := '';
  v_uc_id uuid;
  v_existing record;
  v_new_level public.quality_competency_level;
  v_new_manual boolean;
  m record;
  v_match boolean;
  v_label text;
  v_date timestamptz;
BEGIN
  SELECT company_id INTO v_company FROM public.profiles WHERE id = p_user_id;
  IF v_company IS NULL THEN RETURN; END IF;

  -- evaluate every mapping for this competency
  -- collect contributions in a temp table to rewrite evidences
  CREATE TEMP TABLE IF NOT EXISTS _tmp_ev (
    evidence_type public.quality_evidence_type,
    source_id uuid,
    source_label text,
    evidence_date timestamptz,
    level_contribution public.quality_competency_level
  ) ON COMMIT DROP;
  DELETE FROM _tmp_ev;

  FOR m IN
    SELECT * FROM public.quality_competency_mappings
    WHERE company_id = v_company AND competency_id = p_competency_id
  LOOP
    v_match := false; v_label := m.source_label; v_date := NULL;

    IF m.evidence_type = 'university_course' THEN
      SELECT true, COALESCE(c.title, m.source_label), e.completed_at
      INTO v_match, v_label, v_date
      FROM public.university_enrollments e
      LEFT JOIN public.university_courses c ON c.id = e.course_id
      WHERE e.user_id = p_user_id AND e.course_id = m.source_id AND e.status = 'completed'
      LIMIT 1;

    ELSIF m.evidence_type = 'university_trail' THEN
      -- all courses of the trail must be completed
      IF NOT EXISTS (
        SELECT 1 FROM public.university_trail_courses tc
        WHERE tc.trail_id = m.source_id
          AND NOT EXISTS (
            SELECT 1 FROM public.university_enrollments e
            WHERE e.user_id = p_user_id AND e.course_id = tc.course_id AND e.status = 'completed'
          )
      ) AND EXISTS (SELECT 1 FROM public.university_trail_courses WHERE trail_id = m.source_id) THEN
        SELECT title INTO v_label FROM public.university_trails WHERE id = m.source_id;
        v_match := true;
        v_date := now();
      END IF;

    ELSIF m.evidence_type = 'hr_certificate' THEN
      -- source_id stores the document_type string hash? we treat source_label as document_type
      SELECT true, COALESCE(td.certificate_name, td.document_type), td.uploaded_at
      INTO v_match, v_label, v_date
      FROM public.technician_documents td
      JOIN public.technicians t ON t.id = td.technician_id
      WHERE t.user_id = p_user_id
        AND td.document_type = m.source_label
        AND (td.valid_until IS NULL OR td.valid_until >= CURRENT_DATE)
      ORDER BY td.uploaded_at DESC
      LIMIT 1;

    ELSIF m.evidence_type = 'acknowledgement' THEN
      SELECT true, 'Ciência: '||COALESCE(qd.title,''), MAX(se.signed_at)
      INTO v_match, v_label, v_date
      FROM public.quality_signature_events se
      LEFT JOIN public.quality_documents qd ON qd.id = se.document_id
      WHERE se.user_id = p_user_id
        AND se.action = 'acknowledgment'
        AND se.document_id = m.source_id
      GROUP BY qd.title
      LIMIT 1;
    END IF;

    IF v_match THEN
      INSERT INTO _tmp_ev VALUES (m.evidence_type, m.source_id, v_label, COALESCE(v_date, now()), m.grants_level);
      IF public.quality_level_to_int(m.grants_level) > v_max_int THEN
        v_max_int := public.quality_level_to_int(m.grants_level);
      END IF;
    END IF;
  END LOOP;

  v_new_level := public.quality_int_to_level(v_max_int);
  v_reason := CASE WHEN v_max_int = 0 THEN 'Sem evidências'
                   ELSE 'Auto-sugerido por '||(SELECT count(*) FROM _tmp_ev)||' evidência(s)' END;

  -- upsert user competency
  SELECT * INTO v_existing FROM public.quality_user_competencies
    WHERE company_id = v_company AND user_id = p_user_id AND competency_id = p_competency_id;

  IF v_existing.id IS NULL THEN
    INSERT INTO public.quality_user_competencies (
      company_id, user_id, competency_id, current_level, manual_override,
      auto_suggested_level, auto_suggestion_reason, last_assessed_at
    ) VALUES (
      v_company, p_user_id, p_competency_id, v_new_level, false,
      v_new_level, v_reason, now()
    ) RETURNING id INTO v_uc_id;
  ELSE
    v_uc_id := v_existing.id;
    IF v_existing.manual_override
       AND public.quality_level_to_int(v_existing.current_level) >= v_max_int THEN
      -- preserve manual
      UPDATE public.quality_user_competencies
        SET auto_suggested_level = v_new_level,
            auto_suggestion_reason = v_reason
        WHERE id = v_uc_id;
    ELSE
      UPDATE public.quality_user_competencies
        SET current_level = v_new_level,
            manual_override = false,
            auto_suggested_level = v_new_level,
            auto_suggestion_reason = v_reason,
            last_assessed_at = now()
        WHERE id = v_uc_id;
    END IF;
  END IF;

  -- rewrite evidences for this line
  DELETE FROM public.quality_competency_evidences WHERE user_competency_id = v_uc_id;
  INSERT INTO public.quality_competency_evidences
    (company_id, user_competency_id, evidence_type, source_id, source_label, evidence_date, level_contribution)
  SELECT v_company, v_uc_id, evidence_type, source_id, source_label, evidence_date, level_contribution
  FROM _tmp_ev;
END $$;

-- =========================================
-- FUNCTION: quality_recompute_user_competencies_all
-- =========================================
CREATE OR REPLACE FUNCTION public.quality_recompute_user_competencies_all(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r record; v_company uuid;
BEGIN
  SELECT company_id INTO v_company FROM public.profiles WHERE id = p_user_id;
  IF v_company IS NULL THEN RETURN; END IF;
  FOR r IN SELECT DISTINCT competency_id FROM public.quality_competency_mappings WHERE company_id = v_company
  LOOP
    PERFORM public.quality_recompute_user_competency(p_user_id, r.competency_id);
  END LOOP;
END $$;

-- =========================================
-- FUNCTION: quality_set_manual_level
-- =========================================
CREATE OR REPLACE FUNCTION public.quality_set_manual_level(
  p_user_id uuid, p_competency_id uuid,
  p_level public.quality_competency_level, p_notes text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_company uuid;
BEGIN
  IF NOT public.quality_is_master(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden_not_master';
  END IF;
  SELECT company_id INTO v_company FROM public.profiles WHERE id = p_user_id;
  IF v_company IS NULL THEN RAISE EXCEPTION 'invalid_user'; END IF;

  INSERT INTO public.quality_user_competencies
    (company_id, user_id, competency_id, current_level, manual_override,
     auto_suggested_level, last_assessed_at, assessed_by, assessment_notes)
  VALUES
    (v_company, p_user_id, p_competency_id, p_level, true,
     'none', now(), auth.uid(), p_notes)
  ON CONFLICT (company_id, user_id, competency_id) DO UPDATE
    SET current_level = EXCLUDED.current_level,
        manual_override = true,
        last_assessed_at = now(),
        assessed_by = auth.uid(),
        assessment_notes = COALESCE(EXCLUDED.assessment_notes, public.quality_user_competencies.assessment_notes);
END $$;

-- =========================================
-- FUNCTION: quality_accept_auto_suggestion
-- =========================================
CREATE OR REPLACE FUNCTION public.quality_accept_auto_suggestion(
  p_user_id uuid, p_competency_id uuid
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_company uuid; v_row record;
BEGIN
  IF NOT (public.quality_is_master(auth.uid()) OR auth.uid() = p_user_id) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  SELECT company_id INTO v_company FROM public.profiles WHERE id = p_user_id;
  SELECT * INTO v_row FROM public.quality_user_competencies
    WHERE company_id = v_company AND user_id = p_user_id AND competency_id = p_competency_id;
  IF v_row.id IS NULL THEN RAISE EXCEPTION 'no_row'; END IF;
  UPDATE public.quality_user_competencies
    SET current_level = auto_suggested_level,
        manual_override = false,
        assessed_by = auth.uid(),
        last_assessed_at = now(),
        assessment_notes = 'Aceito auto-sugestão por evidências'
    WHERE id = v_row.id;
END $$;

-- =========================================
-- FUNCTION: quality_generate_training_plans
-- =========================================
CREATE OR REPLACE FUNCTION public.quality_generate_training_plans(p_user_id uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_company uuid; v_role public.app_role; r record;
  v_count integer := 0; v_course uuid; v_trail uuid; v_plan_id uuid;
BEGIN
  SELECT company_id INTO v_company FROM public.profiles WHERE id = p_user_id;
  SELECT role INTO v_role FROM public.user_roles WHERE user_id = p_user_id LIMIT 1;
  IF v_company IS NULL OR v_role IS NULL THEN RETURN 0; END IF;

  FOR r IN
    SELECT req.competency_id, req.required_level,
           COALESCE(uc.current_level, 'none'::public.quality_competency_level) AS current_level
    FROM public.quality_role_requirements req
    LEFT JOIN public.quality_user_competencies uc
      ON uc.company_id = req.company_id
     AND uc.user_id = p_user_id
     AND uc.competency_id = req.competency_id
    WHERE req.company_id = v_company AND req.role = v_role
      AND public.quality_level_to_int(req.required_level) > public.quality_level_to_int(COALESCE(uc.current_level,'none'))
  LOOP
    -- skip if active plan already exists
    IF EXISTS (
      SELECT 1 FROM public.quality_training_plans
      WHERE user_id = p_user_id AND competency_id = r.competency_id
        AND status IN ('proposed','in_progress')
    ) THEN CONTINUE; END IF;

    v_course := NULL; v_trail := NULL;
    SELECT source_id INTO v_course FROM public.quality_competency_mappings
      WHERE company_id = v_company AND competency_id = r.competency_id
        AND evidence_type = 'university_course'
      ORDER BY public.quality_level_to_int(grants_level) DESC LIMIT 1;
    SELECT source_id INTO v_trail FROM public.quality_competency_mappings
      WHERE company_id = v_company AND competency_id = r.competency_id
        AND evidence_type = 'university_trail'
      ORDER BY public.quality_level_to_int(grants_level) DESC LIMIT 1;

    INSERT INTO public.quality_training_plans
      (company_id, user_id, competency_id, current_level, required_level, target_level,
       status, linked_course_id, linked_trail_id, auto_generated)
    VALUES
      (v_company, p_user_id, r.competency_id, r.current_level, r.required_level, r.required_level,
       'proposed', v_course, v_trail, true)
    RETURNING id INTO v_plan_id;

    INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id)
    VALUES (p_user_id, 'quality_alert', 'Novo plano de capacitação',
            'Foi gerado um plano de capacitação para fechar um gap na sua matriz de competências.',
            v_plan_id);
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END $$;

-- =========================================
-- TRIGGERS: auto-recompute
-- =========================================
CREATE OR REPLACE FUNCTION public.quality_trg_enrollment_recompute()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN PERFORM public.quality_recompute_user_competencies_all(NEW.user_id); RETURN NEW; END $$;

CREATE TRIGGER trg_qcompet_enroll_ins
  AFTER INSERT ON public.university_enrollments
  FOR EACH ROW WHEN (NEW.status = 'completed')
  EXECUTE FUNCTION public.quality_trg_enrollment_recompute();

CREATE TRIGGER trg_qcompet_enroll_upd
  AFTER UPDATE ON public.university_enrollments
  FOR EACH ROW WHEN (NEW.status = 'completed' AND OLD.status IS DISTINCT FROM 'completed')
  EXECUTE FUNCTION public.quality_trg_enrollment_recompute();

CREATE OR REPLACE FUNCTION public.quality_trg_signature_recompute()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN PERFORM public.quality_recompute_user_competencies_all(NEW.user_id); RETURN NEW; END $$;

CREATE TRIGGER trg_qcompet_sig_ins
  AFTER INSERT ON public.quality_signature_events
  FOR EACH ROW WHEN (NEW.action = 'acknowledgment')
  EXECUTE FUNCTION public.quality_trg_signature_recompute();

CREATE OR REPLACE FUNCTION public.quality_trg_techdoc_recompute()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_user uuid;
BEGIN
  SELECT user_id INTO v_user FROM public.technicians WHERE id = NEW.technician_id;
  IF v_user IS NOT NULL THEN PERFORM public.quality_recompute_user_competencies_all(v_user); END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_qcompet_techdoc
  AFTER INSERT OR UPDATE ON public.technician_documents
  FOR EACH ROW EXECUTE FUNCTION public.quality_trg_techdoc_recompute();

-- =========================================
-- VIEW: quality_competency_matrix_v
-- =========================================
CREATE OR REPLACE VIEW public.quality_competency_matrix_v
WITH (security_invoker = true) AS
SELECT
  p.company_id,
  p.id AS user_id,
  p.full_name,
  ur.role,
  c.id AS competency_id,
  c.name AS competency_name,
  c.category,
  req.required_level,
  COALESCE(uc.current_level, 'none'::public.quality_competency_level) AS current_level,
  COALESCE(uc.manual_override, false) AS manual_override,
  COALESCE(uc.auto_suggested_level, 'none'::public.quality_competency_level) AS auto_suggested_level,
  GREATEST(0, public.quality_level_to_int(req.required_level) - public.quality_level_to_int(COALESCE(uc.current_level,'none'))) AS gap,
  req.is_mandatory
FROM public.profiles p
JOIN public.user_roles ur ON ur.user_id = p.id
JOIN public.quality_role_requirements req
  ON req.company_id = p.company_id AND req.role = ur.role
JOIN public.quality_competencies c ON c.id = req.competency_id AND c.active = true
LEFT JOIN public.quality_user_competencies uc
  ON uc.company_id = p.company_id
 AND uc.user_id = p.id
 AND uc.competency_id = req.competency_id;

GRANT SELECT ON public.quality_competency_matrix_v TO authenticated;
