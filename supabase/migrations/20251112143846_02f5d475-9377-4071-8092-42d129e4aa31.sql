-- Create visit_type enum
CREATE TYPE visit_type AS ENUM ('initial', 'continuation', 'return');

-- Create service_visits table
CREATE TABLE public.service_visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  visit_number INTEGER NOT NULL,
  visit_type visit_type NOT NULL DEFAULT 'initial',
  visit_date DATE NOT NULL,
  scheduled_by UUID REFERENCES public.profiles(id),
  created_by UUID REFERENCES public.profiles(id),
  return_reason TEXT,
  status service_order_status DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(service_order_id, visit_number),
  CHECK (visit_type != 'return' OR return_reason IS NOT NULL)
);

-- Enable RLS
ALTER TABLE public.service_visits ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX idx_visits_order ON public.service_visits(service_order_id);
CREATE INDEX idx_visits_date ON public.service_visits(visit_date);
CREATE INDEX idx_visits_type ON public.service_visits(visit_type);

-- Create visit_technicians table
CREATE TABLE public.visit_technicians (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visit_id UUID NOT NULL REFERENCES public.service_visits(id) ON DELETE CASCADE,
  technician_id UUID NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  is_lead BOOLEAN DEFAULT FALSE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  assigned_by UUID REFERENCES public.profiles(id),
  
  UNIQUE(visit_id, technician_id)
);

-- Enable RLS
ALTER TABLE public.visit_technicians ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX idx_visit_techs_visit ON public.visit_technicians(visit_id);
CREATE INDEX idx_visit_techs_tech ON public.visit_technicians(technician_id);

-- Add visit_id to task_reports
ALTER TABLE public.task_reports 
ADD COLUMN visit_id UUID REFERENCES public.service_visits(id);

-- Create trigger to update updated_at
CREATE TRIGGER update_service_visits_updated_at
BEFORE UPDATE ON public.service_visits
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();

-- Create function to automatically create initial visit
CREATE OR REPLACE FUNCTION public.create_initial_visit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.service_visits (
    service_order_id,
    visit_number,
    visit_type,
    visit_date,
    created_by,
    status
  ) VALUES (
    NEW.id,
    1,
    'initial',
    COALESCE(NEW.scheduled_date, CURRENT_DATE),
    auth.uid(),
    NEW.status
  );
  RETURN NEW;
END;
$$;

-- Create trigger for initial visit
CREATE TRIGGER on_service_order_created
AFTER INSERT ON public.service_orders
FOR EACH ROW
EXECUTE FUNCTION public.create_initial_visit();

-- RLS Policies for service_visits

-- Technicians can create continuation visits
CREATE POLICY "Technicians can create continuation visits"
ON public.service_visits FOR INSERT
WITH CHECK (
  visit_type = 'continuation' 
  AND created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.tasks
    JOIN public.technicians ON tasks.assigned_to = technicians.id
    WHERE tasks.service_order_id = service_visits.service_order_id
    AND technicians.user_id = auth.uid()
  )
);

-- Admins can create return visits
CREATE POLICY "Admins can create return visits"
ON public.service_visits FOR INSERT
WITH CHECK (
  visit_type = 'return'
  AND has_role(auth.uid(), 'admin'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.service_orders
    WHERE id = service_visits.service_order_id
    AND company_id = user_company_id(auth.uid())
  )
);

-- Users can view visits from their company or where they are assigned
CREATE POLICY "Users can view relevant visits"
ON public.service_visits FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.service_orders
    WHERE id = service_visits.service_order_id
    AND company_id = user_company_id(auth.uid())
  )
  OR EXISTS (
    SELECT 1 FROM public.visit_technicians vt
    JOIN public.technicians t ON vt.technician_id = t.id
    WHERE vt.visit_id = service_visits.id
    AND t.user_id = auth.uid()
  )
);

-- Admins can update visits in their company
CREATE POLICY "Admins can update visits"
ON public.service_visits FOR UPDATE
USING (
  has_role(auth.uid(), 'admin'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.service_orders
    WHERE id = service_visits.service_order_id
    AND company_id = user_company_id(auth.uid())
  )
);

-- RLS Policies for visit_technicians

-- Admins can manage visit technicians
CREATE POLICY "Admins can manage visit technicians"
ON public.visit_technicians FOR ALL
USING (
  has_role(auth.uid(), 'admin'::app_role)
  AND EXISTS (
    SELECT 1 FROM public.service_visits sv
    JOIN public.service_orders so ON sv.service_order_id = so.id
    WHERE sv.id = visit_technicians.visit_id
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- Technicians can view their assignments
CREATE POLICY "Technicians can view their assignments"
ON public.visit_technicians FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.technicians
    WHERE id = visit_technicians.technician_id
    AND user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.service_visits sv
    JOIN public.service_orders so ON sv.service_order_id = so.id
    WHERE sv.id = visit_technicians.visit_id
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- Update task_reports RLS to allow viewing by service order history
CREATE POLICY "Technicians can view reports from their service orders"
ON public.task_reports FOR SELECT
USING (
  EXISTS (
    SELECT 1 
    FROM public.tasks
    JOIN public.service_orders so ON tasks.service_order_id = so.id
    JOIN public.service_visits sv ON sv.service_order_id = so.id
    JOIN public.visit_technicians vt ON vt.visit_id = sv.id
    JOIN public.technicians t ON vt.technician_id = t.id
    WHERE tasks.id::text = task_reports.task_id
    AND t.user_id = auth.uid()
  )
  OR has_role(auth.uid(), 'admin'::app_role)
);