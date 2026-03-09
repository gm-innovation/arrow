
-- Table: client_legal_entities
CREATE TABLE public.client_legal_entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  legal_name TEXT NOT NULL,
  cnpj TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.client_legal_entities ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER update_client_legal_entities_updated_at
  BEFORE UPDATE ON public.client_legal_entities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE POLICY "Users can view legal entities of their company clients"
  ON public.client_legal_entities FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM clients c WHERE c.id = client_legal_entities.client_id AND c.company_id = user_company_id(auth.uid())
  ));

CREATE POLICY "Admins can manage legal entities"
  ON public.client_legal_entities FOR ALL
  USING (EXISTS (
    SELECT 1 FROM clients c WHERE c.id = client_legal_entities.client_id AND c.company_id = user_company_id(auth.uid())
  ));

-- Table: client_addresses
CREATE TABLE public.client_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  label TEXT DEFAULT 'Sede',
  cep TEXT,
  street TEXT,
  street_number TEXT,
  city TEXT,
  state TEXT,
  complement TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.client_addresses ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER update_client_addresses_updated_at
  BEFORE UPDATE ON public.client_addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE POLICY "Users can view addresses of their company clients"
  ON public.client_addresses FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM clients c WHERE c.id = client_addresses.client_id AND c.company_id = user_company_id(auth.uid())
  ));

CREATE POLICY "Admins can manage addresses"
  ON public.client_addresses FOR ALL
  USING (EXISTS (
    SELECT 1 FROM clients c WHERE c.id = client_addresses.client_id AND c.company_id = user_company_id(auth.uid())
  ));

-- Table: contact_vessel_links
CREATE TABLE public.contact_vessel_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES public.client_contacts(id) ON DELETE CASCADE,
  vessel_id UUID NOT NULL REFERENCES public.vessels(id) ON DELETE CASCADE,
  UNIQUE(contact_id, vessel_id)
);

ALTER TABLE public.contact_vessel_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view contact vessel links"
  ON public.contact_vessel_links FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM client_contacts cc
    JOIN clients c ON c.id = cc.client_id
    WHERE cc.id = contact_vessel_links.contact_id
    AND c.company_id = user_company_id(auth.uid())
  ));

CREATE POLICY "Admins can manage contact vessel links"
  ON public.contact_vessel_links FOR ALL
  USING (EXISTS (
    SELECT 1 FROM client_contacts cc
    JOIN clients c ON c.id = cc.client_id
    WHERE cc.id = contact_vessel_links.contact_id
    AND c.company_id = user_company_id(auth.uid())
  ));

-- Add is_general to client_contacts
ALTER TABLE public.client_contacts ADD COLUMN IF NOT EXISTS is_general BOOLEAN DEFAULT true;
