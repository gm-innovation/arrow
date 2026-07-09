ALTER TABLE public.clients
ADD COLUMN IF NOT EXISTS crm_visible boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.clients.crm_visible IS 'Controls whether this client can appear in Commercial/Marketing CRM selectors.';

CREATE OR REPLACE FUNCTION public.crm_normalize_name(_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT trim(regexp_replace(
    translate(lower(coalesce(_value, '')),
      'áàãâäéèêëíìîïóòõôöúùûüçñÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑ',
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    ),
    '\s+',
    ' ',
    'g'
  ));
$$;

CREATE OR REPLACE FUNCTION public.crm_document_digits(_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT regexp_replace(coalesce(_value, ''), '\D', '', 'g');
$$;

CREATE OR REPLACE FUNCTION public.crm_is_cpf_like(_value text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT length(public.crm_document_digits(_value)) = 11;
$$;

CREATE OR REPLACE FUNCTION public.crm_is_commercial_client_eligible(_client public.clients)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    coalesce(_client.crm_visible, true)
    AND coalesce(_client.name, '') <> ''
    AND NOT coalesce(_client.ignore_omie_sync, false)
    AND NOT EXISTS (
      SELECT 1
      FROM public.omie_sync_blocklist b
      WHERE b.company_id = _client.company_id
        AND (
          (b.omie_client_id IS NOT NULL AND _client.omie_client_id IS NOT NULL AND b.omie_client_id = _client.omie_client_id::text)
          OR (b.cnpj IS NOT NULL AND _client.cnpj IS NOT NULL AND public.crm_document_digits(b.cnpj) = public.crm_document_digits(_client.cnpj))
        )
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.company_id = _client.company_id
        AND p.full_name IS NOT NULL
        AND public.crm_normalize_name(p.full_name) = public.crm_normalize_name(_client.name)
    )
    AND NOT (
      public.crm_is_cpf_like(_client.cnpj)
      AND coalesce(_client.entity_type, 'pj') = 'pj'
    );
$$;

CREATE OR REPLACE VIEW public.crm_client_options
WITH (security_invoker = on)
AS
SELECT
  c.id,
  c.company_id,
  c.name,
  c.cnpj,
  c.entity_type,
  c.commercial_status,
  c.omie_client_id,
  c.parent_client_id,
  c.created_at,
  c.updated_at
FROM public.clients c
WHERE public.crm_is_commercial_client_eligible(c);

GRANT SELECT ON public.crm_client_options TO authenticated;
GRANT SELECT ON public.crm_client_options TO service_role;

CREATE OR REPLACE FUNCTION public.prevent_client_employee_collision()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF coalesce(NEW.crm_visible, true)
     AND coalesce(NEW.entity_type, 'pj') <> 'pf'
     AND EXISTS (
       SELECT 1
       FROM public.profiles p
       WHERE p.company_id = NEW.company_id
         AND p.full_name IS NOT NULL
         AND public.crm_normalize_name(p.full_name) = public.crm_normalize_name(NEW.name)
     ) THEN
    RAISE EXCEPTION 'Este nome pertence a um colaborador e não pode ser cadastrado como cliente comercial. Marque como Pessoa Física e confirme a visibilidade apenas se for realmente cliente.';
  END IF;

  IF public.crm_is_cpf_like(NEW.cnpj) AND coalesce(NEW.entity_type, 'pj') = 'pj' THEN
    NEW.entity_type := 'pf';
    NEW.crm_visible := false;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_client_employee_collision ON public.clients;
CREATE TRIGGER trg_prevent_client_employee_collision
BEFORE INSERT OR UPDATE OF name, company_id, entity_type, cnpj, crm_visible
ON public.clients
FOR EACH ROW
EXECUTE FUNCTION public.prevent_client_employee_collision();