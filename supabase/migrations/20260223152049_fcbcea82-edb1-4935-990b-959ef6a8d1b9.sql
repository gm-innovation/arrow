
-- 1. Expandir tabela clients com campos comerciais
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS segment text,
  ADD COLUMN IF NOT EXISTS commercial_status text DEFAULT 'prospect',
  ADD COLUMN IF NOT EXISTS annual_revenue numeric,
  ADD COLUMN IF NOT EXISTS source text,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS last_contact_date date;

-- 2. Tabela crm_buyers
CREATE TABLE IF NOT EXISTS public.crm_buyers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  role text,
  email text,
  phone text,
  influence_level text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_buyers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage buyers in their company"
  ON public.crm_buyers FOR ALL
  USING (
    company_id = user_company_id(auth.uid())
    AND (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
  );

CREATE POLICY "Manager can view buyers in their company"
  ON public.crm_buyers FOR SELECT
  USING (
    company_id = user_company_id(auth.uid())
    AND has_role(auth.uid(), 'manager'::app_role)
  );

CREATE POLICY "Super admin can manage all buyers"
  ON public.crm_buyers FOR ALL
  USING (has_role(auth.uid(), 'super_admin'::app_role));

-- 3. Tabela crm_opportunities
CREATE TABLE IF NOT EXISTS public.crm_opportunities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  buyer_id uuid REFERENCES public.crm_buyers(id) ON DELETE SET NULL,
  assigned_to uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  opportunity_type text,
  stage text NOT NULL DEFAULT 'identified',
  priority text DEFAULT 'medium',
  estimated_value numeric,
  probability integer DEFAULT 0,
  expected_close_date date,
  closed_at timestamptz,
  loss_reason text,
  notes text,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_opportunities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage opportunities in their company"
  ON public.crm_opportunities FOR ALL
  USING (
    company_id = user_company_id(auth.uid())
    AND (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
  );

CREATE POLICY "Manager can view opportunities in their company"
  ON public.crm_opportunities FOR SELECT
  USING (
    company_id = user_company_id(auth.uid())
    AND has_role(auth.uid(), 'manager'::app_role)
  );

CREATE POLICY "Super admin can manage all opportunities"
  ON public.crm_opportunities FOR ALL
  USING (has_role(auth.uid(), 'super_admin'::app_role));

-- 4. Tabela crm_opportunity_activities
CREATE TABLE IF NOT EXISTS public.crm_opportunity_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  opportunity_id uuid NOT NULL REFERENCES public.crm_opportunities(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  activity_type text NOT NULL,
  description text,
  activity_date timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crm_opportunity_activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commercial and Admin can manage activities in their company"
  ON public.crm_opportunity_activities FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.crm_opportunities o
      WHERE o.id = crm_opportunity_activities.opportunity_id
      AND o.company_id = user_company_id(auth.uid())
    )
    AND (has_role(auth.uid(), 'commercial'::app_role) OR has_role(auth.uid(), 'admin'::app_role))
  );

CREATE POLICY "Manager can view activities in their company"
  ON public.crm_opportunity_activities FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.crm_opportunities o
      WHERE o.id = crm_opportunity_activities.opportunity_id
      AND o.company_id = user_company_id(auth.uid())
    )
    AND has_role(auth.uid(), 'manager'::app_role)
  );

CREATE POLICY "Super admin can manage all activities"
  ON public.crm_opportunity_activities FOR ALL
  USING (has_role(auth.uid(), 'super_admin'::app_role));

-- 5. RLS para clients - commercial pode ver/gerenciar clientes da sua empresa
CREATE POLICY "Commercial can manage clients in their company"
  ON public.clients FOR ALL
  USING (
    has_role(auth.uid(), 'commercial'::app_role)
    AND company_id = user_company_id(auth.uid())
  );

-- 6. Triggers updated_at
CREATE TRIGGER update_crm_buyers_updated_at
  BEFORE UPDATE ON public.crm_buyers
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_crm_opportunities_updated_at
  BEFORE UPDATE ON public.crm_opportunities
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- 7. Indexes
CREATE INDEX IF NOT EXISTS idx_crm_buyers_client_id ON public.crm_buyers(client_id);
CREATE INDEX IF NOT EXISTS idx_crm_buyers_company_id ON public.crm_buyers(company_id);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_company_id ON public.crm_opportunities(company_id);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_client_id ON public.crm_opportunities(client_id);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_stage ON public.crm_opportunities(stage);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_assigned_to ON public.crm_opportunities(assigned_to);
CREATE INDEX IF NOT EXISTS idx_crm_opportunity_activities_opportunity_id ON public.crm_opportunity_activities(opportunity_id);
