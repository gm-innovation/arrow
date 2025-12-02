-- Função para auto-completar tarefas dos auxiliares quando o líder completar
CREATE OR REPLACE FUNCTION public.complete_related_auxiliary_tasks()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_is_lead BOOLEAN;
  v_visit_id UUID;
  v_task_type_id UUID;
  v_service_order_id UUID;
BEGIN
  -- Só executa se o status mudou para 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    -- Pega o task_type_id e service_order_id da tarefa completada
    v_task_type_id := NEW.task_type_id;
    v_service_order_id := NEW.service_order_id;
    
    -- Verifica se o técnico que completou é líder em alguma visita desta OS
    SELECT vt.is_lead, vt.visit_id INTO v_is_lead, v_visit_id
    FROM visit_technicians vt
    JOIN service_visits sv ON sv.id = vt.visit_id
    JOIN technicians t ON t.id = vt.technician_id
    WHERE sv.service_order_id = v_service_order_id
      AND t.id = NEW.assigned_to
      AND vt.is_lead = true
    LIMIT 1;
    
    -- Se é líder, completa todas as tarefas relacionadas dos auxiliares
    IF v_is_lead = true AND v_task_type_id IS NOT NULL THEN
      UPDATE tasks
      SET 
        status = 'completed',
        completed_at = COALESCE(NEW.completed_at, now()),
        updated_at = now()
      WHERE service_order_id = v_service_order_id
        AND task_type_id = v_task_type_id
        AND id != NEW.id
        AND status != 'completed';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Criar o trigger
DROP TRIGGER IF EXISTS trigger_complete_auxiliary_tasks ON tasks;
CREATE TRIGGER trigger_complete_auxiliary_tasks
  AFTER UPDATE OF status ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION complete_related_auxiliary_tasks();