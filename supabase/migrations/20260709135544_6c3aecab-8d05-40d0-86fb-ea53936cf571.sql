DROP VIEW IF EXISTS public.crm_client_options;

CREATE VIEW public.crm_client_options
WITH (security_invoker = on) AS
SELECT
  c.id,
  c.company_id,
  c.name,
  c.cnpj,
  c.entity_type,
  c.commercial_status,
  c.omie_client_id,
  c.parent_client_id,
  c.email,
  c.phone,
  c.address,
  c.contact_person,
  c.segment,
  c.annual_revenue,
  c.source,
  c.notes,
  c.last_contact_date,
  c.ignore_omie_sync,
  c.crm_visible,
  c.cep,
  c.street,
  c.street_number,
  c.city,
  c.state,
  c.created_at,
  c.updated_at
FROM public.clients c
WHERE public.crm_is_commercial_client_eligible(c.*);

GRANT SELECT ON public.crm_client_options TO authenticated;
GRANT SELECT ON public.crm_client_options TO service_role;