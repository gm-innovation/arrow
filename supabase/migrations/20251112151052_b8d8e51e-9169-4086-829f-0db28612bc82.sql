-- 1. Adicionar campo created_by na tabela service_orders
ALTER TABLE service_orders 
ADD COLUMN created_by UUID REFERENCES profiles(id);

-- Migrar dados existentes: marcar o primeiro admin da empresa como criador
UPDATE service_orders so
SET created_by = (
  SELECT p.id 
  FROM profiles p
  JOIN user_roles ur ON ur.user_id = p.id
  WHERE p.company_id = so.company_id
  AND ur.role = 'admin'
  ORDER BY p.created_at
  LIMIT 1
);

-- Tornar obrigatório depois da migração
ALTER TABLE service_orders 
ALTER COLUMN created_by SET NOT NULL;

-- 2. Expandir tabela service_history para auditoria completa
ALTER TABLE service_history
ADD COLUMN change_type TEXT NOT NULL DEFAULT 'other',
ADD COLUMN old_values JSONB,
ADD COLUMN new_values JSONB,
ADD COLUMN ip_address TEXT,
ADD COLUMN user_agent TEXT;

-- Criar índices para consultas de auditoria
CREATE INDEX idx_service_history_order ON service_history(service_order_id);
CREATE INDEX idx_service_history_user ON service_history(performed_by);
CREATE INDEX idx_service_history_date ON service_history(created_at DESC);
CREATE INDEX idx_service_history_type ON service_history(change_type);

-- 3. Atualizar RLS Policies para Modelo Híbrido
-- Remover policies antigas
DROP POLICY IF EXISTS "Admins can manage service orders in their company" ON service_orders;
DROP POLICY IF EXISTS "Users can view service orders in their company" ON service_orders;

-- Policy 1: Coordenador responsável tem acesso total
CREATE POLICY "Responsible coordinator can manage their service orders"
ON service_orders FOR ALL
USING (
  created_by = auth.uid() 
  AND has_role(auth.uid(), 'admin'::app_role)
)
WITH CHECK (
  created_by = auth.uid() 
  AND has_role(auth.uid(), 'admin'::app_role)
);

-- Policy 2: Outros admins da empresa têm acesso de leitura
CREATE POLICY "Admins can view company service orders"
ON service_orders FOR SELECT
USING (
  company_id = user_company_id(auth.uid())
  AND has_role(auth.uid(), 'admin'::app_role)
);

-- Policy 3: Super admins têm acesso total
CREATE POLICY "Super admins can manage all service orders"
ON service_orders FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'super_admin'::app_role));

-- Policy 4: Técnicos podem visualizar suas OSs
CREATE POLICY "Technicians can view their service orders"
ON service_orders FOR SELECT
USING (
  company_id = user_company_id(auth.uid())
);

-- 4. Criar trigger para auditoria automática em service_orders
CREATE OR REPLACE FUNCTION log_service_order_changes()
RETURNS TRIGGER AS $$
DECLARE
  performer_name TEXT;
BEGIN
  -- Obter nome do usuário
  SELECT full_name INTO performer_name FROM profiles WHERE id = auth.uid();
  
  IF TG_OP = 'INSERT' THEN
    INSERT INTO service_history (
      service_order_id,
      action,
      change_type,
      description,
      new_values,
      performed_by
    ) VALUES (
      NEW.id,
      'service_order_created',
      'create',
      'OS criada por ' || COALESCE(performer_name, 'Sistema'),
      to_jsonb(NEW),
      auth.uid()
    );
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Registrar apenas se houve mudança real
    IF OLD IS DISTINCT FROM NEW THEN
      INSERT INTO service_history (
        service_order_id,
        action,
        change_type,
        description,
        old_values,
        new_values,
        performed_by
      ) VALUES (
        NEW.id,
        'service_order_updated',
        'update',
        'OS atualizada por ' || COALESCE(performer_name, 'Sistema'),
        to_jsonb(OLD),
        to_jsonb(NEW),
        auth.uid()
      );
    END IF;
    
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO service_history (
      service_order_id,
      action,
      change_type,
      description,
      old_values,
      performed_by
    ) VALUES (
      OLD.id,
      'service_order_deleted',
      'delete',
      'OS deletada por ' || COALESCE(performer_name, 'Sistema'),
      to_jsonb(OLD),
      auth.uid()
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER service_order_audit
AFTER INSERT OR UPDATE OR DELETE ON service_orders
FOR EACH ROW EXECUTE FUNCTION log_service_order_changes();

-- 5. Criar trigger para auditoria em tasks
CREATE OR REPLACE FUNCTION log_task_changes()
RETURNS TRIGGER AS $$
DECLARE
  performer_name TEXT;
BEGIN
  SELECT full_name INTO performer_name FROM profiles WHERE id = auth.uid();
  
  IF TG_OP = 'INSERT' THEN
    INSERT INTO service_history (
      service_order_id,
      action,
      change_type,
      description,
      new_values,
      performed_by
    ) VALUES (
      NEW.service_order_id,
      'task_created',
      'create',
      'Tarefa "' || NEW.title || '" criada',
      jsonb_build_object(
        'task_id', NEW.id,
        'title', NEW.title,
        'assigned_to', NEW.assigned_to
      ),
      auth.uid()
    );
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Detectar mudanças específicas
    IF OLD.assigned_to IS DISTINCT FROM NEW.assigned_to THEN
      INSERT INTO service_history (
        service_order_id,
        action,
        change_type,
        description,
        old_values,
        new_values,
        performed_by
      ) VALUES (
        NEW.service_order_id,
        'task_reassigned',
        'update',
        'Tarefa "' || NEW.title || '" transferida de técnico',
        jsonb_build_object('old_technician', OLD.assigned_to),
        jsonb_build_object('new_technician', NEW.assigned_to),
        auth.uid()
      );
    END IF;
    
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO service_history (
        service_order_id,
        action,
        change_type,
        description,
        old_values,
        new_values,
        performed_by
      ) VALUES (
        NEW.service_order_id,
        'task_status_changed',
        'update',
        'Status da tarefa "' || NEW.title || '" alterado de ' || OLD.status || ' para ' || NEW.status,
        jsonb_build_object('old_status', OLD.status),
        jsonb_build_object('new_status', NEW.status),
        auth.uid()
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER task_audit
AFTER INSERT OR UPDATE ON tasks
FOR EACH ROW EXECUTE FUNCTION log_task_changes();

-- 6. Criar trigger para auditoria em service_visits
CREATE OR REPLACE FUNCTION log_visit_changes()
RETURNS TRIGGER AS $$
DECLARE
  performer_name TEXT;
BEGIN
  SELECT full_name INTO performer_name FROM profiles WHERE id = COALESCE(NEW.created_by, auth.uid());
  
  IF TG_OP = 'INSERT' THEN
    INSERT INTO service_history (
      service_order_id,
      action,
      change_type,
      description,
      new_values,
      performed_by
    ) VALUES (
      NEW.service_order_id,
      CASE 
        WHEN NEW.visit_type = 'initial' THEN 'visit_initial_created'
        WHEN NEW.visit_type = 'continuation' THEN 'visit_continuation_created'
        WHEN NEW.visit_type = 'return' THEN 'visit_return_scheduled'
      END,
      'create',
      CASE 
        WHEN NEW.visit_type = 'initial' THEN 'Visita inicial criada por ' || COALESCE(performer_name, 'Sistema')
        WHEN NEW.visit_type = 'continuation' THEN 'Visita de continuação #' || NEW.visit_number || ' criada por ' || COALESCE(performer_name, 'Sistema')
        WHEN NEW.visit_type = 'return' THEN 'Retorno agendado por ' || COALESCE(performer_name, 'Sistema') || ': ' || COALESCE(NEW.return_reason, 'sem motivo')
      END,
      to_jsonb(NEW),
      COALESCE(NEW.created_by, auth.uid())
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER visit_audit
AFTER INSERT ON service_visits
FOR EACH ROW EXECUTE FUNCTION log_visit_changes();