-- Add coordinator_id column to service_orders table
ALTER TABLE public.service_orders 
ADD COLUMN coordinator_id uuid REFERENCES profiles(id) ON DELETE SET NULL;