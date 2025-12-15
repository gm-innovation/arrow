-- 1. Criar função para verificar se usuário está atribuído à OS
CREATE OR REPLACE FUNCTION public.is_technician_assigned_to_service_order(
  _user_id UUID,
  _service_order_id UUID
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    -- Verificar na tabela visit_technicians (técnicos e auxiliares)
    SELECT 1
    FROM service_visits sv
    JOIN visit_technicians vt ON vt.visit_id = sv.id
    JOIN technicians t ON t.id = vt.technician_id
    WHERE sv.service_order_id = _service_order_id
      AND t.user_id = _user_id
  )
  OR EXISTS (
    -- Verificar também na tabela tasks (atribuição direta)
    SELECT 1
    FROM tasks
    JOIN technicians t ON t.id = tasks.assigned_to
    WHERE tasks.service_order_id = _service_order_id
      AND t.user_id = _user_id
  )
$$;

-- 2. Criar tabela de histórico de relatórios
CREATE TABLE public.task_report_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID NOT NULL REFERENCES task_reports(id) ON DELETE CASCADE,
  edited_by UUID NOT NULL,
  action TEXT NOT NULL,
  changes JSONB,
  previous_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_report_history_report_id ON task_report_history(report_id);
CREATE INDEX idx_report_history_edited_by ON task_report_history(edited_by);

-- 3. Habilitar RLS na tabela de histórico
ALTER TABLE task_report_history ENABLE ROW LEVEL SECURITY;

-- 4. Políticas RLS para task_report_history
-- Técnicos podem ver histórico dos relatórios que têm acesso
CREATE POLICY "Technicians can view report history"
ON task_report_history
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM task_reports tr
    WHERE tr.id = task_report_history.report_id
    AND is_technician_assigned_to_service_order(auth.uid(), tr.task_uuid)
  )
);

-- Técnicos podem inserir no histórico
CREATE POLICY "Technicians can insert report history"
ON task_report_history
FOR INSERT
TO authenticated
WITH CHECK (edited_by = auth.uid());

-- Admins podem ver todo o histórico da empresa
CREATE POLICY "Admins can view all report history"
ON task_report_history
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'admin') AND EXISTS (
    SELECT 1 FROM task_reports tr
    JOIN tasks t ON t.id::text = tr.task_id
    JOIN service_orders so ON so.id = t.service_order_id
    WHERE tr.id = task_report_history.report_id
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- 5. Atualizar políticas da tabela task_reports para técnicos E auxiliares
-- Remover políticas antigas de técnicos
DROP POLICY IF EXISTS "Technicians can create reports for their tasks" ON task_reports;
DROP POLICY IF EXISTS "Technicians can update their own reports" ON task_reports;

-- Nova política: Técnicos podem criar relatórios para suas OS
CREATE POLICY "Technicians can create reports for their service orders"
ON task_reports
FOR INSERT
TO authenticated
WITH CHECK (
  is_technician_assigned_to_service_order(auth.uid(), task_uuid)
);

-- Nova política: Técnicos podem atualizar relatórios de suas OS
CREATE POLICY "Technicians can update reports for their service orders"
ON task_reports
FOR UPDATE
TO authenticated
USING (
  is_technician_assigned_to_service_order(auth.uid(), task_uuid)
);

-- Nova política: Técnicos podem ver relatórios de suas OS
CREATE POLICY "Technicians can view reports for their service orders"
ON task_reports
FOR SELECT
TO authenticated
USING (
  is_technician_assigned_to_service_order(auth.uid(), task_uuid)
);