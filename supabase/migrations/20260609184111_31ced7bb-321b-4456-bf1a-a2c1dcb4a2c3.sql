
-- ============================================================
-- Parte 1: enforcement de permissões + log de negação
-- ============================================================

-- 1.1 Novos labels no enum de ações (auditoria)
ALTER TYPE public.quality_access_action ADD VALUE IF NOT EXISTS 'denied_print';
ALTER TYPE public.quality_access_action ADD VALUE IF NOT EXISTS 'denied_download';

-- 1.2 RPC consolidando permissões efetivas para um documento+usuário
-- Default permissivo (Opção A): documento sem registro libera para todos.
-- Director/super_admin sempre liberados.
CREATE OR REPLACE FUNCTION public.quality_doc_user_perms(_document_id uuid)
RETURNS TABLE(can_view boolean, can_print boolean, can_download boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _uid uuid := auth.uid();
  _doc_company uuid;
  _is_master boolean := false;
  _has_record boolean := false;
  _v boolean := true;
  _p boolean := true;
  _d boolean := true;
BEGIN
  IF _uid IS NULL THEN
    RETURN QUERY SELECT false, false, false;
    RETURN;
  END IF;

  SELECT company_id INTO _doc_company FROM public.quality_documents WHERE id = _document_id;
  IF _doc_company IS NULL THEN
    RETURN QUERY SELECT false, false, false;
    RETURN;
  END IF;

  -- Master / Diretoria: sempre liberado
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = _uid
      AND ur.role IN ('director','super_admin','admin')
  ) INTO _is_master;

  IF _is_master THEN
    RETURN QUERY SELECT true, true, true;
    RETURN;
  END IF;

  -- Existe regra explícita para este usuário neste documento?
  SELECT TRUE,
         bool_or(qdp.can_view),
         bool_or(qdp.can_print),
         bool_or(qdp.can_download)
    INTO _has_record, _v, _p, _d
  FROM public.quality_document_permissions qdp
  WHERE qdp.document_id = _document_id
    AND qdp.user_id = _uid;

  IF _has_record THEN
    RETURN QUERY SELECT COALESCE(_v,false), COALESCE(_p,false), COALESCE(_d,false);
    RETURN;
  END IF;

  -- Sem regra explícita -> liberar (Opção A, preserva comportamento atual)
  RETURN QUERY SELECT true, true, true;
END;
$$;

GRANT EXECUTE ON FUNCTION public.quality_doc_user_perms(uuid) TO authenticated;


-- ============================================================
-- Parte 2: expiração automática de normas
-- ============================================================

-- 2.1 Índice obrigatório em valid_until (consulta da VIEW + cron)
CREATE INDEX IF NOT EXISTS idx_quality_reference_norms_valid_until
  ON public.quality_reference_norms (valid_until)
  WHERE valid_until IS NOT NULL;

-- 2.2 Coluna de idempotência do aviso "vence em breve"
ALTER TABLE public.quality_reference_norms
  ADD COLUMN IF NOT EXISTS expiry_warning_sent_at timestamptz NULL;

-- 2.3 VIEW com status efetivo (security_invoker herda RLS da tabela)
CREATE OR REPLACE VIEW public.quality_reference_norms_status
WITH (security_invoker = on)
AS
SELECT
  n.*,
  CASE
    WHEN n.is_active = false THEN 'inativa'
    WHEN n.valid_until IS NOT NULL AND n.valid_until < CURRENT_DATE THEN 'vencida'
    WHEN n.valid_until IS NOT NULL AND n.valid_until <= (CURRENT_DATE + INTERVAL '30 days') THEN 'vence_em_breve'
    ELSE 'vigente'
  END AS effective_status
FROM public.quality_reference_norms n;

GRANT SELECT ON public.quality_reference_norms_status TO authenticated;

-- 2.4 Função de tick (idempotente). Executada pelo pg_cron diariamente.
CREATE OR REPLACE FUNCTION public.quality_norms_expire_tick()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _norm RECORD;
  _recipient RECORD;
  _days INT;
BEGIN
  -- A) Marcar normas vencidas como inativas e notificar
  FOR _norm IN
    SELECT id, company_id, code, title, valid_until
    FROM public.quality_reference_norms
    WHERE is_active = true
      AND valid_until IS NOT NULL
      AND valid_until < CURRENT_DATE
  LOOP
    UPDATE public.quality_reference_norms
      SET is_active = false, updated_at = now()
      WHERE id = _norm.id;

    FOR _recipient IN
      SELECT DISTINCT p.id AS user_id
      FROM public.profiles p
      JOIN public.user_roles ur ON ur.user_id = p.id
      WHERE p.company_id = _norm.company_id
        AND ur.role IN ('director','coordinator')
    LOOP
      INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id, read)
      VALUES (
        _recipient.user_id,
        'quality_alert',
        'Norma vencida: ' || _norm.code,
        _norm.title || ' venceu em ' || to_char(_norm.valid_until,'DD/MM/YYYY') || ' e foi marcada como inativa.',
        _norm.id,
        false
      );
    END LOOP;
  END LOOP;

  -- B) Avisos de "vence em breve" (≤30 dias) ainda não enviados
  FOR _norm IN
    SELECT id, company_id, code, title, valid_until
    FROM public.quality_reference_norms
    WHERE is_active = true
      AND expiry_warning_sent_at IS NULL
      AND valid_until IS NOT NULL
      AND valid_until >= CURRENT_DATE
      AND valid_until <= (CURRENT_DATE + INTERVAL '30 days')
  LOOP
    _days := (_norm.valid_until - CURRENT_DATE);

    FOR _recipient IN
      SELECT DISTINCT p.id AS user_id
      FROM public.profiles p
      JOIN public.user_roles ur ON ur.user_id = p.id
      WHERE p.company_id = _norm.company_id
        AND ur.role IN ('director','coordinator')
    LOOP
      INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id, read)
      VALUES (
        _recipient.user_id,
        'quality_alert',
        'Norma próxima do vencimento: ' || _norm.code,
        _norm.title || ' vence em ' || _days || ' dia(s) (' || to_char(_norm.valid_until,'DD/MM/YYYY') || ').',
        _norm.id,
        false
      );
    END LOOP;

    UPDATE public.quality_reference_norms
      SET expiry_warning_sent_at = now()
      WHERE id = _norm.id;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.quality_norms_expire_tick() TO service_role;
