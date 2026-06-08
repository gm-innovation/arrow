
-- ============================================================
-- ONDA 4A — Referência Normativa, Termos, Partes Interessadas, Melhorias
-- + REFINO R3 — Processo ↔ Documento vigente com histórico
-- ============================================================

-- 1) REFERÊNCIA NORMATIVA — extensão
ALTER TABLE public.quality_reference_norms
  ADD COLUMN IF NOT EXISTS revision text,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'vigente'
    CHECK (status IN ('vigente','substituida','cancelada','rascunho')),
  ADD COLUMN IF NOT EXISTS responsible_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS superseded_by_id uuid REFERENCES public.quality_reference_norms(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS attachment_url text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS review_frequency_months integer,
  ADD COLUMN IF NOT EXISTS last_reviewed_at timestamptz,
  ADD COLUMN IF NOT EXISTS next_review_due_at date;

-- 2) TERMOS — extensão
ALTER TABLE public.quality_terms
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'vigente'
    CHECK (status IN ('rascunho','vigente','obsoleto')),
  ADD COLUMN IF NOT EXISTS responsible_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS review_frequency_months integer,
  ADD COLUMN IF NOT EXISTS last_reviewed_at timestamptz,
  ADD COLUMN IF NOT EXISTS next_review_due_at date;

-- 3) PARTES INTERESSADAS — status da tratativa
ALTER TABLE public.quality_interested_parties
  ADD COLUMN IF NOT EXISTS treatment_status text NOT NULL DEFAULT 'pendente'
    CHECK (treatment_status IN ('pendente','em_andamento','atendida','nao_aplicavel'));

-- 4) MELHORIAS — origem polimórfica + eficácia
ALTER TABLE public.quality_improvements_manual
  ADD COLUMN IF NOT EXISTS origin_type text NOT NULL DEFAULT 'manual'
    CHECK (origin_type IN ('manual','ncr','audit','satisfaction','risk','deviation','critical_review')),
  ADD COLUMN IF NOT EXISTS origin_id uuid,
  ADD COLUMN IF NOT EXISTS effectiveness_status text NOT NULL DEFAULT 'pendente'
    CHECK (effectiveness_status IN ('pendente','eficaz','ineficaz','nao_aplicavel')),
  ADD COLUMN IF NOT EXISTS effectiveness_verified_at timestamptz,
  ADD COLUMN IF NOT EXISTS effectiveness_verified_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS effectiveness_notes text;

CREATE INDEX IF NOT EXISTS idx_qim_origin ON public.quality_improvements_manual(origin_type, origin_id);

-- ============================================================
-- REFINO R3 — Processo vigente exige documento publicado e não vencido
-- ============================================================

-- 5) Flag de aplicação da regra em quality_settings
ALTER TABLE public.quality_settings
  ADD COLUMN IF NOT EXISTS require_active_process_document boolean NOT NULL DEFAULT true;

-- 6) Trigger de validação
CREATE OR REPLACE FUNCTION public.quality_validate_process_active_document()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_require boolean;
  v_doc_status text;
  v_doc_expires date;
BEGIN
  IF NEW.status <> 'active' THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(require_active_process_document, true)
    INTO v_require
    FROM public.quality_settings
   WHERE company_id = NEW.company_id;

  IF v_require IS DISTINCT FROM true THEN
    RETURN NEW;
  END IF;

  IF NEW.current_document_id IS NULL THEN
    RAISE EXCEPTION 'Processo não pode ficar ativo sem documento vinculado (current_document_id).';
  END IF;

  SELECT status::text, expires_at
    INTO v_doc_status, v_doc_expires
    FROM public.quality_documents
   WHERE id = NEW.current_document_id;

  IF v_doc_status IS NULL THEN
    RAISE EXCEPTION 'Documento vinculado ao processo não existe.';
  END IF;

  IF v_doc_status NOT IN ('published','approved') THEN
    RAISE EXCEPTION 'Processo não pode ficar ativo: documento vinculado está com status %.', v_doc_status;
  END IF;

  IF v_doc_expires IS NOT NULL AND v_doc_expires < CURRENT_DATE THEN
    RAISE EXCEPTION 'Processo não pode ficar ativo: documento vinculado venceu em %.', v_doc_expires;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_qproc_validate_active_doc ON public.quality_processes;
CREATE TRIGGER trg_qproc_validate_active_doc
  BEFORE INSERT OR UPDATE OF status, current_document_id ON public.quality_processes
  FOR EACH ROW EXECUTE FUNCTION public.quality_validate_process_active_document();

-- 7) Histórico de troca de current_document_id
CREATE TABLE IF NOT EXISTS public.quality_process_document_history (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  process_id uuid NOT NULL REFERENCES public.quality_processes(id) ON DELETE CASCADE,
  previous_document_id uuid REFERENCES public.quality_documents(id) ON DELETE SET NULL,
  new_document_id uuid REFERENCES public.quality_documents(id) ON DELETE SET NULL,
  changed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reason text,
  changed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_qpdh_process ON public.quality_process_document_history(process_id, changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_qpdh_company ON public.quality_process_document_history(company_id);

GRANT SELECT, INSERT ON public.quality_process_document_history TO authenticated;
GRANT ALL ON public.quality_process_document_history TO service_role;

ALTER TABLE public.quality_process_document_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS qpdh_select ON public.quality_process_document_history;
CREATE POLICY qpdh_select ON public.quality_process_document_history
  FOR SELECT TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'qualidade'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );

DROP POLICY IF EXISTS qpdh_insert ON public.quality_process_document_history;
CREATE POLICY qpdh_insert ON public.quality_process_document_history
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'qualidade'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );

-- 8) Trigger que grava histórico automaticamente
CREATE OR REPLACE FUNCTION public.quality_log_process_document_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.current_document_id IS NOT NULL THEN
      INSERT INTO public.quality_process_document_history
        (company_id, process_id, previous_document_id, new_document_id, changed_by, reason)
      VALUES
        (NEW.company_id, NEW.id, NULL, NEW.current_document_id, auth.uid(), 'created');
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.current_document_id IS DISTINCT FROM OLD.current_document_id THEN
    INSERT INTO public.quality_process_document_history
      (company_id, process_id, previous_document_id, new_document_id, changed_by, reason)
    VALUES
      (NEW.company_id, NEW.id, OLD.current_document_id, NEW.current_document_id, auth.uid(), NULL);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_qproc_log_doc_change ON public.quality_processes;
CREATE TRIGGER trg_qproc_log_doc_change
  AFTER INSERT OR UPDATE OF current_document_id ON public.quality_processes
  FOR EACH ROW EXECUTE FUNCTION public.quality_log_process_document_change();
