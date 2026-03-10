
-- Catálogo local de produtos do estoque
CREATE TABLE public.stock_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES public.companies(id) NOT NULL,
  external_product_id integer,
  external_product_code text,
  name text NOT NULL,
  category text,
  unit text DEFAULT 'un',
  current_quantity numeric DEFAULT 0,
  min_quantity numeric DEFAULT 0,
  unit_cost numeric DEFAULT 0,
  sell_price numeric DEFAULT 0,
  is_active boolean DEFAULT true,
  last_synced_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, external_product_id)
);

ALTER TABLE public.stock_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view stock_products of their company"
  ON public.stock_products FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert stock_products for their company"
  ON public.stock_products FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update stock_products of their company"
  ON public.stock_products FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can delete stock_products of their company"
  ON public.stock_products FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- Vendas comerciais
CREATE TABLE public.crm_sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES public.companies(id) NOT NULL,
  opportunity_id uuid REFERENCES public.crm_opportunities(id),
  client_id uuid REFERENCES public.clients(id),
  sale_number text,
  status text DEFAULT 'draft',
  total_amount numeric DEFAULT 0,
  notes text,
  created_by uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.crm_sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view crm_sales of their company"
  ON public.crm_sales FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert crm_sales for their company"
  ON public.crm_sales FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update crm_sales of their company"
  ON public.crm_sales FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can delete crm_sales of their company"
  ON public.crm_sales FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- Itens da venda
CREATE TABLE public.crm_sale_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid REFERENCES public.crm_sales(id) ON DELETE CASCADE NOT NULL,
  stock_product_id uuid REFERENCES public.stock_products(id),
  name text NOT NULL,
  quantity numeric NOT NULL DEFAULT 1,
  unit_value numeric DEFAULT 0,
  markup_percentage numeric DEFAULT 0,
  total_value numeric DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.crm_sale_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view crm_sale_items via sale company"
  ON public.crm_sale_items FOR SELECT TO authenticated
  USING (sale_id IN (SELECT id FROM public.crm_sales WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));

CREATE POLICY "Users can insert crm_sale_items via sale company"
  ON public.crm_sale_items FOR INSERT TO authenticated
  WITH CHECK (sale_id IN (SELECT id FROM public.crm_sales WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));

CREATE POLICY "Users can update crm_sale_items via sale company"
  ON public.crm_sale_items FOR UPDATE TO authenticated
  USING (sale_id IN (SELECT id FROM public.crm_sales WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));

CREATE POLICY "Users can delete crm_sale_items via sale company"
  ON public.crm_sale_items FOR DELETE TO authenticated
  USING (sale_id IN (SELECT id FROM public.crm_sales WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));
