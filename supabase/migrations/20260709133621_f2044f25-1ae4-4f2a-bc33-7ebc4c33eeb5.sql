
-- P1: prevenção de reincidência
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS entity_type text NOT NULL DEFAULT 'pj' CHECK (entity_type IN ('pj','pf'));

-- Trigger: bloqueia criar/renomear cliente cujo nome bate com funcionário da mesma empresa, salvo quando marcado como PF explicitamente
CREATE OR REPLACE FUNCTION public.prevent_client_employee_collision()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.entity_type = 'pf' THEN RETURN NEW; END IF;
  IF EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.company_id = NEW.company_id
      AND upper(trim(p.full_name)) = upper(trim(NEW.name))
  ) THEN
    RAISE EXCEPTION 'Nome "%" pertence a um colaborador desta empresa. Se for pessoa física, defina entity_type = pf.', NEW.name
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_client_employee_collision ON public.clients;
CREATE TRIGGER trg_prevent_client_employee_collision
BEFORE INSERT OR UPDATE OF name, entity_type ON public.clients
FOR EACH ROW EXECUTE FUNCTION public.prevent_client_employee_collision();

-- Função utilitária de merge: repointa todas as FKs de "loser" para "winner" e apaga o loser
CREATE OR REPLACE FUNCTION public.admin_merge_clients(winner uuid, loser uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF winner = loser THEN RETURN; END IF;
  UPDATE public.crm_opportunities        SET client_id = winner WHERE client_id = loser;
  UPDATE public.crm_buyers               SET client_id = winner WHERE client_id = loser;
  UPDATE public.crm_tasks                SET client_id = winner WHERE client_id = loser;
  UPDATE public.crm_sales                SET client_id = winner WHERE client_id = loser;
  UPDATE public.crm_client_recurrences   SET client_id = winner WHERE client_id = loser;
  UPDATE public.client_contacts          SET client_id = winner WHERE client_id = loser;
  UPDATE public.client_addresses         SET client_id = winner WHERE client_id = loser;
  UPDATE public.client_legal_entities    SET client_id = winner WHERE client_id = loser;
  UPDATE public.vessels                  SET client_id = winner WHERE client_id = loser;
  UPDATE public.service_orders           SET client_id = winner WHERE client_id = loser;
  UPDATE public.finance_receivables      SET client_id = winner WHERE client_id = loser;
  UPDATE public.technician_reservations  SET client_id = winner WHERE client_id = loser;
  UPDATE public.forecast_history         SET client_id = winner WHERE client_id = loser;
  UPDATE public.ai_failure_patterns      SET client_id = winner WHERE client_id = loser;
  UPDATE public.clients                  SET parent_client_id = winner WHERE parent_client_id = loser;
  DELETE FROM public.clients WHERE id = loser;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_merge_clients(uuid, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_merge_clients(uuid, uuid) TO service_role;
