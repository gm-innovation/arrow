-- Create os_materials table to store materials linked to service orders
CREATE TABLE public.os_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
  external_product_id INTEGER,
  external_product_code VARCHAR(50),
  name TEXT NOT NULL,
  unit_value NUMERIC(10,2) NOT NULL,
  quantity INTEGER DEFAULT 1,
  used BOOLEAN DEFAULT true,
  source VARCHAR(20) DEFAULT 'eva',
  synced_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add columns to measurement_materials for external tracking
ALTER TABLE public.measurement_materials
ADD COLUMN IF NOT EXISTS external_product_id INTEGER,
ADD COLUMN IF NOT EXISTS external_product_code VARCHAR(50),
ADD COLUMN IF NOT EXISTS source VARCHAR(20) DEFAULT 'manual';

-- Enable RLS on os_materials
ALTER TABLE public.os_materials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for os_materials
-- Admins can manage materials in their company
CREATE POLICY "Admins can manage os_materials in their company"
ON public.os_materials FOR ALL
USING (
  has_role(auth.uid(), 'admin'::app_role) 
  AND EXISTS (
    SELECT 1 FROM service_orders so 
    WHERE so.id = os_materials.service_order_id 
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- Technicians can view and update materials for their assigned tasks
CREATE POLICY "Technicians can view os_materials for their orders"
ON public.os_materials FOR SELECT
USING (
  is_tech_assigned_to_order(auth.uid(), service_order_id)
);

CREATE POLICY "Technicians can update os_materials for their orders"
ON public.os_materials FOR UPDATE
USING (
  is_tech_assigned_to_order(auth.uid(), service_order_id)
);

-- Users can view os_materials in their company
CREATE POLICY "Users can view os_materials in their company"
ON public.os_materials FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM service_orders so 
    WHERE so.id = os_materials.service_order_id 
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- Create trigger for updated_at
CREATE TRIGGER update_os_materials_updated_at
BEFORE UPDATE ON public.os_materials
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();