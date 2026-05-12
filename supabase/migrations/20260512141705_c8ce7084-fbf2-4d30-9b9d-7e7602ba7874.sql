ALTER TABLE public.companies
  ADD COLUMN IF NOT EXISTS public_site_slug text UNIQUE,
  ADD COLUMN IF NOT EXISTS public_intake_enabled boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.public_site_leads (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('rfq','contact')),
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  company_name text,
  message text,
  items jsonb NOT NULL DEFAULT '[]'::jsonb,
  source text NOT NULL DEFAULT 'site',
  ip text,
  user_agent text,
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new','reviewed','converted','discarded')),
  converted_opportunity_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_public_site_leads_company ON public.public_site_leads(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_public_site_leads_status ON public.public_site_leads(status);

ALTER TABLE public.public_site_leads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company staff can view their site leads"
ON public.public_site_leads FOR SELECT
TO authenticated
USING (
  public.has_role(auth.uid(), 'super_admin'::app_role)
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.company_id = public_site_leads.company_id
      AND (
        public.has_role(auth.uid(), 'coordinator'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
        OR public.has_role(auth.uid(), 'admin'::app_role)
      )
  )
);

CREATE POLICY "Company staff can update their site leads"
ON public.public_site_leads FOR UPDATE
TO authenticated
USING (
  public.has_role(auth.uid(), 'super_admin'::app_role)
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.company_id = public_site_leads.company_id
      AND (
        public.has_role(auth.uid(), 'coordinator'::app_role)
        OR public.has_role(auth.uid(), 'director'::app_role)
        OR public.has_role(auth.uid(), 'admin'::app_role)
      )
  )
);

CREATE TABLE IF NOT EXISTS public.public_lead_rate_limit (
  ip text NOT NULL,
  window_start timestamptz NOT NULL,
  count int NOT NULL DEFAULT 1,
  PRIMARY KEY (ip, window_start)
);
ALTER TABLE public.public_lead_rate_limit ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS trg_public_site_leads_updated_at ON public.public_site_leads;
CREATE TRIGGER trg_public_site_leads_updated_at
BEFORE UPDATE ON public.public_site_leads
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();