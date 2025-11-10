-- Function to notify super admins about overdue payments
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify super admins about new companies
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for overdue payments
DROP TRIGGER IF EXISTS trigger_overdue_payment ON companies;
CREATE TRIGGER trigger_overdue_payment
  AFTER INSERT OR UPDATE OF payment_status ON companies
  FOR EACH ROW
  EXECUTE FUNCTION notify_overdue_payment();

-- Trigger for new companies
DROP TRIGGER IF EXISTS trigger_new_company ON companies;
CREATE TRIGGER trigger_new_company
  AFTER INSERT ON companies
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_company();