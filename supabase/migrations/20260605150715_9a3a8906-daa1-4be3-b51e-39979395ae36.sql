DO $$ BEGIN
  CREATE TYPE public.complaint_kind AS ENUM ('complaint','suggestion');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.quality_complaints
  ADD COLUMN IF NOT EXISTS kind public.complaint_kind NOT NULL DEFAULT 'complaint';

CREATE INDEX IF NOT EXISTS idx_qc_kind ON public.quality_complaints(kind);

CREATE OR REPLACE FUNCTION public.quality_complaint_to_ncr(p_complaint_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_c public.quality_complaints%ROWTYPE;
  v_ncr_id uuid;
BEGIN
  SELECT * INTO v_c FROM public.quality_complaints WHERE id = p_complaint_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reclamação não encontrada' USING ERRCODE='22023'; END IF;
  IF v_c.kind = 'suggestion' THEN
    RAISE EXCEPTION 'Sugestões não podem ser convertidas em NCR' USING ERRCODE='22023';
  END IF;
  IF v_c.linked_ncr_id IS NOT NULL THEN
    RETURN v_c.linked_ncr_id;
  END IF;

  INSERT INTO public.quality_ncrs (
    company_id, title, description, source, status, severity, created_by
  ) VALUES (
    v_c.company_id,
    'Reclamação #' || v_c.complaint_number || ' — ' || v_c.title,
    v_c.description,
    'customer_complaint',
    'open',
    'medium',
    auth.uid()
  ) RETURNING id INTO v_ncr_id;

  UPDATE public.quality_complaints
    SET linked_ncr_id = v_ncr_id, status = 'under_analysis', updated_at = now()
    WHERE id = p_complaint_id;

  RETURN v_ncr_id;
END $$;