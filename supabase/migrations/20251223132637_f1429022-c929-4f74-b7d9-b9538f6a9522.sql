-- Add requester_contact_id column to service_orders
ALTER TABLE public.service_orders 
ADD COLUMN requester_contact_id uuid REFERENCES client_contacts(id) ON DELETE SET NULL;