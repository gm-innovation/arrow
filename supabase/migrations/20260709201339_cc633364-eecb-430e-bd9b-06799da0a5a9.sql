
-- Helper: quem pode editar uma medição de uma OS específica
CREATE OR REPLACE FUNCTION public.can_edit_measurement_by_so(_service_order_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    has_role(auth.uid(), 'super_admin'::app_role)
    OR has_role(auth.uid(), 'director'::app_role)
    OR has_role(auth.uid(), 'coordinator'::app_role)
    OR has_role(auth.uid(), 'admin'::app_role)
    OR (
      (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
      AND EXISTS (
        SELECT 1 FROM public.service_orders so
        WHERE so.id = _service_order_id
          AND so.created_by = auth.uid()
      )
    );
$$;

-- Marketing: SELECT nas medições da empresa
CREATE POLICY "Marketing can view company measurements"
ON public.measurements FOR SELECT
USING (
  has_role(auth.uid(), 'marketing'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

-- Commercial/Marketing: INSERT/UPDATE/DELETE em measurements quando são donos da OS
CREATE POLICY "Commercial marketing manage own measurements"
ON public.measurements FOR ALL
USING (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.created_by = auth.uid()
  )
)
WITH CHECK (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.created_by = auth.uid()
  )
);

-- Sub-tabelas: policies genéricas para commercial/marketing donos da OS
CREATE POLICY "Commercial marketing manage own measurement materials"
ON public.measurement_materials FOR ALL
USING (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_materials.measurement_id
      AND so.created_by = auth.uid()
  )
)
WITH CHECK (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_materials.measurement_id
      AND so.created_by = auth.uid()
  )
);

CREATE POLICY "Commercial marketing manage own measurement services"
ON public.measurement_services FOR ALL
USING (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_services.measurement_id
      AND so.created_by = auth.uid()
  )
)
WITH CHECK (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_services.measurement_id
      AND so.created_by = auth.uid()
  )
);

CREATE POLICY "Commercial marketing manage own measurement man hours"
ON public.measurement_man_hours FOR ALL
USING (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.created_by = auth.uid()
  )
)
WITH CHECK (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.created_by = auth.uid()
  )
);

CREATE POLICY "Commercial marketing manage own measurement travels"
ON public.measurement_travels FOR ALL
USING (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_travels.measurement_id
      AND so.created_by = auth.uid()
  )
)
WITH CHECK (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_travels.measurement_id
      AND so.created_by = auth.uid()
  )
);

CREATE POLICY "Commercial marketing manage own measurement expenses"
ON public.measurement_expenses FOR ALL
USING (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.created_by = auth.uid()
  )
)
WITH CHECK (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.created_by = auth.uid()
  )
);

-- Marketing SELECT nas sub-tabelas (commercial já tinha via policies existentes? conferindo)
CREATE POLICY "Marketing can view measurement details"
ON public.measurement_materials FOR SELECT
USING (
  has_role(auth.uid(), 'marketing'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_materials.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Marketing can view measurement services"
ON public.measurement_services FOR SELECT
USING (
  has_role(auth.uid(), 'marketing'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_services.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Marketing can view measurement man hours"
ON public.measurement_man_hours FOR SELECT
USING (
  has_role(auth.uid(), 'marketing'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Marketing can view measurement travels"
ON public.measurement_travels FOR SELECT
USING (
  has_role(auth.uid(), 'marketing'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_travels.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Marketing can view measurement expenses"
ON public.measurement_expenses FOR SELECT
USING (
  has_role(auth.uid(), 'marketing'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
