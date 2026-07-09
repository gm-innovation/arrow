CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

CREATE INDEX IF NOT EXISTS idx_clients_company_name
  ON public.clients (company_id, name);

CREATE INDEX IF NOT EXISTS idx_clients_name_trgm
  ON public.clients USING gin (name extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_profiles_company_normalized_full_name
  ON public.profiles (company_id, public.crm_normalize_name(full_name))
  WHERE full_name IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_omie_sync_blocklist_company_omie_client_id
  ON public.omie_sync_blocklist (company_id, omie_client_id)
  WHERE omie_client_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_omie_sync_blocklist_company_document_digits
  ON public.omie_sync_blocklist (company_id, public.crm_document_digits(cnpj))
  WHERE cnpj IS NOT NULL;