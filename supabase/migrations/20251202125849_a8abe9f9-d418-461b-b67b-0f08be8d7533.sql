-- FASE 1: Correções de Segurança
-- Corrigir Function Search Path Mutable nas 3 funções identificadas

-- 1. Corrigir notify_technicians_on_service_order_change
CREATE OR REPLACE FUNCTION public.notify_technicians_on_service_order_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_technician_id UUID;
  v_notification_title TEXT;
  v_notification_message TEXT;
  v_task_record RECORD;
BEGIN
  -- Determine notification title and message based on operation
  IF TG_OP = 'INSERT' THEN
    v_notification_title := 'Nova Ordem de Serviço';
    v_notification_message := 'OS #' || NEW.order_number || ' foi criada e você foi atribuído';
  ELSIF TG_OP = 'UPDATE' THEN
    v_notification_title := 'OS Atualizada';
    v_notification_message := 'OS #' || NEW.order_number || ' foi atualizada';
  END IF;

  -- Find all technicians assigned to tasks for this service order
  FOR v_task_record IN
    SELECT DISTINCT t.assigned_to, tech.user_id
    FROM tasks t
    JOIN technicians tech ON tech.id = t.assigned_to
    WHERE t.service_order_id = NEW.id
  LOOP
    -- Create notification for each technician
    INSERT INTO notifications (
      user_id,
      title,
      message,
      notification_type,
      reference_id,
      read
    ) VALUES (
      v_task_record.user_id,
      v_notification_title,
      v_notification_message,
      'service_order',
      NEW.id,
      false
    );
  END LOOP;

  RETURN NEW;
END;
$function$;

-- 2. Corrigir notify_technician_on_task_assignment
CREATE OR REPLACE FUNCTION public.notify_technician_on_task_assignment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id UUID;
  v_order_number TEXT;
  v_task_title TEXT;
BEGIN
  -- Only notify on INSERT or when assigned_to changes
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.assigned_to IS DISTINCT FROM NEW.assigned_to) THEN
    -- Get technician's user_id
    SELECT user_id INTO v_user_id
    FROM technicians
    WHERE id = NEW.assigned_to;

    -- Get service order number and task title
    SELECT so.order_number INTO v_order_number
    FROM service_orders so
    WHERE so.id = NEW.service_order_id;

    v_task_title := COALESCE(NEW.title, 'Tarefa');

    -- Create notification
    IF v_user_id IS NOT NULL THEN
      INSERT INTO notifications (
        user_id,
        title,
        message,
        notification_type,
        reference_id,
        read
      ) VALUES (
        v_user_id,
        'Nova Tarefa Atribuída',
        'Você foi atribuído à tarefa "' || v_task_title || '" na OS #' || v_order_number,
        'task_assignment',
        NEW.id,
        false
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

-- 3. Corrigir notify_technicians_on_schedule_change
CREATE OR REPLACE FUNCTION public.notify_technicians_on_schedule_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_task_record RECORD;
  v_new_date TEXT;
BEGIN
  -- Only notify if scheduled_date or service_date_time actually changed
  IF (OLD.scheduled_date IS DISTINCT FROM NEW.scheduled_date) OR 
     (OLD.service_date_time IS DISTINCT FROM NEW.service_date_time) THEN
    
    v_new_date := COALESCE(
      to_char(NEW.service_date_time, 'DD/MM/YYYY HH24:MI'),
      to_char(NEW.scheduled_date, 'DD/MM/YYYY')
    );

    -- Notify all assigned technicians
    FOR v_task_record IN
      SELECT DISTINCT tech.user_id
      FROM tasks t
      JOIN technicians tech ON tech.id = t.assigned_to
      WHERE t.service_order_id = NEW.id
    LOOP
      INSERT INTO notifications (
        user_id,
        title,
        message,
        notification_type,
        reference_id,
        read
      ) VALUES (
        v_task_record.user_id,
        'Agendamento Alterado',
        'A data da OS #' || NEW.order_number || ' foi alterada para ' || v_new_date,
        'schedule_change',
        NEW.id,
        false
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$function$;