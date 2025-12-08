-- Função para criar time_entry automaticamente quando tarefa é concluída
CREATE OR REPLACE FUNCTION public.create_time_entry_on_task_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_entry_date DATE;
BEGIN
  -- Só processa quando status muda para 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') AND NEW.assigned_to IS NOT NULL THEN
    -- Define a data da entrada
    v_entry_date := COALESCE(DATE(NEW.completed_at), CURRENT_DATE);
    
    -- Verifica se já existe um time_entry para esta tarefa e técnico nesta data
    IF NOT EXISTS (
      SELECT 1 FROM time_entries
      WHERE task_id = NEW.id
        AND technician_id = NEW.assigned_to
        AND entry_date = v_entry_date
    ) THEN
      -- Cria o time_entry automaticamente com horário padrão 08:00-17:00
      INSERT INTO time_entries (
        task_id,
        technician_id,
        entry_type,
        entry_date,
        start_time,
        end_time
      ) VALUES (
        NEW.id,
        NEW.assigned_to,
        'work_normal',
        v_entry_date,
        '08:00:00'::time,
        '17:00:00'::time
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger que dispara ao atualizar status da tarefa
DROP TRIGGER IF EXISTS trigger_create_time_entry_on_task_completion ON tasks;
CREATE TRIGGER trigger_create_time_entry_on_task_completion
  AFTER UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION create_time_entry_on_task_completion();

-- Função para gerar time entries para tarefas já completadas ou da mesma OS
CREATE OR REPLACE FUNCTION public.generate_time_entries_for_completed_orders()
RETURNS INTEGER AS $$
DECLARE
  v_task RECORD;
  v_count INTEGER := 0;
  v_entry_date DATE;
BEGIN
  -- Processa todas as tarefas de OS concluídas
  FOR v_task IN 
    SELECT t.id as task_id, t.assigned_to as technician_id, 
           COALESCE(DATE(t.completed_at), DATE(so.completed_date), DATE(t.created_at)) as entry_date
    FROM tasks t
    JOIN service_orders so ON t.service_order_id = so.id
    WHERE t.assigned_to IS NOT NULL
      AND (so.status = 'completed' OR t.status = 'completed')
  LOOP
    -- Verifica se já existe
    IF NOT EXISTS (
      SELECT 1 FROM time_entries
      WHERE task_id = v_task.task_id
        AND technician_id = v_task.technician_id
        AND entry_date = v_task.entry_date
    ) THEN
      -- Insere o time_entry com horário padrão
      INSERT INTO time_entries (
        task_id,
        technician_id,
        entry_type,
        entry_date,
        start_time,
        end_time
      ) VALUES (
        v_task.task_id,
        v_task.technician_id,
        'work_normal',
        v_task.entry_date,
        '08:00:00'::time,
        '17:00:00'::time
      );
      v_count := v_count + 1;
    END IF;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Executa a geração para OS já concluídas
SELECT generate_time_entries_for_completed_orders();