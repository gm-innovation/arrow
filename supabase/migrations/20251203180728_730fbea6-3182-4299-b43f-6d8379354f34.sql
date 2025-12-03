-- Create client_contacts table
CREATE TABLE public.client_contacts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  role TEXT,
  email TEXT,
  phone TEXT,
  whatsapp TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.client_contacts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can manage client contacts in their company"
ON public.client_contacts
FOR ALL
USING (
  has_role(auth.uid(), 'admin'::app_role) AND 
  EXISTS (
    SELECT 1 FROM clients c 
    WHERE c.id = client_contacts.client_id 
    AND c.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Users can view client contacts in their company"
ON public.client_contacts
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM clients c 
    WHERE c.id = client_contacts.client_id 
    AND c.company_id = user_company_id(auth.uid())
  )
);

-- Trigger for updated_at
CREATE TRIGGER update_client_contacts_updated_at
BEFORE UPDATE ON public.client_contacts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();