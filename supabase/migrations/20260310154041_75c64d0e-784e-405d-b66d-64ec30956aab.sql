
ALTER TABLE companies ADD COLUMN IF NOT EXISTS omie_app_key text;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS omie_app_secret text;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS omie_sync_enabled boolean DEFAULT false;

ALTER TABLE service_orders ADD COLUMN IF NOT EXISTS omie_os_id bigint;
ALTER TABLE service_orders ADD COLUMN IF NOT EXISTS omie_os_integration_code text;

ALTER TABLE clients ADD COLUMN IF NOT EXISTS omie_client_id bigint;
