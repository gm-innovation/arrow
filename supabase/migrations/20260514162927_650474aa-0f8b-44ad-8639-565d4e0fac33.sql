
-- Extend public_site_leads
ALTER TABLE public.public_site_leads
  ADD COLUMN IF NOT EXISTS segment text NOT NULL DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

DO $$ BEGIN
  ALTER TABLE public.public_site_leads
    ADD CONSTRAINT public_site_leads_segment_check
    CHECK (segment IN ('service','product','unknown'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Allow more sources
ALTER TABLE public.public_site_leads
  DROP CONSTRAINT IF EXISTS public_site_leads_source_check;

DO $$ BEGIN
  ALTER TABLE public.public_site_leads
    ADD CONSTRAINT public_site_leads_source_check
    CHECK (source IN ('site','site_rfq','site_contact','whatsapp','phone','client_referral','import','manual'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS idx_public_site_leads_segment ON public.public_site_leads(segment);
CREATE INDEX IF NOT EXISTS idx_public_site_leads_assigned_to ON public.public_site_leads(assigned_to);

-- Extend crm_opportunities
ALTER TABLE public.crm_opportunities
  ADD COLUMN IF NOT EXISTS segment text NOT NULL DEFAULT 'product',
  ADD COLUMN IF NOT EXISTS service_order_id uuid REFERENCES public.service_orders(id) ON DELETE SET NULL;

DO $$ BEGIN
  ALTER TABLE public.crm_opportunities
    ADD CONSTRAINT crm_opportunities_segment_check
    CHECK (segment IN ('service','product'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS idx_crm_opportunities_segment ON public.crm_opportunities(segment);

-- RLS: replace SELECT/UPDATE policies with segment-aware versions, and allow staff INSERT
DROP POLICY IF EXISTS "Company staff can view their site leads" ON public.public_site_leads;
DROP POLICY IF EXISTS "Company staff can update their site leads" ON public.public_site_leads;
DROP POLICY IF EXISTS "Company staff can insert site leads" ON public.public_site_leads;

CREATE POLICY "Company staff can view their site leads"
ON public.public_site_leads FOR SELECT
USING (
  has_role(auth.uid(), 'super_admin'::app_role)
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.company_id = public_site_leads.company_id
      AND (
        has_role(auth.uid(), 'director'::app_role)
        OR has_role(auth.uid(), 'admin'::app_role)
        OR (has_role(auth.uid(), 'coordinator'::app_role)
            AND (public_site_leads.segment IN ('service','unknown') OR public_site_leads.assigned_to = auth.uid()))
        OR ((has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
            AND (public_site_leads.segment IN ('product','unknown') OR public_site_leads.assigned_to = auth.uid()))
      )
  )
);

CREATE POLICY "Company staff can update their site leads"
ON public.public_site_leads FOR UPDATE
USING (
  has_role(auth.uid(), 'super_admin'::app_role)
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.company_id = public_site_leads.company_id
      AND (
        has_role(auth.uid(), 'director'::app_role)
        OR has_role(auth.uid(), 'admin'::app_role)
        OR (has_role(auth.uid(), 'coordinator'::app_role)
            AND (public_site_leads.segment IN ('service','unknown') OR public_site_leads.assigned_to = auth.uid()))
        OR ((has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'marketing'::app_role))
            AND (public_site_leads.segment IN ('product','unknown') OR public_site_leads.assigned_to = auth.uid()))
      )
  )
);

CREATE POLICY "Company staff can insert site leads"
ON public.public_site_leads FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.company_id = public_site_leads.company_id
      AND (
        has_role(auth.uid(), 'director'::app_role)
        OR has_role(auth.uid(), 'admin'::app_role)
        OR has_role(auth.uid(), 'coordinator'::app_role)
        OR has_role(auth.uid(), 'commercial'::app_role)
        OR has_role(auth.uid(), 'marketing'::app_role)
      )
  )
);
