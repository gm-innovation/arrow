
-- 1) finance_payables: restrict to finance team / leadership
DROP POLICY IF EXISTS finance_payables_select ON public.finance_payables;
DROP POLICY IF EXISTS finance_payables_insert ON public.finance_payables;
DROP POLICY IF EXISTS finance_payables_update ON public.finance_payables;
DROP POLICY IF EXISTS finance_payables_delete ON public.finance_payables;

CREATE POLICY finance_payables_select ON public.finance_payables
FOR SELECT TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'financeiro'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'admin'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE POLICY finance_payables_insert ON public.finance_payables
FOR INSERT TO authenticated
WITH CHECK (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'financeiro'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'admin'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE POLICY finance_payables_update ON public.finance_payables
FOR UPDATE TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'financeiro'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'admin'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
)
WITH CHECK (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'financeiro'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'admin'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE POLICY finance_payables_delete ON public.finance_payables
FOR DELETE TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'financeiro'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'admin'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

-- 2) technician_absences: add Director visibility
DROP POLICY IF EXISTS "Directors can view absences in their company" ON public.technician_absences;
CREATE POLICY "Directors can view absences in their company"
ON public.technician_absences
FOR SELECT TO authenticated
USING (
  public.has_role(auth.uid(), 'director'::app_role)
  AND company_id = public.user_company_id(auth.uid())
);

-- 3) corp_feed_polls / corp_feed_poll_options: scope INSERT to same-company author
DROP POLICY IF EXISTS "Authenticated can insert polls" ON public.corp_feed_polls;
CREATE POLICY "Same-company authors can insert polls"
ON public.corp_feed_polls
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.corp_feed_posts p
    WHERE p.id = corp_feed_polls.post_id
      AND p.company_id = public.user_company_id(auth.uid())
      AND p.author_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Authenticated can insert poll options" ON public.corp_feed_poll_options;
CREATE POLICY "Same-company authors can insert poll options"
ON public.corp_feed_poll_options
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.corp_feed_polls pl
    JOIN public.corp_feed_posts p ON p.id = pl.post_id
    WHERE pl.id = corp_feed_poll_options.poll_id
      AND p.company_id = public.user_company_id(auth.uid())
      AND p.author_id = auth.uid()
  )
);

-- 4) vessel_positions: restrict insert to operational roles in the vessel's company
DROP POLICY IF EXISTS "System can insert vessel positions" ON public.vessel_positions;
CREATE POLICY "Operational roles can insert vessel positions"
ON public.vessel_positions
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.vessels v
    JOIN public.clients c ON c.id = v.client_id
    WHERE v.id = vessel_positions.vessel_id
      AND c.company_id = public.user_company_id(auth.uid())
      AND public.is_operational_role(auth.uid())
  )
);
