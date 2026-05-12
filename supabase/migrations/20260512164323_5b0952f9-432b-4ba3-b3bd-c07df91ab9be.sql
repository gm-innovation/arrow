ALTER TABLE public.public_site_leads
  ADD COLUMN IF NOT EXISTS opportunity_id uuid REFERENCES public.crm_opportunities(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS converted_at timestamptz;
CREATE INDEX IF NOT EXISTS idx_public_site_leads_opportunity ON public.public_site_leads(opportunity_id);