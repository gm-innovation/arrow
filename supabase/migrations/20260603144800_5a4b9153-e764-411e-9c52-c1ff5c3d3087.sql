-- Helper for updated_at if not present in public
CREATE OR REPLACE FUNCTION public.set_updated_at_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- 1) EPI items catalog
CREATE TABLE public.epi_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  ca_number TEXT,
  ca_expires_at DATE,
  size TEXT,
  description TEXT,
  min_stock INTEGER NOT NULL DEFAULT 0,
  current_stock INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.epi_items TO authenticated;
GRANT ALL ON public.epi_items TO service_role;
ALTER TABLE public.epi_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "epi_items select same company" ON public.epi_items FOR SELECT TO authenticated
USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "epi_items hr director insert" ON public.epi_items FOR INSERT TO authenticated
WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "epi_items hr director update" ON public.epi_items FOR UPDATE TO authenticated
USING (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "epi_items hr director delete" ON public.epi_items FOR DELETE TO authenticated
USING (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'));
CREATE TRIGGER trg_epi_items_updated BEFORE UPDATE ON public.epi_items
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_timestamp();

-- 2) Stock movements
CREATE TABLE public.epi_stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  epi_item_id UUID NOT NULL REFERENCES public.epi_items(id) ON DELETE CASCADE,
  movement_type TEXT NOT NULL CHECK (movement_type IN ('in','out','adjustment')),
  quantity INTEGER NOT NULL,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.epi_stock_movements TO authenticated;
GRANT ALL ON public.epi_stock_movements TO service_role;
ALTER TABLE public.epi_stock_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "epi_movements select same company" ON public.epi_stock_movements FOR SELECT TO authenticated
USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "epi_movements hr director insert" ON public.epi_stock_movements FOR INSERT TO authenticated
WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));

-- 3) Deliveries
CREATE TABLE public.epi_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  epi_item_id UUID NOT NULL REFERENCES public.epi_items(id) ON DELETE RESTRICT,
  recipient_profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 1,
  delivered_at DATE NOT NULL DEFAULT CURRENT_DATE,
  expires_at DATE,
  notes TEXT,
  signature_url TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.epi_deliveries TO authenticated;
GRANT ALL ON public.epi_deliveries TO service_role;
ALTER TABLE public.epi_deliveries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "epi_deliveries select hr director or self" ON public.epi_deliveries FOR SELECT TO authenticated
USING (recipient_profile_id = auth.uid()
  OR public.has_role(auth.uid(),'hr')
  OR public.has_role(auth.uid(),'director')
  OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "epi_deliveries hr director insert" ON public.epi_deliveries FOR INSERT TO authenticated
WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "epi_deliveries hr director update" ON public.epi_deliveries FOR UPDATE TO authenticated
USING (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "epi_deliveries hr director delete" ON public.epi_deliveries FOR DELETE TO authenticated
USING (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'));
CREATE TRIGGER trg_epi_deliveries_updated BEFORE UPDATE ON public.epi_deliveries
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_timestamp();

-- 4) HR Partnerships
CREATE TABLE public.hr_partnerships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT,
  description TEXT,
  benefit TEXT,
  contact TEXT,
  link TEXT,
  logo_url TEXT,
  valid_from DATE,
  valid_until DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hr_partnerships TO authenticated;
GRANT ALL ON public.hr_partnerships TO service_role;
ALTER TABLE public.hr_partnerships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hr_partnerships select same company" ON public.hr_partnerships FOR SELECT TO authenticated
USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "hr_partnerships hr director insert" ON public.hr_partnerships FOR INSERT TO authenticated
WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin')));
CREATE POLICY "hr_partnerships hr director update" ON public.hr_partnerships FOR UPDATE TO authenticated
USING (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "hr_partnerships hr director delete" ON public.hr_partnerships FOR DELETE TO authenticated
USING (public.has_role(auth.uid(),'hr') OR public.has_role(auth.uid(),'director') OR public.has_role(auth.uid(),'super_admin'));
CREATE TRIGGER trg_hr_partnerships_updated BEFORE UPDATE ON public.hr_partnerships
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_timestamp();