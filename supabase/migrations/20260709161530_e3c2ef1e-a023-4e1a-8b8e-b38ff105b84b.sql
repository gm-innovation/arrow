
DO $$ BEGIN
  CREATE TYPE public.vacation_period_status AS ENUM ('open','partially_used','fully_used','expired');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.vacation_request_status AS ENUM (
    'draft','pending_manager','pending_hr','approved','rejected','cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.vacation_request_type AS ENUM ('vacation','sell_days','advance_13th');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.hr_vacation_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  concession_deadline DATE NOT NULL,
  entitled_days INTEGER NOT NULL DEFAULT 30,
  used_days INTEGER NOT NULL DEFAULT 0,
  sold_days INTEGER NOT NULL DEFAULT 0,
  status public.vacation_period_status NOT NULL DEFAULT 'open',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (employee_id, period_start)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hr_vacation_periods TO authenticated;
GRANT ALL ON public.hr_vacation_periods TO service_role;
ALTER TABLE public.hr_vacation_periods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reads own vacation periods" ON public.hr_vacation_periods FOR SELECT TO authenticated
USING (
  employee_id = auth.uid()
  OR public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director')
  OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'super_admin')
  OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = hr_vacation_periods.employee_id AND p.direct_manager_id = auth.uid())
);

CREATE POLICY "hr manages vacation periods" ON public.hr_vacation_periods FOR ALL TO authenticated
USING (
  public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director')
  OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'super_admin')
) WITH CHECK (
  public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director')
  OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'super_admin')
);

CREATE TRIGGER trg_hr_vacation_periods_updated_at
  BEFORE UPDATE ON public.hr_vacation_periods
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE IF NOT EXISTS public.hr_vacation_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  period_id UUID REFERENCES public.hr_vacation_periods(id) ON DELETE SET NULL,
  request_type public.vacation_request_type NOT NULL DEFAULT 'vacation',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  requested_days INTEGER NOT NULL,
  sell_days INTEGER NOT NULL DEFAULT 0,
  advance_13th BOOLEAN NOT NULL DEFAULT false,
  justification TEXT,
  status public.vacation_request_status NOT NULL DEFAULT 'pending_manager',
  manager_id UUID REFERENCES public.profiles(id),
  manager_decision_at TIMESTAMPTZ,
  manager_comment TEXT,
  hr_decision_by UUID REFERENCES public.profiles(id),
  hr_decision_at TIMESTAMPTZ,
  hr_comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date),
  CHECK (requested_days > 0)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hr_vacation_requests TO authenticated;
GRANT ALL ON public.hr_vacation_requests TO service_role;
ALTER TABLE public.hr_vacation_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reads vacation requests" ON public.hr_vacation_requests FOR SELECT TO authenticated
USING (
  employee_id = auth.uid() OR manager_id = auth.uid()
  OR public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director')
  OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'super_admin')
  OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = hr_vacation_requests.employee_id AND p.direct_manager_id = auth.uid())
);

CREATE POLICY "creates vacation request" ON public.hr_vacation_requests FOR INSERT TO authenticated
WITH CHECK (
  employee_id = auth.uid()
  OR public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director')
  OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'super_admin')
);

CREATE POLICY "updates vacation request" ON public.hr_vacation_requests FOR UPDATE TO authenticated
USING (
  (employee_id = auth.uid() AND status IN ('draft','pending_manager'))
  OR manager_id = auth.uid()
  OR public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director')
  OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'super_admin')
  OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = hr_vacation_requests.employee_id AND p.direct_manager_id = auth.uid())
);

CREATE POLICY "hr deletes vacation request" ON public.hr_vacation_requests FOR DELETE TO authenticated
USING (
  public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director')
  OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'super_admin')
);

CREATE TRIGGER trg_hr_vacation_requests_updated_at
  BEFORE UPDATE ON public.hr_vacation_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE INDEX IF NOT EXISTS idx_hr_vacation_requests_employee ON public.hr_vacation_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_hr_vacation_requests_status ON public.hr_vacation_requests(status);

CREATE TABLE IF NOT EXISTS public.hr_vacation_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.hr_vacation_requests(id) ON DELETE CASCADE,
  approver_id UUID NOT NULL REFERENCES public.profiles(id),
  stage TEXT NOT NULL,
  decision TEXT NOT NULL,
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.hr_vacation_approvals TO authenticated;
GRANT ALL ON public.hr_vacation_approvals TO service_role;
ALTER TABLE public.hr_vacation_approvals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reads vacation approvals" ON public.hr_vacation_approvals FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.hr_vacation_requests r
    WHERE r.id = hr_vacation_approvals.request_id
      AND (
        r.employee_id = auth.uid() OR r.manager_id = auth.uid()
        OR public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director')
        OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'super_admin')
      )
  )
);

CREATE POLICY "inserts vacation approvals" ON public.hr_vacation_approvals FOR INSERT TO authenticated
WITH CHECK (approver_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_hr_vacation_approvals_request ON public.hr_vacation_approvals(request_id);

CREATE OR REPLACE FUNCTION public.create_initial_vacation_period()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_start DATE;
BEGIN
  IF NEW.hire_date IS NULL THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' AND OLD.hire_date IS NOT DISTINCT FROM NEW.hire_date THEN RETURN NEW; END IF;
  v_start := NEW.hire_date;
  INSERT INTO public.hr_vacation_periods (employee_id, period_start, period_end, concession_deadline, entitled_days)
  VALUES (NEW.id, v_start, (v_start + INTERVAL '12 months')::date, (v_start + INTERVAL '23 months')::date, 30)
  ON CONFLICT (employee_id, period_start) DO NOTHING;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_create_initial_vacation_period ON public.profiles;
CREATE TRIGGER trg_create_initial_vacation_period
  AFTER INSERT OR UPDATE OF hire_date ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.create_initial_vacation_period();

CREATE OR REPLACE FUNCTION public.sync_vacation_period_balance()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS DISTINCT FROM 'approved') AND NEW.period_id IS NOT NULL THEN
    UPDATE public.hr_vacation_periods
       SET used_days = used_days + COALESCE(NEW.requested_days,0),
           sold_days = sold_days + COALESCE(NEW.sell_days,0),
           status = CASE
             WHEN (used_days + COALESCE(NEW.requested_days,0) + sold_days + COALESCE(NEW.sell_days,0)) >= entitled_days
               THEN 'fully_used'::vacation_period_status
             ELSE 'partially_used'::vacation_period_status
           END,
           updated_at = now()
     WHERE id = NEW.period_id;
  END IF;

  IF OLD.status = 'approved' AND NEW.status IN ('cancelled','rejected') AND OLD.period_id IS NOT NULL THEN
    UPDATE public.hr_vacation_periods
       SET used_days = GREATEST(0, used_days - COALESCE(OLD.requested_days,0)),
           sold_days = GREATEST(0, sold_days - COALESCE(OLD.sell_days,0)),
           status = CASE
             WHEN (GREATEST(0, used_days - COALESCE(OLD.requested_days,0))
                   + GREATEST(0, sold_days - COALESCE(OLD.sell_days,0))) = 0
               THEN 'open'::vacation_period_status
             ELSE 'partially_used'::vacation_period_status
           END,
           updated_at = now()
     WHERE id = OLD.period_id;
  END IF;

  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_sync_vacation_period_balance ON public.hr_vacation_requests;
CREATE TRIGGER trg_sync_vacation_period_balance
  AFTER UPDATE OF status ON public.hr_vacation_requests
  FOR EACH ROW EXECUTE FUNCTION public.sync_vacation_period_balance();

CREATE OR REPLACE FUNCTION public.get_vacation_balance(_employee_id UUID)
RETURNS TABLE (
  total_entitled INTEGER, total_used INTEGER, total_sold INTEGER,
  available_days INTEGER, open_periods INTEGER, next_deadline DATE
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    COALESCE(SUM(entitled_days),0)::int,
    COALESCE(SUM(used_days),0)::int,
    COALESCE(SUM(sold_days),0)::int,
    COALESCE(SUM(entitled_days - used_days - sold_days),0)::int,
    COUNT(*) FILTER (WHERE status IN ('open','partially_used'))::int,
    MIN(concession_deadline) FILTER (WHERE status IN ('open','partially_used'))
  FROM public.hr_vacation_periods
  WHERE employee_id = _employee_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_vacation_balance(UUID) TO authenticated;
