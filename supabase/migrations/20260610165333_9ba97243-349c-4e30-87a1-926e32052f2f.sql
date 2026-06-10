
-- Add new notification type for HR document review outcomes
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'document_review';

-- =====================================================================
-- Trigger: safe audit fill on review status transition
-- Only acts on pending_review -> approved/rejected (legitimate transitions)
-- Never overwrites values that came pre-populated from the client
-- =====================================================================
CREATE OR REPLACE FUNCTION public.hr_employee_documents_review_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.review_status IN ('approved', 'rejected')
     AND COALESCE(OLD.review_status, '') = 'pending_review'
     AND NEW.review_status IS DISTINCT FROM OLD.review_status
  THEN
    IF NEW.reviewed_by IS NULL THEN
      NEW.reviewed_by := auth.uid();
    END IF;
    IF NEW.reviewed_at IS NULL THEN
      NEW.reviewed_at := now();
    END IF;

    -- Rejection releases the unique slot, preserving history
    IF NEW.review_status = 'rejected' THEN
      NEW.is_current := false;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_hr_employee_documents_review_audit ON public.hr_employee_documents;
CREATE TRIGGER trg_hr_employee_documents_review_audit
BEFORE UPDATE ON public.hr_employee_documents
FOR EACH ROW
EXECUTE FUNCTION public.hr_employee_documents_review_audit();

-- =====================================================================
-- Trigger: notify the employee when a review decision is recorded
-- =====================================================================
CREATE OR REPLACE FUNCTION public.hr_employee_documents_notify_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_catalog_name text;
  v_title text;
  v_message text;
BEGIN
  IF NEW.review_status IS DISTINCT FROM OLD.review_status
     AND NEW.review_status IN ('approved', 'rejected')
     AND COALESCE(OLD.review_status, '') = 'pending_review'
  THEN
    SELECT name INTO v_catalog_name FROM public.hr_document_catalog WHERE id = NEW.catalog_id;

    IF NEW.review_status = 'approved' THEN
      v_title := 'Documento aprovado';
      v_message := COALESCE(v_catalog_name, 'Seu documento') || ' foi aprovado pelo RH.';
    ELSE
      v_title := 'Documento rejeitado';
      v_message := COALESCE(v_catalog_name, 'Seu documento') || ' foi rejeitado.'
                || CASE WHEN NEW.rejection_reason IS NOT NULL AND length(NEW.rejection_reason) > 0
                        THEN ' Motivo: ' || NEW.rejection_reason ELSE '' END
                || ' Reenvie em Meus Documentos.';
    END IF;

    INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id, read)
    VALUES (NEW.employee_id, 'document_review', v_title, v_message, NEW.id, false);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_hr_employee_documents_notify_review ON public.hr_employee_documents;
CREATE TRIGGER trg_hr_employee_documents_notify_review
AFTER UPDATE ON public.hr_employee_documents
FOR EACH ROW
EXECUTE FUNCTION public.hr_employee_documents_notify_review();

-- =====================================================================
-- RPC: fila de revisão de documentos (RH/Diretoria/Super Admin)
-- =====================================================================
CREATE OR REPLACE FUNCTION public.hr_pending_reviews(_company_id uuid)
RETURNS TABLE (
  document_id uuid,
  employee_id uuid,
  employee_name text,
  employee_position text,
  catalog_id uuid,
  catalog_name text,
  catalog_category text,
  file_name text,
  file_path text,
  uploaded_at timestamptz,
  uploaded_by uuid,
  uploader_name text,
  issue_date date,
  notes text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT (
    has_role(auth.uid(), 'hr'::app_role)
    OR has_role(auth.uid(), 'director'::app_role)
    OR has_role(auth.uid(), 'super_admin'::app_role)
  ) THEN
    RAISE EXCEPTION 'Acesso negado';
  END IF;

  RETURN QUERY
  SELECT
    d.id,
    d.employee_id,
    p.full_name,
    p.position,
    d.catalog_id,
    c.name,
    c.category,
    d.file_name,
    d.file_path,
    d.uploaded_at,
    d.uploaded_by,
    up.full_name,
    d.issue_date,
    d.notes
  FROM public.hr_employee_documents d
  JOIN public.profiles p ON p.id = d.employee_id
  JOIN public.hr_document_catalog c ON c.id = d.catalog_id
  LEFT JOIN public.profiles up ON up.id = d.uploaded_by
  WHERE d.company_id = _company_id
    AND d.review_status = 'pending_review'
    AND d.is_current = true
  ORDER BY d.uploaded_at ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.hr_pending_reviews(uuid) TO authenticated;
