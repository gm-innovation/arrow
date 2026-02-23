
-- =============================================
-- MÓDULO QUALIDADE - Tabelas e RLS
-- =============================================

-- 1. Não-Conformidades (RNC)
CREATE TABLE public.quality_ncrs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  ncr_number SERIAL,
  title TEXT NOT NULL,
  description TEXT,
  ncr_type TEXT NOT NULL DEFAULT 'internal' CHECK (ncr_type IN ('internal', 'external', 'supplier', 'process')),
  severity TEXT NOT NULL DEFAULT 'minor' CHECK (severity IN ('minor', 'major', 'critical')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'analysis', 'action_plan', 'verification', 'closed', 'cancelled')),
  source TEXT, -- origem da NC (auditoria, cliente, processo, etc.)
  affected_area TEXT,
  root_cause TEXT,
  immediate_action TEXT,
  responsible_id UUID REFERENCES public.profiles(id),
  detected_by UUID REFERENCES public.profiles(id),
  detected_at TIMESTAMPTZ DEFAULT now(),
  deadline TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  closed_by UUID REFERENCES public.profiles(id),
  verification_notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.quality_ncrs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quality_ncrs_select" ON public.quality_ncrs FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_ncrs_insert" ON public.quality_ncrs FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_ncrs_update" ON public.quality_ncrs FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_ncrs_delete" ON public.quality_ncrs FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
    AND public.has_role(auth.uid(), 'qualidade'));

-- 2. Anexos de RNC
CREATE TABLE public.quality_ncr_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ncr_id UUID NOT NULL REFERENCES public.quality_ncrs(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.quality_ncr_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quality_ncr_attachments_select" ON public.quality_ncr_attachments FOR SELECT TO authenticated
  USING (ncr_id IN (SELECT id FROM quality_ncrs WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_ncr_attachments_insert" ON public.quality_ncr_attachments FOR INSERT TO authenticated
  WITH CHECK (ncr_id IN (SELECT id FROM quality_ncrs WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_ncr_attachments_delete" ON public.quality_ncr_attachments FOR DELETE TO authenticated
  USING (ncr_id IN (SELECT id FROM quality_ncrs WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

-- 3. Planos de Ação (5W2H)
CREATE TABLE public.quality_action_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  ncr_id UUID REFERENCES public.quality_ncrs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  plan_type TEXT NOT NULL DEFAULT 'corrective' CHECK (plan_type IN ('corrective', 'preventive', 'improvement')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'in_progress', 'verification', 'effective', 'ineffective', 'closed')),
  responsible_id UUID REFERENCES public.profiles(id),
  start_date DATE,
  target_date DATE,
  completed_date DATE,
  effectiveness_verified BOOLEAN DEFAULT false,
  effectiveness_notes TEXT,
  verified_by UUID REFERENCES public.profiles(id),
  verified_at TIMESTAMPTZ,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.quality_action_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quality_action_plans_select" ON public.quality_action_plans FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_action_plans_insert" ON public.quality_action_plans FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_action_plans_update" ON public.quality_action_plans FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_action_plans_delete" ON public.quality_action_plans FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
    AND public.has_role(auth.uid(), 'qualidade'));

-- 4. Itens do Plano de Ação (5W2H detalhado)
CREATE TABLE public.quality_action_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action_plan_id UUID NOT NULL REFERENCES public.quality_action_plans(id) ON DELETE CASCADE,
  what TEXT NOT NULL, -- O que
  why TEXT, -- Por que
  where_location TEXT, -- Onde
  who UUID REFERENCES public.profiles(id), -- Quem
  when_date DATE, -- Quando
  how TEXT, -- Como
  how_much NUMERIC(12,2), -- Quanto
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  completed_at TIMESTAMPTZ,
  notes TEXT,
  item_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.quality_action_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quality_action_items_select" ON public.quality_action_items FOR SELECT TO authenticated
  USING (action_plan_id IN (SELECT id FROM quality_action_plans WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_action_items_insert" ON public.quality_action_items FOR INSERT TO authenticated
  WITH CHECK (action_plan_id IN (SELECT id FROM quality_action_plans WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_action_items_update" ON public.quality_action_items FOR UPDATE TO authenticated
  USING (action_plan_id IN (SELECT id FROM quality_action_plans WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_action_items_delete" ON public.quality_action_items FOR DELETE TO authenticated
  USING (action_plan_id IN (SELECT id FROM quality_action_plans WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

-- 5. Auditorias Internas
CREATE TABLE public.quality_audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  audit_number SERIAL,
  title TEXT NOT NULL,
  scope TEXT,
  audit_type TEXT NOT NULL DEFAULT 'internal' CHECK (audit_type IN ('internal', 'external', 'supplier', 'process')),
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
  planned_date DATE NOT NULL,
  actual_date DATE,
  lead_auditor_id UUID REFERENCES public.profiles(id),
  department TEXT,
  standard_reference TEXT, -- ex: ISO 9001:2015 clausula 7.1
  conclusion TEXT,
  summary TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.quality_audits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quality_audits_select" ON public.quality_audits FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_audits_insert" ON public.quality_audits FOR INSERT TO authenticated
  WITH CHECK (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_audits_update" ON public.quality_audits FOR UPDATE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "quality_audits_delete" ON public.quality_audits FOR DELETE TO authenticated
  USING (company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
    AND public.has_role(auth.uid(), 'qualidade'));

-- 6. Achados de Auditoria
CREATE TABLE public.quality_audit_findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_id UUID NOT NULL REFERENCES public.quality_audits(id) ON DELETE CASCADE,
  finding_type TEXT NOT NULL DEFAULT 'observation' CHECK (finding_type IN ('conformity', 'observation', 'minor_nc', 'major_nc', 'opportunity')),
  description TEXT NOT NULL,
  evidence TEXT,
  clause_reference TEXT, -- referência da norma
  corrective_action_required BOOLEAN DEFAULT false,
  action_plan_id UUID REFERENCES public.quality_action_plans(id) ON DELETE SET NULL,
  responsible_id UUID REFERENCES public.profiles(id),
  deadline DATE,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'closed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.quality_audit_findings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quality_audit_findings_select" ON public.quality_audit_findings FOR SELECT TO authenticated
  USING (audit_id IN (SELECT id FROM quality_audits WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_audit_findings_insert" ON public.quality_audit_findings FOR INSERT TO authenticated
  WITH CHECK (audit_id IN (SELECT id FROM quality_audits WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_audit_findings_update" ON public.quality_audit_findings FOR UPDATE TO authenticated
  USING (audit_id IN (SELECT id FROM quality_audits WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_audit_findings_delete" ON public.quality_audit_findings FOR DELETE TO authenticated
  USING (audit_id IN (SELECT id FROM quality_audits WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

-- 7. Checklist de Auditoria
CREATE TABLE public.quality_audit_checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_id UUID NOT NULL REFERENCES public.quality_audits(id) ON DELETE CASCADE,
  requirement TEXT NOT NULL,
  clause_reference TEXT,
  result TEXT CHECK (result IN ('conforming', 'non_conforming', 'observation', 'not_applicable', NULL)),
  notes TEXT,
  item_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.quality_audit_checklist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quality_audit_checklist_select" ON public.quality_audit_checklist_items FOR SELECT TO authenticated
  USING (audit_id IN (SELECT id FROM quality_audits WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_audit_checklist_insert" ON public.quality_audit_checklist_items FOR INSERT TO authenticated
  WITH CHECK (audit_id IN (SELECT id FROM quality_audits WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_audit_checklist_update" ON public.quality_audit_checklist_items FOR UPDATE TO authenticated
  USING (audit_id IN (SELECT id FROM quality_audits WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY "quality_audit_checklist_delete" ON public.quality_audit_checklist_items FOR DELETE TO authenticated
  USING (audit_id IN (SELECT id FROM quality_audits WHERE company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())));

-- Triggers de updated_at
CREATE TRIGGER update_quality_ncrs_updated_at BEFORE UPDATE ON public.quality_ncrs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_quality_action_plans_updated_at BEFORE UPDATE ON public.quality_action_plans
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_quality_action_items_updated_at BEFORE UPDATE ON public.quality_action_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_quality_audits_updated_at BEFORE UPDATE ON public.quality_audits
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_quality_audit_findings_updated_at BEFORE UPDATE ON public.quality_audit_findings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Índices para performance
CREATE INDEX idx_quality_ncrs_company ON public.quality_ncrs(company_id);
CREATE INDEX idx_quality_ncrs_status ON public.quality_ncrs(status);
CREATE INDEX idx_quality_action_plans_company ON public.quality_action_plans(company_id);
CREATE INDEX idx_quality_action_plans_ncr ON public.quality_action_plans(ncr_id);
CREATE INDEX idx_quality_audits_company ON public.quality_audits(company_id);
CREATE INDEX idx_quality_audits_planned_date ON public.quality_audits(planned_date);
