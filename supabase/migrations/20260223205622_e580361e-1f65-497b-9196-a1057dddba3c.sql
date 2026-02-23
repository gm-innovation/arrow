
-- =============================================
-- MÓDULO FINANCEIRO - Tabelas e RLS
-- =============================================

-- 1. Categorias financeiras
CREATE TABLE public.finance_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category_type TEXT NOT NULL CHECK (category_type IN ('revenue', 'expense')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.finance_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "finance_categories_select" ON public.finance_categories FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_categories_insert" ON public.finance_categories FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_categories_update" ON public.finance_categories FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_categories_delete" ON public.finance_categories FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()) AND public.has_role(auth.uid(), 'financeiro'));

-- 2. Contas a Pagar
CREATE TABLE public.finance_payables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  supplier_name TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES public.finance_categories(id) ON DELETE SET NULL,
  amount NUMERIC(14,2) NOT NULL,
  paid_amount NUMERIC(14,2) DEFAULT 0,
  due_date DATE NOT NULL,
  payment_date DATE,
  invoice_number TEXT,
  purchase_request_id UUID REFERENCES public.purchase_requests(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'partial', 'paid', 'overdue', 'cancelled')),
  notes TEXT,
  approved_by UUID REFERENCES public.profiles(id),
  approved_at TIMESTAMPTZ,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.finance_payables ENABLE ROW LEVEL SECURITY;

CREATE POLICY "finance_payables_select" ON public.finance_payables FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_payables_insert" ON public.finance_payables FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_payables_update" ON public.finance_payables FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_payables_delete" ON public.finance_payables FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()) AND public.has_role(auth.uid(), 'financeiro'));

-- 3. Contas a Receber
CREATE TABLE public.finance_receivables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  client_name TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES public.finance_categories(id) ON DELETE SET NULL,
  amount NUMERIC(14,2) NOT NULL,
  received_amount NUMERIC(14,2) DEFAULT 0,
  due_date DATE NOT NULL,
  received_date DATE,
  invoice_number TEXT,
  measurement_id UUID, -- referência a medições (sem FK por agora)
  status TEXT NOT NULL DEFAULT 'invoiced' CHECK (status IN ('invoiced', 'partial', 'paid', 'overdue', 'cancelled')),
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.finance_receivables ENABLE ROW LEVEL SECURITY;

CREATE POLICY "finance_receivables_select" ON public.finance_receivables FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_receivables_insert" ON public.finance_receivables FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_receivables_update" ON public.finance_receivables FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_receivables_delete" ON public.finance_receivables FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()) AND public.has_role(auth.uid(), 'financeiro'));

-- 4. Reembolsos
CREATE TABLE public.finance_reimbursements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES public.profiles(id),
  description TEXT NOT NULL,
  amount NUMERIC(14,2) NOT NULL,
  expense_date DATE NOT NULL,
  category_id UUID REFERENCES public.finance_categories(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid', 'cancelled')),
  rejection_reason TEXT,
  approved_by UUID REFERENCES public.profiles(id),
  approved_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.finance_reimbursements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "finance_reimbursements_select" ON public.finance_reimbursements FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_reimbursements_insert" ON public.finance_reimbursements FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_reimbursements_update" ON public.finance_reimbursements FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_reimbursements_delete" ON public.finance_reimbursements FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()) AND public.has_role(auth.uid(), 'financeiro'));

-- 5. Anexos de Reembolso
CREATE TABLE public.finance_reimbursement_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reimbursement_id UUID NOT NULL REFERENCES public.finance_reimbursements(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.finance_reimbursement_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "finance_reimb_attach_select" ON public.finance_reimbursement_attachments FOR SELECT TO authenticated
  USING (reimbursement_id IN (SELECT id FROM finance_reimbursements WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));
CREATE POLICY "finance_reimb_attach_insert" ON public.finance_reimbursement_attachments FOR INSERT TO authenticated
  WITH CHECK (reimbursement_id IN (SELECT id FROM finance_reimbursements WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));
CREATE POLICY "finance_reimb_attach_delete" ON public.finance_reimbursement_attachments FOR DELETE TO authenticated
  USING (reimbursement_id IN (SELECT id FROM finance_reimbursements WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

-- 6. Transações (registro de movimentações efetivadas)
CREATE TABLE public.finance_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
  description TEXT NOT NULL,
  amount NUMERIC(14,2) NOT NULL,
  transaction_date DATE NOT NULL,
  category_id UUID REFERENCES public.finance_categories(id) ON DELETE SET NULL,
  reference_type TEXT, -- 'payable', 'receivable', 'reimbursement'
  reference_id UUID,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.finance_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "finance_transactions_select" ON public.finance_transactions FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_transactions_insert" ON public.finance_transactions FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_transactions_update" ON public.finance_transactions FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "finance_transactions_delete" ON public.finance_transactions FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()) AND public.has_role(auth.uid(), 'financeiro'));

-- Triggers de updated_at
CREATE TRIGGER update_finance_categories_updated_at BEFORE UPDATE ON public.finance_categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_finance_payables_updated_at BEFORE UPDATE ON public.finance_payables FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_finance_receivables_updated_at BEFORE UPDATE ON public.finance_receivables FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_finance_reimbursements_updated_at BEFORE UPDATE ON public.finance_reimbursements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_finance_transactions_updated_at BEFORE UPDATE ON public.finance_transactions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Índices
CREATE INDEX idx_finance_payables_company ON public.finance_payables(company_id);
CREATE INDEX idx_finance_payables_status ON public.finance_payables(status);
CREATE INDEX idx_finance_payables_due_date ON public.finance_payables(due_date);
CREATE INDEX idx_finance_receivables_company ON public.finance_receivables(company_id);
CREATE INDEX idx_finance_receivables_status ON public.finance_receivables(status);
CREATE INDEX idx_finance_receivables_due_date ON public.finance_receivables(due_date);
CREATE INDEX idx_finance_reimbursements_company ON public.finance_reimbursements(company_id);
CREATE INDEX idx_finance_transactions_company ON public.finance_transactions(company_id);
CREATE INDEX idx_finance_transactions_date ON public.finance_transactions(transaction_date);
CREATE INDEX idx_finance_categories_company ON public.finance_categories(company_id);
