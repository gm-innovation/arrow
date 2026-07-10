ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'support_ticket_created';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'support_ticket_reply';

CREATE OR REPLACE FUNCTION public.notify_support_ticket_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_user RECORD;
BEGIN
  FOR admin_user IN
    SELECT ur.user_id
    FROM public.user_roles ur
    WHERE ur.role = 'super_admin'
  LOOP
    INSERT INTO public.notifications (
      user_id,
      notification_type,
      title,
      message,
      reference_id,
      read
    )
    VALUES (
      admin_user.user_id,
      'support_ticket_created',
      'Novo chamado #' || NEW.ticket_number,
      COALESCE(NEW.user_name, 'Usuário') || ' abriu: ' || NEW.title,
      NEW.id,
      false
    );
  END LOOP;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_support_ticket_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ticket_row RECORD;
  admin_user RECORD;
BEGIN
  SELECT * INTO ticket_row
  FROM public.support_tickets
  WHERE id = NEW.ticket_id;

  IF ticket_row.id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.is_admin THEN
    INSERT INTO public.notifications (
      user_id,
      notification_type,
      title,
      message,
      reference_id,
      read
    )
    VALUES (
      ticket_row.user_id,
      'support_ticket_reply',
      'Resposta no chamado #' || ticket_row.ticket_number,
      'Você recebeu uma resposta do suporte.',
      ticket_row.id,
      false
    );
  ELSE
    FOR admin_user IN
      SELECT ur.user_id
      FROM public.user_roles ur
      WHERE ur.role = 'super_admin'
    LOOP
      INSERT INTO public.notifications (
        user_id,
        notification_type,
        title,
        message,
        reference_id,
        read
      )
      VALUES (
        admin_user.user_id,
        'support_ticket_reply',
        'Nova mensagem no chamado #' || ticket_row.ticket_number,
        COALESCE(ticket_row.user_name, 'Usuário') || ' respondeu.',
        ticket_row.id,
        false
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$;