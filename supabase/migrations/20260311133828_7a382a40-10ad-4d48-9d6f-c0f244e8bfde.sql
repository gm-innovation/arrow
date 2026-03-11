DROP INDEX IF EXISTS idx_clients_company_omie;
ALTER TABLE public.clients ADD CONSTRAINT uq_clients_company_omie UNIQUE (company_id, omie_client_id);