CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TABLE public.api_integrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  key_hash text NOT NULL UNIQUE,
  key_prefix text NOT NULL,
  scopes text[] NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','revoked')),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  last_used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_api_integrations_company ON public.api_integrations(company_id);
CREATE INDEX idx_api_integrations_key_hash ON public.api_integrations(key_hash);
ALTER TABLE public.api_integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Director and super_admin can view integrations of their company"
ON public.api_integrations FOR SELECT
USING ((company_id = public.user_company_id(auth.uid()) AND public.has_role(auth.uid(), 'director')) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "Director and super_admin can insert integrations"
ON public.api_integrations FOR INSERT
WITH CHECK ((company_id = public.user_company_id(auth.uid()) AND public.has_role(auth.uid(), 'director')) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "Director and super_admin can update integrations"
ON public.api_integrations FOR UPDATE
USING ((company_id = public.user_company_id(auth.uid()) AND public.has_role(auth.uid(), 'director')) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "Director and super_admin can delete integrations"
ON public.api_integrations FOR DELETE
USING ((company_id = public.user_company_id(auth.uid()) AND public.has_role(auth.uid(), 'director')) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TABLE public.api_request_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_id uuid REFERENCES public.api_integrations(id) ON DELETE CASCADE,
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE,
  method text NOT NULL,
  path text NOT NULL,
  status integer NOT NULL,
  latency_ms integer,
  ip text,
  user_agent text,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_api_request_logs_integration ON public.api_request_logs(integration_id, created_at DESC);
CREATE INDEX idx_api_request_logs_company ON public.api_request_logs(company_id, created_at DESC);
ALTER TABLE public.api_request_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Director and super_admin can view logs of their company"
ON public.api_request_logs FOR SELECT
USING ((company_id = public.user_company_id(auth.uid()) AND public.has_role(auth.uid(), 'director')) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TABLE public.api_idempotency_keys (
  key text NOT NULL,
  integration_id uuid NOT NULL REFERENCES public.api_integrations(id) ON DELETE CASCADE,
  response_status integer NOT NULL,
  response_body jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (integration_id, key)
);
CREATE INDEX idx_api_idempotency_created ON public.api_idempotency_keys(created_at);
ALTER TABLE public.api_idempotency_keys ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.verify_api_key(_key text)
RETURNS TABLE (integration_id uuid, company_id uuid, scopes text[])
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT i.id, i.company_id, i.scopes
  FROM public.api_integrations i
  WHERE i.key_hash = encode(extensions.digest(_key, 'sha256'), 'hex')
    AND i.status = 'active'
  LIMIT 1;
$$;

CREATE TRIGGER trg_api_integrations_updated_at
BEFORE UPDATE ON public.api_integrations
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();