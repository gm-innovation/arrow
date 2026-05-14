ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS ignore_omie_sync boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_clients_ignore_omie_sync
  ON public.clients (company_id, ignore_omie_sync) WHERE ignore_omie_sync = true;

CREATE TABLE IF NOT EXISTS public.omie_sync_blocklist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  omie_client_id text,
  cnpj text,
  reason text,
  blocked_at timestamptz NOT NULL DEFAULT now(),
  blocked_by uuid REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_omie_blocklist_company_omie
  ON public.omie_sync_blocklist (company_id, omie_client_id);
CREATE INDEX IF NOT EXISTS idx_omie_blocklist_company_cnpj
  ON public.omie_sync_blocklist (company_id, cnpj);

ALTER TABLE public.omie_sync_blocklist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Coordinators view blocklist of own company"
  ON public.omie_sync_blocklist FOR SELECT
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
    )
  );

CREATE POLICY "Coordinators insert blocklist of own company"
  ON public.omie_sync_blocklist FOR INSERT
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );

CREATE POLICY "Coordinators delete blocklist of own company"
  ON public.omie_sync_blocklist FOR DELETE
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );