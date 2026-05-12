-- api_integrations
DROP POLICY IF EXISTS "Director and super_admin can view integrations of their company" ON public.api_integrations;
DROP POLICY IF EXISTS "Director and super_admin can insert integrations" ON public.api_integrations;
DROP POLICY IF EXISTS "Director and super_admin can update integrations" ON public.api_integrations;
DROP POLICY IF EXISTS "Director and super_admin can delete integrations" ON public.api_integrations;

CREATE POLICY "Super admin manages all integrations"
ON public.api_integrations FOR ALL
USING (public.has_role(auth.uid(), 'super_admin'))
WITH CHECK (public.has_role(auth.uid(), 'super_admin'));

-- api_request_logs
DROP POLICY IF EXISTS "Director and super_admin can view logs of their company" ON public.api_request_logs;

CREATE POLICY "Super admin views all logs"
ON public.api_request_logs FOR SELECT
USING (public.has_role(auth.uid(), 'super_admin'));