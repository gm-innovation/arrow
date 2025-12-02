
-- Update trigger function to also copy time_entries from leader to auxiliaries
CREATE OR REPLACE FUNCTION public.complete_related_auxiliary_tasks()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_is_lead BOOLEAN;
  v_visit_id UUID;
  v_task_type_id UUID;
  v_service_order_id UUID;
  v_lead_name TEXT;
  v_order_number TEXT;
  v_task_title TEXT;
  v_auxiliary_task RECORD;
  v_time_entry RECORD;
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
      
      -- Buscar nome do líder e número da OS para notificação
      SELECT p.full_name INTO v_lead_name
      FROM technicians t
      JOIN profiles p ON p.id = t.user_id
      WHERE t.id = NEW.assigned_to;
      
      SELECT order_number INTO v_order_number
      FROM service_orders
      WHERE id = v_service_order_id;
      
      v_task_title := NEW.title;
      
      -- Para cada tarefa de auxiliar que será completada
      FOR v_auxiliary_task IN
        SELECT t.id as task_id, tech.user_id, tech.id as technician_id
        FROM tasks t
        JOIN technicians tech ON tech.id = t.assigned_to
        WHERE t.service_order_id = v_service_order_id
          AND t.task_type_id = v_task_type_id
          AND t.id != NEW.id
          AND t.status != 'completed'
      LOOP
        -- Criar notificação para o auxiliar
        INSERT INTO notifications (
          user_id,
          title,
          message,
          notification_type,
          reference_id,
          read
        ) VALUES (
          v_auxiliary_task.user_id,
          'Tarefa Concluída pelo Líder',
          'A tarefa "' || COALESCE(v_task_title, 'Tarefa') || '" na OS #' || v_order_number || ' foi concluída por ' || COALESCE(v_lead_name, 'o técnico líder') || '.',
          'task_update',
          v_auxiliary_task.task_id,
          false
        );

        -- Copy time_entries from leader's task to auxiliary's task
        FOR v_time_entry IN
          SELECT entry_type, entry_date, start_time, end_time
          FROM time_entries
          WHERE task_id = NEW.id
        LOOP
          INSERT INTO time_entries (task_id, technician_id, entry_type, entry_date, start_time, end_time)
          VALUES (
            v_auxiliary_task.task_id,
            v_auxiliary_task.technician_id,
            v_time_entry.entry_type,
            v_time_entry.entry_date,
            v_time_entry.start_time,
            v_time_entry.end_time
          )
          ON CONFLICT DO NOTHING;
        END LOOP;
      END LOOP;
      
      -- Completar as tarefas dos auxiliares
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
$function$;
