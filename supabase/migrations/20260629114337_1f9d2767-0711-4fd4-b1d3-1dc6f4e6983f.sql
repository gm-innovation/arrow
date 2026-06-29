
-- 1) Add obsolete metadata columns
ALTER TABLE public.quality_documents
  ADD COLUMN IF NOT EXISTS obsolete_by uuid,
  ADD COLUMN IF NOT EXISTS obsolete_reason text;

-- 2) Status transition audit log
CREATE TABLE IF NOT EXISTS public.quality_document_status_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  from_status public.quality_document_status,
  to_status public.quality_document_status NOT NULL,
  reason text,
  changed_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT ON public.quality_document_status_log TO authenticated;
GRANT ALL ON public.quality_document_status_log TO service_role;

ALTER TABLE public.quality_document_status_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qd_status_log_read"
  ON public.quality_document_status_log
  FOR SELECT
  TO authenticated
  USING (public.quality_doc_user_can_view(document_id, auth.uid()));

CREATE POLICY "qd_status_log_insert"
  ON public.quality_document_status_log
  FOR INSERT
  TO authenticated
  WITH CHECK (changed_by = auth.uid());

CREATE INDEX IF NOT EXISTS idx_qd_status_log_document ON public.quality_document_status_log(document_id, created_at DESC);

-- 3) Trigger to capture status transitions automatically
CREATE OR REPLACE FUNCTION public.quality_documents_log_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO public.quality_document_status_log (
      document_id, from_status, to_status, reason, changed_by
    ) VALUES (
      NEW.id,
      OLD.status,
      NEW.status,
      CASE WHEN NEW.status = 'obsolete' THEN NEW.obsolete_reason ELSE NULL END,
      COALESCE(auth.uid(), NEW.obsolete_by)
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_quality_documents_log_status ON public.quality_documents;
CREATE TRIGGER trg_quality_documents_log_status
  AFTER UPDATE OF status ON public.quality_documents
  FOR EACH ROW
  EXECUTE FUNCTION public.quality_documents_log_status_change();
