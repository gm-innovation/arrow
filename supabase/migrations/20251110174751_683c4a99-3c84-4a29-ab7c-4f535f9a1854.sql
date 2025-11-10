-- Add new fields to service_orders table
ALTER TABLE service_orders
ADD COLUMN IF NOT EXISTS service_date_time timestamp with time zone,
ADD COLUMN IF NOT EXISTS location text,
ADD COLUMN IF NOT EXISTS access text,
ADD COLUMN IF NOT EXISTS single_report boolean DEFAULT false;

-- Create index for optimized searches by service_date_time
CREATE INDEX IF NOT EXISTS idx_service_orders_service_date_time 
ON service_orders(service_date_time);

-- Add helpful comment
COMMENT ON COLUMN service_orders.service_date_time IS 'Scheduled date and time for the service';
COMMENT ON COLUMN service_orders.location IS 'Service location details';
COMMENT ON COLUMN service_orders.access IS 'Access information for the service location';
COMMENT ON COLUMN service_orders.single_report IS 'Flag to generate a single report for all services in this order';