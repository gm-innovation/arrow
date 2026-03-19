-- Fix measurement access policies: coordinators are stored as 'coordinator' in user_roles,
-- not 'admin'. Existing policies were blocking reads/inserts/updates.

-- Main measurements table
DROP POLICY IF EXISTS "Coordinators can manage company measurements" ON public.measurements;
DROP POLICY IF EXISTS "Directors can manage company measurements" ON public.measurements;

CREATE POLICY "Coordinators can manage company measurements"
ON public.measurements
FOR ALL
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Directors can manage company measurements"
ON public.measurements
FOR ALL
USING (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.service_orders so
    WHERE so.id = measurements.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

-- Detail tables: coordinators/directors must also be able to read and manage nested items
DROP POLICY IF EXISTS "Coordinators can manage their measurement details" ON public.measurement_man_hours;
DROP POLICY IF EXISTS "Coordinators can manage company measurement details" ON public.measurement_man_hours;
DROP POLICY IF EXISTS "Directors can manage company measurement details" ON public.measurement_man_hours;
CREATE POLICY "Coordinators can manage company measurement details"
ON public.measurement_man_hours
FOR ALL
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
CREATE POLICY "Directors can manage company measurement details"
ON public.measurement_man_hours
FOR ALL
USING (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

DROP POLICY IF EXISTS "Coordinators can manage their measurement details" ON public.measurement_materials;
DROP POLICY IF EXISTS "Coordinators can manage company measurement details" ON public.measurement_materials;
DROP POLICY IF EXISTS "Directors can manage company measurement details" ON public.measurement_materials;
CREATE POLICY "Coordinators can manage company measurement details"
ON public.measurement_materials
FOR ALL
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_materials.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_materials.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
CREATE POLICY "Directors can manage company measurement details"
ON public.measurement_materials
FOR ALL
USING (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_materials.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_materials.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

DROP POLICY IF EXISTS "Coordinators can manage their measurement details" ON public.measurement_services;
DROP POLICY IF EXISTS "Coordinators can manage company measurement details" ON public.measurement_services;
DROP POLICY IF EXISTS "Directors can manage company measurement details" ON public.measurement_services;
CREATE POLICY "Coordinators can manage company measurement details"
ON public.measurement_services
FOR ALL
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_services.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_services.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
CREATE POLICY "Directors can manage company measurement details"
ON public.measurement_services
FOR ALL
USING (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_services.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_services.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

DROP POLICY IF EXISTS "Coordinators can manage their measurement details" ON public.measurement_travels;
DROP POLICY IF EXISTS "Coordinators can manage company measurement details" ON public.measurement_travels;
DROP POLICY IF EXISTS "Directors can manage company measurement details" ON public.measurement_travels;
CREATE POLICY "Coordinators can manage company measurement details"
ON public.measurement_travels
FOR ALL
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_travels.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_travels.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
CREATE POLICY "Directors can manage company measurement details"
ON public.measurement_travels
FOR ALL
USING (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_travels.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_travels.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

DROP POLICY IF EXISTS "Coordinators can manage their measurement details" ON public.measurement_expenses;
DROP POLICY IF EXISTS "Coordinators can manage company measurement details" ON public.measurement_expenses;
DROP POLICY IF EXISTS "Directors can manage company measurement details" ON public.measurement_expenses;
CREATE POLICY "Coordinators can manage company measurement details"
ON public.measurement_expenses
FOR ALL
USING (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'coordinator'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
CREATE POLICY "Directors can manage company measurement details"
ON public.measurement_expenses
FOR ALL
USING (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  has_role(auth.uid(), 'director'::app_role)
  AND EXISTS (
    SELECT 1
    FROM public.measurements m
    JOIN public.service_orders so ON so.id = m.service_order_id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);