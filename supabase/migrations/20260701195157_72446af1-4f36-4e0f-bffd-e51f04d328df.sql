
CREATE OR REPLACE FUNCTION public.sync_central_approval_document_reject()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'rejected' AND OLD.status = 'pending' AND NEW.entity_type IN ('document','company_document') THEN
    IF NEW.entity_type = 'document' THEN
      UPDATE public.quality_document_versions
        SET status = 'draft'
        WHERE document_id = NEW.entity_id
          AND status = 'pending_approval';
      UPDATE public.quality_documents
        SET status = 'draft'
        WHERE id = NEW.entity_id
          AND status = 'pending_approval';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_central_approval_document_reject ON public.quality_central_approvals;
CREATE TRIGGER trg_sync_central_approval_document_reject
AFTER UPDATE ON public.quality_central_approvals
FOR EACH ROW
EXECUTE FUNCTION public.sync_central_approval_document_reject();
