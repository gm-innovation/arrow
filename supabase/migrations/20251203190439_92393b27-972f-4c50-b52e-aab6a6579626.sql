-- ==========================================
-- 1. SISTEMA DE CHECKLISTS CONFIGURÁVEIS
-- ==========================================

-- Tabela de templates de checklist
CREATE TABLE public.checklist_templates (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  task_type_id UUID REFERENCES public.task_types(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_mandatory BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Itens do checklist template
CREATE TABLE public.checklist_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  template_id UUID NOT NULL REFERENCES public.checklist_templates(id) ON DELETE CASCADE,
  item_order INTEGER NOT NULL DEFAULT 0,
  description TEXT NOT NULL,
  item_type TEXT NOT NULL DEFAULT 'boolean', -- boolean, text, number, photo
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Respostas do checklist (preenchido pelo técnico)
CREATE TABLE public.checklist_responses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES public.checklist_templates(id) ON DELETE CASCADE,
  technician_id UUID NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Respostas individuais de cada item
CREATE TABLE public.checklist_item_responses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  response_id UUID NOT NULL REFERENCES public.checklist_responses(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.checklist_items(id) ON DELETE CASCADE,
  value_boolean BOOLEAN,
  value_text TEXT,
  value_number NUMERIC,
  value_photo_path TEXT,
  answered_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- 2. GEOLOCALIZAÇÃO DE TÉCNICOS
-- ==========================================

-- Tabela de localizações dos técnicos
CREATE TABLE public.technician_locations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  technician_id UUID NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
  latitude NUMERIC(10, 8) NOT NULL,
  longitude NUMERIC(11, 8) NOT NULL,
  accuracy NUMERIC,
  location_type TEXT NOT NULL DEFAULT 'tracking', -- check_in, check_out, tracking
  address TEXT,
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índice para consultas de localização por técnico e data
CREATE INDEX idx_technician_locations_tech_date ON public.technician_locations(technician_id, recorded_at DESC);

-- ==========================================
-- 3. IA PROATIVA - HISTÓRICO DE ANÁLISES
-- ==========================================

-- Tabela para padrões de falha identificados
CREATE TABLE public.ai_failure_patterns (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  vessel_id UUID REFERENCES public.vessels(id) ON DELETE SET NULL,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  pattern_type TEXT NOT NULL, -- recurrent_issue, seasonal, equipment_related
  description TEXT NOT NULL,
  occurrences INTEGER DEFAULT 1,
  last_occurrence TIMESTAMP WITH TIME ZONE,
  suggested_action TEXT,
  confidence_score NUMERIC(3, 2),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabela para previsão de tempo de tarefas
CREATE TABLE public.task_time_estimates (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  task_type_id UUID REFERENCES public.task_types(id) ON DELETE SET NULL,
  vessel_type TEXT,
  average_duration_minutes INTEGER,
  min_duration_minutes INTEGER,
  max_duration_minutes INTEGER,
  sample_count INTEGER DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- ==========================================
-- RLS POLICIES
-- ==========================================

-- Checklist Templates
ALTER TABLE public.checklist_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage checklist templates"
ON public.checklist_templates FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role) AND company_id = user_company_id(auth.uid()));

CREATE POLICY "Users can view checklist templates in their company"
ON public.checklist_templates FOR SELECT
USING (company_id = user_company_id(auth.uid()));

-- Checklist Items
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view checklist items in their company"
ON public.checklist_items FOR SELECT
USING (EXISTS (
  SELECT 1 FROM checklist_templates ct
  WHERE ct.id = checklist_items.template_id
  AND ct.company_id = user_company_id(auth.uid())
));

CREATE POLICY "Admins can manage checklist items"
ON public.checklist_items FOR ALL
USING (EXISTS (
  SELECT 1 FROM checklist_templates ct
  WHERE ct.id = checklist_items.template_id
  AND ct.company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'admin'::app_role)
));

-- Checklist Responses
ALTER TABLE public.checklist_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Technicians can manage their checklist responses"
ON public.checklist_responses FOR ALL
USING (EXISTS (
  SELECT 1 FROM technicians t
  WHERE t.id = checklist_responses.technician_id
  AND t.user_id = auth.uid()
));

CREATE POLICY "Admins can view checklist responses in their company"
ON public.checklist_responses FOR SELECT
USING (EXISTS (
  SELECT 1 FROM checklist_templates ct
  WHERE ct.id = checklist_responses.template_id
  AND ct.company_id = user_company_id(auth.uid())
));

-- Checklist Item Responses
ALTER TABLE public.checklist_item_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their item responses"
ON public.checklist_item_responses FOR ALL
USING (EXISTS (
  SELECT 1 FROM checklist_responses cr
  JOIN technicians t ON t.id = cr.technician_id
  WHERE cr.id = checklist_item_responses.response_id
  AND t.user_id = auth.uid()
));

CREATE POLICY "Admins can view item responses in their company"
ON public.checklist_item_responses FOR SELECT
USING (EXISTS (
  SELECT 1 FROM checklist_responses cr
  JOIN checklist_templates ct ON ct.id = cr.template_id
  WHERE cr.id = checklist_item_responses.response_id
  AND ct.company_id = user_company_id(auth.uid())
));

-- Technician Locations
ALTER TABLE public.technician_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Technicians can insert their own locations"
ON public.technician_locations FOR INSERT
WITH CHECK (EXISTS (
  SELECT 1 FROM technicians t
  WHERE t.id = technician_locations.technician_id
  AND t.user_id = auth.uid()
));

CREATE POLICY "Technicians can view their own locations"
ON public.technician_locations FOR SELECT
USING (EXISTS (
  SELECT 1 FROM technicians t
  WHERE t.id = technician_locations.technician_id
  AND t.user_id = auth.uid()
));

CREATE POLICY "Admins can view locations in their company"
ON public.technician_locations FOR SELECT
USING (EXISTS (
  SELECT 1 FROM technicians t
  WHERE t.id = technician_locations.technician_id
  AND t.company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'admin'::app_role)
));

-- AI Failure Patterns
ALTER TABLE public.ai_failure_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage failure patterns"
ON public.ai_failure_patterns FOR ALL
USING (company_id = user_company_id(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Users can view failure patterns in their company"
ON public.ai_failure_patterns FOR SELECT
USING (company_id = user_company_id(auth.uid()));

-- Task Time Estimates
ALTER TABLE public.task_time_estimates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view time estimates in their company"
ON public.task_time_estimates FOR SELECT
USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "System can manage time estimates"
ON public.task_time_estimates FOR ALL
USING (true);