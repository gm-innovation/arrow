-- Criar índice para melhorar performance das queries
CREATE INDEX IF NOT EXISTS idx_task_reports_task_id ON public.task_reports(task_id);
CREATE INDEX IF NOT EXISTS idx_task_reports_status ON public.task_reports(status);
CREATE INDEX IF NOT EXISTS idx_task_reports_task_uuid ON public.task_reports(task_uuid);

-- Criar função helper para verificar se admin pode gerenciar relatório
CREATE OR REPLACE FUNCTION public.can_admin_manage_report(_task_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM tasks t
    JOIN service_orders so ON t.service_order_id = so.id
    WHERE t.id::text = _task_id
      AND so.company_id = user_company_id(auth.uid())
  )
$$;

-- Remover políticas antigas problemáticas
DROP POLICY IF EXISTS "Admins can manage reports in their company" ON public.task_reports;
DROP POLICY IF EXISTS "Authorized users can view task reports" ON public.task_reports;
DROP POLICY IF EXISTS "Technicians can view reports from their service orders" ON public.task_reports;

-- Recriar políticas de forma otimizada
CREATE POLICY "Admins can manage reports in their company" 
ON public.task_reports 
FOR ALL 
USING (
  has_role(auth.uid(), 'admin'::app_role) 
  AND can_admin_manage_report(task_id)
);

-- Política simplificada para visualização
CREATE POLICY "Users can view reports in their company" 
ON public.task_reports 
FOR SELECT 
USING (
  can_admin_manage_report(task_id)
);