-- Fix database security issues identified by linter

-- 1. Fix search_path for user-defined functions to prevent SQL injection
-- Setting search_path to 'public' explicitly makes functions more secure

-- Update handle_new_user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = 'public'
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.email
  );
  RETURN NEW;
END;
$function$;

-- Update update_updated_at function
CREATE OR REPLACE FUNCTION public.update_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = 'public'
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

-- Update update_task_reports_updated_at function
CREATE OR REPLACE FUNCTION public.update_task_reports_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = 'public'
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

-- Update update_report_embeddings_updated_at function
CREATE OR REPLACE FUNCTION public.update_report_embeddings_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = 'public'
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

-- Update notify_overdue_payment function
CREATE OR REPLACE FUNCTION public.notify_overdue_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = 'public'
AS $function$
DECLARE
  super_admin_id uuid;
BEGIN
  IF NEW.payment_status = 'overdue' AND (OLD.payment_status IS NULL OR OLD.payment_status != 'overdue') THEN
    FOR super_admin_id IN 
      SELECT user_id FROM public.user_roles WHERE role = 'super_admin'
    LOOP
      INSERT INTO public.notifications (
        user_id,
        title,
        message,
        notification_type,
        reference_id
      ) VALUES (
        super_admin_id,
        'Pagamento em Atraso',
        'A empresa "' || NEW.name || '" está com pagamento em atraso.',
        'payment_overdue',
        NEW.id
      );
    END LOOP;
  END IF;
  RETURN NEW;
END;
$function$;

-- Update notify_new_company function
CREATE OR REPLACE FUNCTION public.notify_new_company()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = 'public'
AS $function$
DECLARE
  super_admin_id uuid;
BEGIN
  FOR super_admin_id IN 
    SELECT user_id FROM public.user_roles WHERE role = 'super_admin'
  LOOP
    INSERT INTO public.notifications (
      user_id,
      title,
      message,
      notification_type,
      reference_id
    ) VALUES (
      super_admin_id,
      'Nova Empresa Cadastrada',
      'A empresa "' || NEW.name || '" foi cadastrada no sistema.',
      'new_company',
      NEW.id
    );
  END LOOP;
  RETURN NEW;
END;
$function$;

-- Update notify_technicians_on_service_order_change function
CREATE OR REPLACE FUNCTION public.notify_technicians_on_service_order_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = 'public'
AS $function$
DECLARE
  v_technician_id UUID;
  v_notification_title TEXT;
  v_notification_message TEXT;
  v_task_record RECORD;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_notification_title := 'Nova Ordem de Serviço';
    v_notification_message := 'OS #' || NEW.order_number || ' foi criada e você foi atribuído';
  ELSIF TG_OP = 'UPDATE' THEN
    v_notification_title := 'OS Atualizada';
    v_notification_message := 'OS #' || NEW.order_number || ' foi atualizada';
  END IF;

  FOR v_task_record IN
    SELECT DISTINCT t.assigned_to, tech.user_id
    FROM public.tasks t
    JOIN public.technicians tech ON tech.id = t.assigned_to
    WHERE t.service_order_id = NEW.id
  LOOP
    INSERT INTO public.notifications (
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

-- Update notify_technician_on_task_assignment function
CREATE OR REPLACE FUNCTION public.notify_technician_on_task_assignment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = 'public'
AS $function$
DECLARE
  v_user_id UUID;
  v_order_number TEXT;
  v_task_title TEXT;
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.assigned_to IS DISTINCT FROM NEW.assigned_to) THEN
    SELECT user_id INTO v_user_id
    FROM public.technicians
    WHERE id = NEW.assigned_to;

    SELECT so.order_number INTO v_order_number
    FROM public.service_orders so
    WHERE so.id = NEW.service_order_id;

    v_task_title := COALESCE(NEW.title, 'Tarefa');

    IF v_user_id IS NOT NULL THEN
      INSERT INTO public.notifications (
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

-- Update notify_technicians_on_schedule_change function
CREATE OR REPLACE FUNCTION public.notify_technicians_on_schedule_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = 'public'
AS $function$
DECLARE
  v_task_record RECORD;
  v_new_date TEXT;
BEGIN
  IF (OLD.scheduled_date IS DISTINCT FROM NEW.scheduled_date) OR 
     (OLD.service_date_time IS DISTINCT FROM NEW.service_date_time) THEN
    
    v_new_date := COALESCE(
      to_char(NEW.service_date_time, 'DD/MM/YYYY HH24:MI'),
      to_char(NEW.scheduled_date, 'DD/MM/YYYY')
    );

    FOR v_task_record IN
      SELECT DISTINCT tech.user_id
      FROM public.tasks t
      JOIN public.technicians tech ON tech.id = t.assigned_to
      WHERE t.service_order_id = NEW.id
    LOOP
      INSERT INTO public.notifications (
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

-- Update complete_related_auxiliary_tasks function
CREATE OR REPLACE FUNCTION public.complete_related_auxiliary_tasks()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = 'public'
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
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    v_task_type_id := NEW.task_type_id;
    v_service_order_id := NEW.service_order_id;
    
    SELECT vt.is_lead, vt.visit_id INTO v_is_lead, v_visit_id
    FROM public.visit_technicians vt
    JOIN public.service_visits sv ON sv.id = vt.visit_id
    JOIN public.technicians t ON t.id = vt.technician_id
    WHERE sv.service_order_id = v_service_order_id
      AND t.id = NEW.assigned_to
      AND vt.is_lead = true
    LIMIT 1;
    
    IF v_is_lead = true AND v_task_type_id IS NOT NULL THEN
      
      SELECT p.full_name INTO v_lead_name
      FROM public.technicians t
      JOIN public.profiles p ON p.id = t.user_id
      WHERE t.id = NEW.assigned_to;
      
      SELECT order_number INTO v_order_number
      FROM public.service_orders
      WHERE id = v_service_order_id;
      
      v_task_title := NEW.title;
      
      FOR v_auxiliary_task IN
        SELECT t.id as task_id, tech.user_id, tech.id as technician_id
        FROM public.tasks t
        JOIN public.technicians tech ON tech.id = t.assigned_to
        WHERE t.service_order_id = v_service_order_id
          AND t.task_type_id = v_task_type_id
          AND t.id != NEW.id
          AND t.status != 'completed'
      LOOP
        INSERT INTO public.notifications (
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

        FOR v_time_entry IN
          SELECT entry_type, entry_date, start_time, end_time
          FROM public.time_entries
          WHERE task_id = NEW.id
        LOOP
          INSERT INTO public.time_entries (task_id, technician_id, entry_type, entry_date, start_time, end_time)
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
      
      UPDATE public.tasks
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

-- Note about extensions in public schema:
-- Moving extensions out of public schema requires careful consideration
-- as it may break existing functionality. This should be done in a future
-- maintenance window with proper testing.

-- Note about leaked password protection:
-- This setting requires Supabase dashboard access and cannot be modified via SQL migrations.
-- It should be enabled through the Supabase Auth settings.