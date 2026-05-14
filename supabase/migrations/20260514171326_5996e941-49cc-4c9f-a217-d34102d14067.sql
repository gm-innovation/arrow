
CREATE TABLE public.crm_opportunity_transfers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  opportunity_id uuid NOT NULL REFERENCES public.crm_opportunities(id) ON DELETE CASCADE,
  from_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
  to_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
  reason text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','cancelled','auto')),
  decided_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  decided_at timestamptz,
  decision_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_crm_opp_transfers_opp ON public.crm_opportunity_transfers(opportunity_id);
CREATE INDEX idx_crm_opp_transfers_to ON public.crm_opportunity_transfers(to_user_id);
CREATE INDEX idx_crm_opp_transfers_from ON public.crm_opportunity_transfers(from_user_id);
CREATE INDEX idx_crm_opp_transfers_status ON public.crm_opportunity_transfers(status);

ALTER TABLE public.crm_opportunity_transfers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Transfers visible to involved or coordinators"
ON public.crm_opportunity_transfers FOR SELECT TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    from_user_id = auth.uid()
    OR to_user_id = auth.uid()
    OR public.has_role(auth.uid(), 'coordinator')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'admin')
    OR public.has_role(auth.uid(), 'super_admin')
  )
);

CREATE POLICY "Coordinators can create transfers"
ON public.crm_opportunity_transfers FOR INSERT TO authenticated
WITH CHECK (
  company_id = public.user_company_id(auth.uid())
  AND from_user_id = auth.uid()
  AND (
    public.has_role(auth.uid(), 'coordinator')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'admin')
  )
);

CREATE POLICY "Decide or cancel transfer"
ON public.crm_opportunity_transfers FOR UPDATE TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    to_user_id = auth.uid()
    OR from_user_id = auth.uid()
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'admin')
  )
)
WITH CHECK (company_id = public.user_company_id(auth.uid()));

CREATE TRIGGER update_crm_opp_transfers_updated_at
BEFORE UPDATE ON public.crm_opportunity_transfers
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.crm_opp_transfer_apply()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_to_name text;
  v_from_name text;
  v_opp_title text;
BEGIN
  SELECT full_name INTO v_to_name FROM public.profiles WHERE id = NEW.to_user_id;
  SELECT full_name INTO v_from_name FROM public.profiles WHERE id = NEW.from_user_id;
  SELECT title INTO v_opp_title FROM public.crm_opportunities WHERE id = NEW.opportunity_id;

  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'auto' THEN
      UPDATE public.crm_opportunities SET assigned_to = NEW.to_user_id WHERE id = NEW.opportunity_id;
      INSERT INTO public.crm_opportunity_activities (opportunity_id, user_id, activity_type, description)
      VALUES (NEW.opportunity_id, NEW.from_user_id, 'note',
        format('[Transferência direta] %s → %s%s', COALESCE(v_from_name,'—'), COALESCE(v_to_name,'—'),
          CASE WHEN NEW.reason IS NOT NULL AND NEW.reason <> '' THEN ' | Motivo: '||NEW.reason ELSE '' END));
      INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id)
      VALUES (NEW.to_user_id, 'task_assignment', 'Oportunidade transferida para você',
        format('"%s" foi transferida por %s.', COALESCE(v_opp_title,'Oportunidade'), COALESCE(v_from_name,'—')),
        NEW.opportunity_id);
    ELSIF NEW.status = 'pending' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id)
      VALUES (NEW.to_user_id, 'approval_pending', 'Solicitação de transferência de oportunidade',
        format('%s solicitou transferir "%s" para você.', COALESCE(v_from_name,'—'), COALESCE(v_opp_title,'Oportunidade')),
        NEW.opportunity_id);
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.status <> OLD.status THEN
    IF NEW.status = 'accepted' THEN
      UPDATE public.crm_opportunities SET assigned_to = NEW.to_user_id WHERE id = NEW.opportunity_id;
      INSERT INTO public.crm_opportunity_activities (opportunity_id, user_id, activity_type, description)
      VALUES (NEW.opportunity_id, NEW.to_user_id, 'note',
        format('[Transferência aceita] %s → %s%s', COALESCE(v_from_name,'—'), COALESCE(v_to_name,'—'),
          CASE WHEN NEW.decision_note IS NOT NULL AND NEW.decision_note <> '' THEN ' | Nota: '||NEW.decision_note ELSE '' END));
      INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id)
      VALUES (NEW.from_user_id, 'request_approved', 'Transferência aceita',
        format('%s aceitou a transferência de "%s".', COALESCE(v_to_name,'—'), COALESCE(v_opp_title,'Oportunidade')),
        NEW.opportunity_id);
    ELSIF NEW.status = 'rejected' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id)
      VALUES (NEW.from_user_id, 'request_rejected', 'Transferência recusada',
        format('%s recusou a transferência de "%s"%s.', COALESCE(v_to_name,'—'), COALESCE(v_opp_title,'Oportunidade'),
          CASE WHEN NEW.decision_note IS NOT NULL AND NEW.decision_note <> '' THEN ' | Motivo: '||NEW.decision_note ELSE '' END),
        NEW.opportunity_id);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER crm_opp_transfer_apply_trg
AFTER INSERT OR UPDATE ON public.crm_opportunity_transfers
FOR EACH ROW EXECUTE FUNCTION public.crm_opp_transfer_apply();
