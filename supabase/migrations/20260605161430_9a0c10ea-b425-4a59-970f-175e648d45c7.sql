
ALTER TABLE public.quality_documents
  ADD COLUMN IF NOT EXISTS requires_strong_acknowledgement boolean NOT NULL DEFAULT false;

CREATE TABLE public.quality_document_acknowledgement_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  version_id uuid NOT NULL REFERENCES public.quality_document_versions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  due_date date NULL,
  status text NOT NULL DEFAULT 'pending',
  acknowledged_at timestamptz NULL,
  signature_event_id uuid NULL REFERENCES public.quality_signature_events(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT quality_doc_ack_unique UNIQUE (document_id, version_id, user_id),
  CONSTRAINT quality_doc_ack_status_chk CHECK (status IN ('pending','acknowledged','cancelled'))
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_document_acknowledgement_assignments TO authenticated;
GRANT ALL ON public.quality_document_acknowledgement_assignments TO service_role;

ALTER TABLE public.quality_document_acknowledgement_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ack_select_own_or_master"
ON public.quality_document_acknowledgement_assignments
FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.quality_documents d
    JOIN public.profiles p ON p.company_id = d.company_id
    WHERE d.id = quality_document_acknowledgement_assignments.document_id
      AND p.id = auth.uid()
      AND (
        public.has_role(auth.uid(), 'qualidade'::app_role)
        OR public.has_role(auth.uid(), 'coordinator'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
        OR public.has_role(auth.uid(), 'super_admin'::app_role)
      )
  )
);

CREATE POLICY "ack_insert_master"
ON public.quality_document_acknowledgement_assignments
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.quality_documents d
    JOIN public.profiles p ON p.company_id = d.company_id
    WHERE d.id = document_id
      AND p.id = auth.uid()
      AND (
        public.has_role(auth.uid(), 'qualidade'::app_role)
        OR public.has_role(auth.uid(), 'coordinator'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
        OR public.has_role(auth.uid(), 'super_admin'::app_role)
      )
  )
);

CREATE POLICY "ack_update_master_or_self"
ON public.quality_document_acknowledgement_assignments
FOR UPDATE TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.quality_documents d
    JOIN public.profiles p ON p.company_id = d.company_id
    WHERE d.id = quality_document_acknowledgement_assignments.document_id
      AND p.id = auth.uid()
      AND (
        public.has_role(auth.uid(), 'qualidade'::app_role)
        OR public.has_role(auth.uid(), 'coordinator'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
        OR public.has_role(auth.uid(), 'super_admin'::app_role)
      )
  )
);

CREATE POLICY "ack_delete_master"
ON public.quality_document_acknowledgement_assignments
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.quality_documents d
    JOIN public.profiles p ON p.company_id = d.company_id
    WHERE d.id = quality_document_acknowledgement_assignments.document_id
      AND p.id = auth.uid()
      AND (
        public.has_role(auth.uid(), 'qualidade'::app_role)
        OR public.has_role(auth.uid(), 'coordinator'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
        OR public.has_role(auth.uid(), 'super_admin'::app_role)
      )
  )
);

CREATE TRIGGER trg_quality_doc_ack_updated_at
BEFORE UPDATE ON public.quality_document_acknowledgement_assignments
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.notify_quality_ack_assignment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_doc_code text;
  v_doc_title text;
BEGIN
  SELECT code, title INTO v_doc_code, v_doc_title
    FROM public.quality_documents
   WHERE id = NEW.document_id;

  INSERT INTO public.notifications (user_id, title, message, type, link, metadata)
  VALUES (
    NEW.user_id,
    'Novo documento para sua ciência',
    coalesce(v_doc_code,'') || ' — ' || coalesce(v_doc_title,''),
    'quality_acknowledgement',
    '/quality/my-acknowledgements',
    jsonb_build_object(
      'document_id', NEW.document_id,
      'version_id', NEW.version_id,
      'assignment_id', NEW.id,
      'due_date', NEW.due_date
    )
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_quality_ack_notify_assign
AFTER INSERT ON public.quality_document_acknowledgement_assignments
FOR EACH ROW
WHEN (NEW.status = 'pending')
EXECUTE FUNCTION public.notify_quality_ack_assignment();

CREATE OR REPLACE FUNCTION public.quality_register_acknowledgement(
  p_assignment_id uuid,
  p_ip text DEFAULT NULL,
  p_user_agent text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_assignment public.quality_document_acknowledgement_assignments%ROWTYPE;
  v_doc public.quality_documents%ROWTYPE;
  v_signature public.quality_signatures%ROWTYPE;
  v_event_id uuid;
  v_full_name text;
  v_role_label text;
  v_signature_path text := NULL;
  v_pending_remaining int;
  v_master_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO v_assignment
    FROM public.quality_document_acknowledgement_assignments
   WHERE id = p_assignment_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'assignment_not_found';
  END IF;

  IF v_assignment.user_id <> v_uid THEN
    RAISE EXCEPTION 'forbidden_not_assignee';
  END IF;

  IF v_assignment.status = 'acknowledged' THEN
    RETURN v_assignment.signature_event_id;
  END IF;

  IF v_assignment.status = 'cancelled' THEN
    RAISE EXCEPTION 'assignment_cancelled';
  END IF;

  SELECT * INTO v_doc FROM public.quality_documents WHERE id = v_assignment.document_id;

  IF v_doc.requires_strong_acknowledgement THEN
    SELECT * INTO v_signature
      FROM public.quality_signatures
     WHERE user_id = v_uid AND is_active = true
     ORDER BY created_at DESC
     LIMIT 1;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'signature_required_but_missing';
    END IF;
    v_signature_path := v_signature.signature_image_path;
  END IF;

  SELECT full_name INTO v_full_name FROM public.profiles WHERE id = v_uid;
  SELECT string_agg(role::text, ',') INTO v_role_label FROM public.user_roles WHERE user_id = v_uid;

  INSERT INTO public.quality_signature_events (
    document_id, version_id, user_id, action,
    signature_image_path, full_name_snapshot, role_snapshot,
    signed_at, ip_address, user_agent, notes
  ) VALUES (
    v_assignment.document_id, v_assignment.version_id, v_uid, 'acknowledgment'::quality_signature_action,
    v_signature_path, v_full_name, v_role_label,
    now(), p_ip, p_user_agent,
    CASE WHEN v_doc.requires_strong_acknowledgement
         THEN 'Ciência registrada com assinatura eletrônica'
         ELSE 'Ciência registrada (Li e estou ciente)'
    END
  ) RETURNING id INTO v_event_id;

  UPDATE public.quality_document_acknowledgement_assignments
     SET status = 'acknowledged',
         acknowledged_at = now(),
         signature_event_id = v_event_id,
         updated_at = now()
   WHERE id = p_assignment_id;

  SELECT count(*) INTO v_pending_remaining
    FROM public.quality_document_acknowledgement_assignments
   WHERE document_id = v_assignment.document_id
     AND version_id = v_assignment.version_id
     AND status = 'pending';

  IF v_pending_remaining = 0 THEN
    FOR v_master_id IN
      SELECT DISTINCT assigned_by
        FROM public.quality_document_acknowledgement_assignments
       WHERE document_id = v_assignment.document_id
         AND version_id = v_assignment.version_id
         AND assigned_by IS NOT NULL
    LOOP
      INSERT INTO public.notifications (user_id, title, message, type, link, metadata)
      VALUES (
        v_master_id,
        'Conscientização 100% concluída',
        coalesce(v_doc.code,'') || ' — ' || coalesce(v_doc.title,'') || ' — todos os destinatários deram ciência',
        'quality_acknowledgement_complete',
        '/quality/documents/' || v_doc.id,
        jsonb_build_object('document_id', v_doc.id, 'version_id', v_assignment.version_id)
      );
    END LOOP;
  END IF;

  RETURN v_event_id;
END;
$$;

REVOKE ALL ON FUNCTION public.quality_register_acknowledgement(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.quality_register_acknowledgement(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.quality_clone_acks_on_publish()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prev_version_id uuid;
BEGIN
  IF NEW.status <> 'published' THEN RETURN NEW; END IF;
  IF OLD.status = 'published' THEN RETURN NEW; END IF;

  SELECT id INTO v_prev_version_id
    FROM public.quality_document_versions
   WHERE document_id = NEW.document_id
     AND id <> NEW.id
     AND status = 'published'
   ORDER BY approved_at DESC NULLS LAST, issued_at DESC NULLS LAST
   LIMIT 1;

  IF v_prev_version_id IS NULL THEN RETURN NEW; END IF;

  INSERT INTO public.quality_document_acknowledgement_assignments
    (document_id, version_id, user_id, assigned_by, due_date, status)
  SELECT a.document_id, NEW.id, a.user_id, a.assigned_by, a.due_date, 'pending'
    FROM public.quality_document_acknowledgement_assignments a
   WHERE a.document_id = NEW.document_id
     AND a.version_id = v_prev_version_id
     AND a.status IN ('pending','acknowledged')
  ON CONFLICT (document_id, version_id, user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_quality_clone_acks_on_publish
AFTER UPDATE OF status ON public.quality_document_versions
FOR EACH ROW
EXECUTE FUNCTION public.quality_clone_acks_on_publish();

CREATE OR REPLACE VIEW public.quality_acknowledgements_v
WITH (security_invoker = true) AS
SELECT
  a.id AS assignment_id,
  a.document_id, a.version_id, a.user_id, a.assigned_by, a.assigned_at,
  a.due_date, a.status, a.acknowledged_at, a.signature_event_id,
  d.company_id, d.code AS document_code, d.title AS document_title,
  d.requires_strong_acknowledgement,
  v.revision_label, v.status AS version_status
FROM public.quality_document_acknowledgement_assignments a
JOIN public.quality_documents d ON d.id = a.document_id
JOIN public.quality_document_versions v ON v.id = a.version_id;

GRANT SELECT ON public.quality_acknowledgements_v TO authenticated;
