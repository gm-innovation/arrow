
DROP FUNCTION IF EXISTS public.quality_get_invite_public(uuid);

CREATE FUNCTION public.quality_get_invite_public(p_token uuid)
RETURNS TABLE (
  invite_id uuid,
  campaign_id uuid,
  campaign_name text,
  campaign_status text,
  already_responded boolean,
  collects_nps boolean,
  collects_csat boolean,
  collects_ces boolean
)
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT i.id, c.id, c.name, c.status::text, (i.responded_at IS NOT NULL),
         c.collects_nps, c.collects_csat, c.collects_ces
  FROM public.quality_satisfaction_invites i
  JOIN public.quality_satisfaction_campaigns c ON c.id = i.campaign_id
  WHERE i.token = p_token;
$$;
REVOKE ALL ON FUNCTION public.quality_get_invite_public(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.quality_get_invite_public(uuid) TO anon, authenticated;

DROP FUNCTION IF EXISTS public.quality_submit_satisfaction_response(uuid,int,int,text,text,text);

CREATE FUNCTION public.quality_submit_satisfaction_response(
  p_token uuid,
  p_nps int,
  p_csat int,
  p_comment text,
  p_responder_name text,
  p_responder_email text,
  p_ces int DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_invite public.quality_satisfaction_invites%ROWTYPE;
  v_campaign public.quality_satisfaction_campaigns%ROWTYPE;
  v_response_id uuid;
BEGIN
  SELECT * INTO v_invite FROM public.quality_satisfaction_invites WHERE token = p_token;
  IF NOT FOUND THEN RAISE EXCEPTION 'Token inválido' USING ERRCODE='22023'; END IF;
  IF v_invite.responded_at IS NOT NULL THEN RAISE EXCEPTION 'Pesquisa já respondida' USING ERRCODE='22023'; END IF;

  SELECT * INTO v_campaign FROM public.quality_satisfaction_campaigns WHERE id = v_invite.campaign_id;
  IF v_campaign.status <> 'active' THEN RAISE EXCEPTION 'Campanha não está ativa' USING ERRCODE='22023'; END IF;

  IF v_campaign.collects_nps THEN
    IF p_nps IS NULL OR p_nps < 0 OR p_nps > 10 THEN RAISE EXCEPTION 'NPS inválido' USING ERRCODE='22023'; END IF;
  ELSE
    p_nps := NULL;
  END IF;
  IF v_campaign.collects_csat THEN
    IF p_csat IS NULL OR p_csat < 1 OR p_csat > 5 THEN RAISE EXCEPTION 'CSAT inválido' USING ERRCODE='22023'; END IF;
  ELSE
    p_csat := NULL;
  END IF;
  IF v_campaign.collects_ces THEN
    IF p_ces IS NULL OR p_ces < 1 OR p_ces > 7 THEN RAISE EXCEPTION 'CES inválido' USING ERRCODE='22023'; END IF;
  ELSE
    p_ces := NULL;
  END IF;

  INSERT INTO public.quality_satisfaction_responses (
    invite_id, campaign_id, company_id, client_id, service_order_id,
    nps_score, csat_score, ces_score, comment, responder_name, responder_email
  ) VALUES (
    v_invite.id, v_invite.campaign_id, v_campaign.company_id, v_invite.client_id, v_invite.service_order_id,
    p_nps, p_csat, p_ces, NULLIF(trim(p_comment),''), NULLIF(trim(p_responder_name),''), NULLIF(trim(p_responder_email),'')
  ) RETURNING id INTO v_response_id;

  UPDATE public.quality_satisfaction_invites SET responded_at = now() WHERE id = v_invite.id;
  RETURN v_response_id;
END $$;
REVOKE ALL ON FUNCTION public.quality_submit_satisfaction_response(uuid,int,int,text,text,text,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.quality_submit_satisfaction_response(uuid,int,int,text,text,text,int) TO anon, authenticated;
