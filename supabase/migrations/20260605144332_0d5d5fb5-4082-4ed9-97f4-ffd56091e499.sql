
-- ============ SPRINT 2.5 ============
DO $$ BEGIN CREATE TYPE public.satisfaction_campaign_status AS ENUM ('draft','active','closed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.satisfaction_target_kind AS ENUM ('all_clients','selected'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.complaint_source AS ENUM ('survey','email','phone','in_person','system','other'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.complaint_status AS ENUM ('new','acknowledged','under_analysis','resolved','rejected'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Campanhas
CREATE TABLE public.quality_satisfaction_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  starts_at date NOT NULL,
  ends_at date NOT NULL,
  status public.satisfaction_campaign_status NOT NULL DEFAULT 'draft',
  target_kind public.satisfaction_target_kind NOT NULL DEFAULT 'all_clients',
  target_client_ids uuid[] NOT NULL DEFAULT '{}',
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_satisfaction_campaigns TO authenticated;
GRANT ALL ON public.quality_satisfaction_campaigns TO service_role;
ALTER TABLE public.quality_satisfaction_campaigns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sgq read campaigns" ON public.quality_satisfaction_campaigns FOR SELECT TO authenticated
USING (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator') OR has_role(auth.uid(),'hr'));
CREATE POLICY "sgq manage campaigns" ON public.quality_satisfaction_campaigns FOR ALL TO authenticated
USING (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator'))
WITH CHECK (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator'));
CREATE TRIGGER trg_qsc_updated_at BEFORE UPDATE ON public.quality_satisfaction_campaigns
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Convites
CREATE TABLE public.quality_satisfaction_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES public.quality_satisfaction_campaigns(id) ON DELETE CASCADE,
  client_id uuid,
  service_order_id uuid,
  token uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  sent_at timestamptz,
  responded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_satisfaction_invites TO authenticated;
GRANT ALL ON public.quality_satisfaction_invites TO service_role;
ALTER TABLE public.quality_satisfaction_invites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sgq read invites" ON public.quality_satisfaction_invites FOR SELECT TO authenticated
USING (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator') OR has_role(auth.uid(),'hr'));
CREATE POLICY "sgq manage invites" ON public.quality_satisfaction_invites FOR ALL TO authenticated
USING (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator'))
WITH CHECK (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator'));
CREATE INDEX idx_qsi_campaign ON public.quality_satisfaction_invites(campaign_id);
CREATE INDEX idx_qsi_token ON public.quality_satisfaction_invites(token);

-- Respostas
CREATE TABLE public.quality_satisfaction_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_id uuid UNIQUE REFERENCES public.quality_satisfaction_invites(id) ON DELETE SET NULL,
  campaign_id uuid REFERENCES public.quality_satisfaction_campaigns(id) ON DELETE SET NULL,
  company_id uuid NOT NULL,
  client_id uuid,
  service_order_id uuid,
  nps_score int NOT NULL CHECK (nps_score BETWEEN 0 AND 10),
  csat_score int NOT NULL CHECK (csat_score BETWEEN 1 AND 5),
  comment text,
  responder_name text,
  responder_email text,
  responder_ip text,
  derived_nps text,
  derived_csat text,
  suggested_ncr_id uuid,
  responded_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_satisfaction_responses TO authenticated;
GRANT ALL ON public.quality_satisfaction_responses TO service_role;
ALTER TABLE public.quality_satisfaction_responses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sgq read responses" ON public.quality_satisfaction_responses FOR SELECT TO authenticated
USING (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator') OR has_role(auth.uid(),'hr'));
CREATE POLICY "sgq manage responses" ON public.quality_satisfaction_responses FOR ALL TO authenticated
USING (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator'))
WITH CHECK (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator'));
CREATE INDEX idx_qsr_campaign ON public.quality_satisfaction_responses(campaign_id);
CREATE INDEX idx_qsr_company_resp ON public.quality_satisfaction_responses(company_id, responded_at);

CREATE OR REPLACE FUNCTION public.quality_derive_satisfaction_categories()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  NEW.derived_nps := CASE WHEN NEW.nps_score >= 9 THEN 'promoter' WHEN NEW.nps_score >= 7 THEN 'neutral' ELSE 'detractor' END;
  NEW.derived_csat := CASE WHEN NEW.csat_score >= 4 THEN 'satisfied' WHEN NEW.csat_score = 3 THEN 'neutral' ELSE 'dissatisfied' END;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_qsr_derive BEFORE INSERT OR UPDATE OF nps_score, csat_score
  ON public.quality_satisfaction_responses FOR EACH ROW EXECUTE FUNCTION public.quality_derive_satisfaction_categories();

-- Reclamações
CREATE SEQUENCE IF NOT EXISTS public.quality_complaints_number_seq;
CREATE TABLE public.quality_complaints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  complaint_number int NOT NULL DEFAULT nextval('public.quality_complaints_number_seq'),
  client_id uuid,
  is_anonymous boolean NOT NULL DEFAULT false,
  source public.complaint_source NOT NULL DEFAULT 'other',
  title text NOT NULL,
  description text NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  status public.complaint_status NOT NULL DEFAULT 'new',
  responsible_id uuid REFERENCES auth.users(id),
  linked_ncr_id uuid,
  linked_response_id uuid REFERENCES public.quality_satisfaction_responses(id) ON DELETE SET NULL,
  resolution_notes text,
  responder_name text,
  responder_email text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_complaints TO authenticated;
GRANT ALL ON public.quality_complaints TO service_role;
ALTER TABLE public.quality_complaints ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sgq read complaints" ON public.quality_complaints FOR SELECT TO authenticated
USING (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator') OR has_role(auth.uid(),'hr'));
CREATE POLICY "sgq manage complaints" ON public.quality_complaints FOR ALL TO authenticated
USING (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator'))
WITH CHECK (has_role(auth.uid(),'director') OR has_role(auth.uid(),'super_admin') OR has_role(auth.uid(),'coordinator'));
CREATE INDEX idx_qc_company_received ON public.quality_complaints(company_id, received_at);
CREATE INDEX idx_qc_status ON public.quality_complaints(status);
CREATE TRIGGER trg_qc_updated_at BEFORE UPDATE ON public.quality_complaints
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- RPC pública: ler convite
CREATE OR REPLACE FUNCTION public.quality_get_invite_public(p_token uuid)
RETURNS TABLE (invite_id uuid, campaign_id uuid, campaign_name text, campaign_status text, already_responded boolean)
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT i.id, c.id, c.name, c.status::text, (i.responded_at IS NOT NULL)
  FROM public.quality_satisfaction_invites i
  JOIN public.quality_satisfaction_campaigns c ON c.id = i.campaign_id
  WHERE i.token = p_token;
$$;
REVOKE ALL ON FUNCTION public.quality_get_invite_public(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.quality_get_invite_public(uuid) TO anon, authenticated;

-- RPC pública: submeter resposta
CREATE OR REPLACE FUNCTION public.quality_submit_satisfaction_response(
  p_token uuid, p_nps int, p_csat int, p_comment text, p_responder_name text, p_responder_email text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_invite public.quality_satisfaction_invites%ROWTYPE;
  v_campaign public.quality_satisfaction_campaigns%ROWTYPE;
  v_response_id uuid;
BEGIN
  IF p_nps IS NULL OR p_nps < 0 OR p_nps > 10 THEN RAISE EXCEPTION 'NPS inválido' USING ERRCODE='22023'; END IF;
  IF p_csat IS NULL OR p_csat < 1 OR p_csat > 5 THEN RAISE EXCEPTION 'CSAT inválido' USING ERRCODE='22023'; END IF;

  SELECT * INTO v_invite FROM public.quality_satisfaction_invites WHERE token = p_token;
  IF NOT FOUND THEN RAISE EXCEPTION 'Token inválido' USING ERRCODE='22023'; END IF;
  IF v_invite.responded_at IS NOT NULL THEN RAISE EXCEPTION 'Pesquisa já respondida' USING ERRCODE='22023'; END IF;

  SELECT * INTO v_campaign FROM public.quality_satisfaction_campaigns WHERE id = v_invite.campaign_id;
  IF v_campaign.status <> 'active' THEN RAISE EXCEPTION 'Campanha não está ativa' USING ERRCODE='22023'; END IF;

  INSERT INTO public.quality_satisfaction_responses (
    invite_id, campaign_id, company_id, client_id, service_order_id,
    nps_score, csat_score, comment, responder_name, responder_email
  ) VALUES (
    v_invite.id, v_invite.campaign_id, v_campaign.company_id, v_invite.client_id, v_invite.service_order_id,
    p_nps, p_csat, NULLIF(trim(p_comment),''), NULLIF(trim(p_responder_name),''), NULLIF(trim(p_responder_email),'')
  ) RETURNING id INTO v_response_id;

  UPDATE public.quality_satisfaction_invites SET responded_at = now() WHERE id = v_invite.id;
  RETURN v_response_id;
END $$;
REVOKE ALL ON FUNCTION public.quality_submit_satisfaction_response(uuid,int,int,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.quality_submit_satisfaction_response(uuid,int,int,text,text,text) TO anon, authenticated;

-- RPC: converter reclamação em NCR (manual)
CREATE OR REPLACE FUNCTION public.quality_complaint_to_ncr(p_complaint_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  v_c public.quality_complaints%ROWTYPE;
  v_ncr_id uuid;
BEGIN
  SELECT * INTO v_c FROM public.quality_complaints WHERE id = p_complaint_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reclamação não encontrada'; END IF;
  IF v_c.linked_ncr_id IS NOT NULL THEN RETURN v_c.linked_ncr_id; END IF;

  INSERT INTO public.quality_ncrs (
    company_id, title, description, ncr_type, severity, status, source, detected_at, created_by
  ) VALUES (
    v_c.company_id,
    'Reclamação #' || v_c.complaint_number || ' — ' || v_c.title,
    v_c.description,
    'external', 'minor', 'open', 'customer_complaint',
    v_c.received_at, auth.uid()
  ) RETURNING id INTO v_ncr_id;

  UPDATE public.quality_complaints SET linked_ncr_id = v_ncr_id, updated_at = now() WHERE id = p_complaint_id;
  RETURN v_ncr_id;
END $$;
GRANT EXECUTE ON FUNCTION public.quality_complaint_to_ncr(uuid) TO authenticated;
