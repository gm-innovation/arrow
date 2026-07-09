
CREATE POLICY "Commercial and marketing can view company service orders"
ON public.service_orders FOR SELECT TO authenticated
USING (
  company_id = user_company_id(auth.uid())
  AND (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
);

CREATE POLICY "Commercial and marketing can view company visits"
ON public.service_visits FOR SELECT TO authenticated
USING (
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
  AND EXISTS (
    SELECT 1 FROM public.service_orders so
    WHERE so.id = service_visits.service_order_id
      AND so.company_id = user_company_id(auth.uid())
  )
);
