
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS cep text;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS street text;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS street_number text;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS state text;

ALTER TABLE public.crm_buyers ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;
ALTER TABLE public.crm_buyers ADD COLUMN IF NOT EXISTS is_primary boolean DEFAULT false;

ALTER TABLE public.crm_client_recurrences ADD COLUMN IF NOT EXISTS advance_notice_days integer DEFAULT 30;
