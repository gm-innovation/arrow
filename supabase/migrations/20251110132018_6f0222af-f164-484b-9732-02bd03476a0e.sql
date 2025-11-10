-- Fix search_path for notify_overdue_payment function
CREATE OR REPLACE FUNCTION notify_overdue_payment()
RETURNS TRIGGER AS $$
DECLARE
  super_admin_id uuid;
BEGIN
  -- Only trigger if status changed to overdue
  IF NEW.payment_status = 'overdue' AND (OLD.payment_status IS NULL OR OLD.payment_status != 'overdue') THEN
    -- Get all super admin users
    FOR super_admin_id IN 
      SELECT user_id FROM user_roles WHERE role = 'super_admin'
    LOOP
      INSERT INTO notifications (
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Fix search_path for notify_new_company function
CREATE OR REPLACE FUNCTION notify_new_company()
RETURNS TRIGGER AS $$
DECLARE
  super_admin_id uuid;
BEGIN
  -- Get all super admin users
  FOR super_admin_id IN 
    SELECT user_id FROM user_roles WHERE role = 'super_admin'
  LOOP
    INSERT INTO notifications (
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;