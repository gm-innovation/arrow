
-- 1. Coordenadores e diretores podem ver visitas da sua empresa
CREATE POLICY "Coordinators and directors can view company visits"
ON public.service_visits
FOR SELECT
TO authenticated
USING (
  (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role))
  AND EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = service_visits.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

-- 2. Coordenadores e diretores podem gerenciar técnicos de visitas da sua empresa
CREATE POLICY "Coordinators and directors can manage visit technicians"
ON public.visit_technicians
FOR ALL
TO authenticated
USING (
  (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role))
  AND EXISTS (
    SELECT 1 FROM service_visits sv
    JOIN service_orders so ON sv.service_order_id = so.id
    WHERE sv.id = visit_technicians.visit_id
      AND so.company_id = user_company_id(auth.uid())
  )
)
WITH CHECK (
  (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role))
  AND EXISTS (
    SELECT 1 FROM service_visits sv
    JOIN service_orders so ON sv.service_order_id = so.id
    WHERE sv.id = visit_technicians.visit_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
