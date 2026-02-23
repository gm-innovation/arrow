
-- ============================================
-- FASE 3B: Catálogo de Produtos/Serviços
-- ============================================

-- Tabela de produtos/serviços do CRM
CREATE TABLE public.crm_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  category text,
  type text NOT NULL DEFAULT 'service',
  is_recurring boolean DEFAULT false,
  reference_value numeric,
  description text,
  active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage products in their company"
ON public.crm_products FOR ALL
USING (
  (company_id = user_company_id(auth.uid())) AND 
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Manager can view products in their company"
ON public.crm_products FOR SELECT
USING (
  (company_id = user_company_id(auth.uid())) AND has_role(auth.uid(), 'manager'::app_role)
);

CREATE POLICY "Super admin can manage all products"
ON public.crm_products FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- Tabela de vínculo oportunidade-produto
CREATE TABLE public.crm_opportunity_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  opportunity_id uuid NOT NULL REFERENCES public.crm_opportunities(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.crm_products(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1,
  unit_value numeric,
  total_value numeric,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_opportunity_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage opportunity products"
ON public.crm_opportunity_products FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM crm_opportunities o
    WHERE o.id = crm_opportunity_products.opportunity_id
    AND o.company_id = user_company_id(auth.uid())
  ) AND (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Manager can view opportunity products"
ON public.crm_opportunity_products FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM crm_opportunities o
    WHERE o.id = crm_opportunity_products.opportunity_id
    AND o.company_id = user_company_id(auth.uid())
  ) AND has_role(auth.uid(), 'manager'::app_role)
);

CREATE POLICY "Super admin can manage all opportunity products"
ON public.crm_opportunity_products FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- ============================================
-- FASE 3C: Recorrências e Agendamentos
-- ============================================

CREATE TABLE public.crm_recurrence_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.crm_products(id) ON DELETE SET NULL,
  name text NOT NULL,
  period_type text NOT NULL DEFAULT 'monthly',
  period_value integer NOT NULL DEFAULT 1,
  notification_days_before integer DEFAULT 30,
  description text,
  active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_recurrence_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage recurrence templates"
ON public.crm_recurrence_templates FOR ALL
USING (
  (company_id = user_company_id(auth.uid())) AND
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Manager can view recurrence templates"
ON public.crm_recurrence_templates FOR SELECT
USING (
  (company_id = user_company_id(auth.uid())) AND has_role(auth.uid(), 'manager'::app_role)
);

CREATE POLICY "Super admin can manage all recurrence templates"
ON public.crm_recurrence_templates FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

CREATE TABLE public.crm_client_recurrences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  template_id uuid REFERENCES public.crm_recurrence_templates(id) ON DELETE SET NULL,
  product_id uuid REFERENCES public.crm_products(id) ON DELETE SET NULL,
  assigned_to uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  recurrence_type text,
  periodicity text NOT NULL DEFAULT 'monthly',
  next_date date NOT NULL,
  last_executed_date date,
  status text NOT NULL DEFAULT 'active',
  estimated_value numeric,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_client_recurrences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage client recurrences"
ON public.crm_client_recurrences FOR ALL
USING (
  (company_id = user_company_id(auth.uid())) AND
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Manager can view client recurrences"
ON public.crm_client_recurrences FOR SELECT
USING (
  (company_id = user_company_id(auth.uid())) AND has_role(auth.uid(), 'manager'::app_role)
);

CREATE POLICY "Super admin can manage all client recurrences"
ON public.crm_client_recurrences FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- ============================================
-- FASE 3D: Medições - RLS para commercial
-- ============================================

CREATE POLICY "Commercial can view company measurements"
ON public.measurements FOR SELECT
USING (
  has_role(auth.uid(), 'commercial'::app_role) AND
  EXISTS (
    SELECT 1 FROM service_orders so
    WHERE so.id = measurements.service_order_id
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- ============================================
-- FASE 3F: Base de Conhecimento
-- ============================================

CREATE TABLE public.crm_knowledge_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.crm_products(id) ON DELETE SET NULL,
  author_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  category text,
  tags text[],
  published boolean DEFAULT true,
  title text NOT NULL,
  content text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_knowledge_base ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage knowledge base"
ON public.crm_knowledge_base FOR ALL
USING (
  (company_id = user_company_id(auth.uid())) AND
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Manager can view knowledge base"
ON public.crm_knowledge_base FOR SELECT
USING (
  (company_id = user_company_id(auth.uid())) AND has_role(auth.uid(), 'manager'::app_role)
);

CREATE POLICY "Super admin can manage all knowledge base"
ON public.crm_knowledge_base FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

CREATE TABLE public.crm_reference_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  knowledge_base_id uuid REFERENCES public.crm_knowledge_base(id) ON DELETE SET NULL,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_url text NOT NULL,
  file_type text,
  category text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_reference_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage reference documents"
ON public.crm_reference_documents FOR ALL
USING (
  (company_id = user_company_id(auth.uid())) AND
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Manager can view reference documents"
ON public.crm_reference_documents FOR SELECT
USING (
  (company_id = user_company_id(auth.uid())) AND has_role(auth.uid(), 'manager'::app_role)
);

CREATE POLICY "Super admin can manage all reference documents"
ON public.crm_reference_documents FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- ============================================
-- FASE 3H: Logs de integração
-- ============================================

CREATE TABLE public.crm_integration_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  action text NOT NULL,
  entity_type text,
  entity_id text,
  details jsonb,
  status text NOT NULL DEFAULT 'success',
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_integration_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view integration logs"
ON public.crm_integration_logs FOR ALL
USING (
  (company_id = user_company_id(auth.uid())) AND has_role(auth.uid(), 'admin'::app_role)
);

CREATE POLICY "Super admin can manage all integration logs"
ON public.crm_integration_logs FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- Storage bucket para documentos de referência
INSERT INTO storage.buckets (id, name, public) VALUES ('crm-documents', 'crm-documents', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Commercial users can upload crm documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'crm-documents' AND
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Commercial users can view crm documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'crm-documents' AND
  (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'manager'::app_role))
);

CREATE POLICY "Admin can delete crm documents"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'crm-documents' AND has_role(auth.uid(), 'admin'::app_role)
);
