
ALTER TABLE public.service_orders ADD COLUMN IF NOT EXISTS is_docking boolean DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS scheduled_date date;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS scheduled_time time;
