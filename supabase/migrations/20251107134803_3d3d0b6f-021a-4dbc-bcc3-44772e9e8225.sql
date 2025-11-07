-- FASE 9: Correções de Segurança

-- 1. Melhorar políticas RLS para clients (restringir a admins e supervisores)
DROP POLICY IF EXISTS "Users can view clients in their company" ON public.clients;

CREATE POLICY "Admins and supervisors can view clients in their company"
ON public.clients
FOR SELECT
TO authenticated
USING (
  company_id = user_company_id(auth.uid()) 
  AND (
    has_role(auth.uid(), 'admin'::app_role) 
    OR has_role(auth.uid(), 'super_admin'::app_role)
    OR EXISTS (
      SELECT 1 FROM service_orders 
      WHERE service_orders.client_id = clients.id 
      AND service_orders.supervisor_id IN (
        SELECT id FROM technicians WHERE user_id = auth.uid()
      )
    )
  )
);

-- 2. Restringir visualização de companies apenas para admins
DROP POLICY IF EXISTS "Users can view their own company" ON public.companies;

CREATE POLICY "Admins can view their own company"
ON public.companies
FOR SELECT
TO authenticated
USING (
  id = user_company_id(auth.uid()) 
  AND (
    has_role(auth.uid(), 'admin'::app_role) 
    OR has_role(auth.uid(), 'super_admin'::app_role)
  )
);

-- 3. Melhorar políticas de profiles (usuários veem apenas próprio perfil + admins veem todos)
DROP POLICY IF EXISTS "Users can view profiles in their company" ON public.profiles;

CREATE POLICY "Users can view own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "Admins can view all profiles in their company"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  company_id = user_company_id(auth.uid())
  AND (
    has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'super_admin'::app_role)
  )
);

-- 4. Melhorar política de criação de notificações (remover política permissiva)
DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;

CREATE POLICY "Admins can create notifications"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) 
  OR has_role(auth.uid(), 'super_admin'::app_role)
);

-- 5. Melhorar política de criação de service_history (remover política permissiva)
DROP POLICY IF EXISTS "System can create service history" ON public.service_history;

CREATE POLICY "Admins can create service history"
ON public.service_history
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM service_orders
    WHERE service_orders.id = service_history.service_order_id
    AND service_orders.company_id = user_company_id(auth.uid())
  )
  AND (
    has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'super_admin'::app_role)
  )
);

-- 6. Melhorar visualização de task_reports (apenas técnicos atribuídos, supervisores e admins)
DROP POLICY IF EXISTS "Users can view task reports in their company" ON public.task_reports;

CREATE POLICY "Authorized users can view task reports"
ON public.task_reports
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM tasks
    JOIN service_orders ON tasks.service_order_id = service_orders.id
    WHERE tasks.id::text = task_reports.task_id
    AND service_orders.company_id = user_company_id(auth.uid())
    AND (
      has_role(auth.uid(), 'admin'::app_role)
      OR has_role(auth.uid(), 'super_admin'::app_role)
      OR tasks.assigned_to IN (SELECT id FROM technicians WHERE user_id = auth.uid())
      OR service_orders.supervisor_id IN (SELECT id FROM technicians WHERE user_id = auth.uid())
    )
  )
);

-- 7. Adicionar política de RLS para o bucket de reports
INSERT INTO storage.buckets (id, name, public)
VALUES ('reports', 'reports', false)
ON CONFLICT (id) DO NOTHING;

-- Políticas de Storage para reports bucket
CREATE POLICY "Users can view reports from their company"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'reports'
  AND (
    has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'super_admin'::app_role)
    OR EXISTS (
      SELECT 1 FROM task_reports
      JOIN tasks ON tasks.id::text = task_reports.task_id
      JOIN technicians ON tasks.assigned_to = technicians.id
      WHERE task_reports.pdf_path = storage.objects.name
      AND technicians.user_id = auth.uid()
    )
  )
);

CREATE POLICY "Technicians can upload reports"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'reports'
  AND auth.uid() IS NOT NULL
);

CREATE POLICY "Admins can delete reports"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'reports'
  AND (
    has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'super_admin'::app_role)
  )
);