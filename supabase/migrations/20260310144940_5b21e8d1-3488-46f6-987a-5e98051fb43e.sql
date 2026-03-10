
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS docking_activity_group uuid;
ALTER TABLE public.service_orders ADD COLUMN IF NOT EXISTS parent_docking_id uuid REFERENCES public.service_orders(id);
