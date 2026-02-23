
-- ============================================
-- MÓDULO SUPRIMENTOS - Tabelas completas + RLS
-- ============================================

-- Tabela: purchase_requests
CREATE TABLE public.purchase_requests (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES public.profiles(id),
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL DEFAULT 'material',
  priority TEXT NOT NULL DEFAULT 'media',
  status TEXT NOT NULL DEFAULT 'draft',
  estimated_total NUMERIC(12,2) DEFAULT 0,
  justification TEXT,
  manager_approver_id UUID REFERENCES public.profiles(id),
  manager_approved_at TIMESTAMPTZ,
  director_approver_id UUID REFERENCES public.profiles(id),
  director_approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tabela: purchase_request_items
CREATE TABLE public.purchase_request_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  request_id UUID NOT NULL REFERENCES public.purchase_requests(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity NUMERIC(10,2) NOT NULL DEFAULT 1,
  unit TEXT NOT NULL DEFAULT 'un',
  estimated_unit_price NUMERIC(12,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_purchase_requests_company ON public.purchase_requests(company_id);
CREATE INDEX idx_purchase_requests_requester ON public.purchase_requests(requester_id);
CREATE INDEX idx_purchase_requests_status ON public.purchase_requests(status);
CREATE INDEX idx_purchase_request_items_request ON public.purchase_request_items(request_id);

-- Trigger updated_at
CREATE TRIGGER update_purchase_requests_updated_at
  BEFORE UPDATE ON public.purchase_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Trigger recalcular total
CREATE OR REPLACE FUNCTION public.recalculate_purchase_request_total()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _request_id UUID;
BEGIN
  _request_id := COALESCE(NEW.request_id, OLD.request_id);
  
  UPDATE purchase_requests
  SET estimated_total = (
    SELECT COALESCE(SUM(quantity * estimated_unit_price), 0)
    FROM purchase_request_items
    WHERE request_id = _request_id
  ),
  updated_at = now()
  WHERE id = _request_id;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER recalculate_purchase_total_on_item_change
  AFTER INSERT OR UPDATE OR DELETE ON public.purchase_request_items
  FOR EACH ROW
  EXECUTE FUNCTION public.recalculate_purchase_request_total();

-- RLS
ALTER TABLE public.purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_request_items ENABLE ROW LEVEL SECURITY;

-- purchase_requests policies
CREATE POLICY "Users can view purchase requests from their company"
  ON public.purchase_requests FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));

CREATE POLICY "Users can create purchase requests in their company"
  ON public.purchase_requests FOR INSERT TO authenticated
  WITH CHECK (company_id = public.user_company_id(auth.uid()) AND requester_id = auth.uid());

CREATE POLICY "Authorized users can update purchase requests"
  ON public.purchase_requests FOR UPDATE TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      requester_id = auth.uid()
      OR public.has_role(auth.uid(), 'compras')
      OR public.has_role(auth.uid(), 'manager')
      OR public.has_role(auth.uid(), 'director')
      OR public.has_role(auth.uid(), 'admin')
      OR public.has_role(auth.uid(), 'super_admin')
    )
  );

CREATE POLICY "Requester can delete draft purchase requests"
  ON public.purchase_requests FOR DELETE TO authenticated
  USING (requester_id = auth.uid() AND status = 'draft');

-- purchase_request_items policies
CREATE POLICY "Users can view items from company requests"
  ON public.purchase_request_items FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM purchase_requests pr
    WHERE pr.id = request_id AND pr.company_id = public.user_company_id(auth.uid())
  ));

CREATE POLICY "Users can insert items on own requests"
  ON public.purchase_request_items FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM purchase_requests pr
    WHERE pr.id = request_id AND pr.company_id = public.user_company_id(auth.uid())
    AND (pr.requester_id = auth.uid() OR public.has_role(auth.uid(), 'compras'))
  ));

CREATE POLICY "Users can update items on accessible requests"
  ON public.purchase_request_items FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM purchase_requests pr
    WHERE pr.id = request_id AND pr.company_id = public.user_company_id(auth.uid())
    AND (pr.requester_id = auth.uid() OR public.has_role(auth.uid(), 'compras'))
  ));

CREATE POLICY "Users can delete items on own draft requests"
  ON public.purchase_request_items FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM purchase_requests pr
    WHERE pr.id = request_id AND pr.requester_id = auth.uid() AND pr.status = 'draft'
  ));

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.purchase_requests;
