CREATE OR REPLACE FUNCTION public.quality_seed_safety_document_types(p_company_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_allowed boolean;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  SELECT (
    public.has_role(v_uid, 'super_admin'::app_role)
    OR public.has_role(v_uid, 'director'::app_role)
    OR public.has_role(v_uid, 'coordinator'::app_role)
    OR public.has_role(v_uid, 'qualidade'::app_role)
  ) INTO v_allowed;

  IF NOT v_allowed THEN
    RAISE EXCEPTION 'insufficient_privileges';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_uid AND company_id = p_company_id
  ) AND NOT public.has_role(v_uid, 'super_admin'::app_role) THEN
    RAISE EXCEPTION 'company_mismatch';
  END IF;

  INSERT INTO public.quality_document_types
    (company_id, code_prefix, name, description, default_review_interval_months, is_active)
  VALUES
    (p_company_id, 'PCMSO',     'Programa de Controle Médico de Saúde Ocupacional', 'NR-07 — PCMSO',                12, true),
    (p_company_id, 'PGR',       'Programa de Gerenciamento de Riscos',                'NR-01 — PGR (GRO)',            24, true),
    (p_company_id, 'LTCAT',     'Laudo Técnico das Condições Ambientais do Trabalho', 'Insalubridade/Aposentadoria',  12, true),
    (p_company_id, 'NR01',      'Documentação NR-01 (GRO)',                           'Inventário de Riscos / GRO',   12, true),
    (p_company_id, 'FICHA_EPI', 'Ficha de Controle de EPI (modelo)',                   'Modelo institucional de FEPI', 12, true),
    (p_company_id, 'ASO',       'Atestado de Saúde Ocupacional (modelo)',              'Modelo de ASO',                12, true),
    (p_company_id, 'LAUDO_SST', 'Outros Laudos de S&S',                                'Laudos diversos NR/SST',       12, true)
  ON CONFLICT (company_id, code_prefix) DO NOTHING;
END;
$$;