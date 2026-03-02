
-- Trigger: auto assign department when user_roles is inserted
CREATE OR REPLACE FUNCTION public.auto_assign_department_on_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_company_id uuid;
  v_dept_id uuid;
  v_dept_name text;
BEGIN
  -- Get user's company
  SELECT company_id INTO v_company_id FROM profiles WHERE id = NEW.user_id;
  
  IF v_company_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Map role to department name
  v_dept_name := CASE NEW.role::text
    WHEN 'admin' THEN 'Administração'
    WHEN 'technician' THEN 'Técnico'
    WHEN 'hr' THEN 'Recursos Humanos'
    WHEN 'manager' THEN 'Gerência'
    WHEN 'commercial' THEN 'Comercial'
    WHEN 'financeiro' THEN 'Financeiro'
    WHEN 'qualidade' THEN 'Qualidade'
    WHEN 'compras' THEN 'Suprimentos'
    ELSE NULL
  END;

  IF v_dept_name IS NULL THEN
    RETURN NEW;
  END IF;

  -- Find department
  SELECT id INTO v_dept_id
  FROM departments
  WHERE company_id = v_company_id AND name = v_dept_name;

  IF v_dept_id IS NOT NULL THEN
    INSERT INTO department_members (department_id, user_id)
    VALUES (v_dept_id, NEW.user_id)
    ON CONFLICT DO NOTHING;
  END IF;

  -- If role changed (UPDATE), remove from old department
  IF TG_OP = 'UPDATE' AND OLD.role IS DISTINCT FROM NEW.role THEN
    v_dept_name := CASE OLD.role::text
      WHEN 'admin' THEN 'Administração'
      WHEN 'technician' THEN 'Técnico'
      WHEN 'hr' THEN 'Recursos Humanos'
      WHEN 'manager' THEN 'Gerência'
      WHEN 'commercial' THEN 'Comercial'
      WHEN 'financeiro' THEN 'Financeiro'
      WHEN 'qualidade' THEN 'Qualidade'
      WHEN 'compras' THEN 'Suprimentos'
      ELSE NULL
    END;
    
    IF v_dept_name IS NOT NULL THEN
      DELETE FROM department_members
      WHERE user_id = NEW.user_id
        AND department_id IN (
          SELECT id FROM departments
          WHERE company_id = v_company_id AND name = v_dept_name
        );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger on user_roles
DROP TRIGGER IF EXISTS trg_auto_assign_department_on_role ON user_roles;
CREATE TRIGGER trg_auto_assign_department_on_role
  AFTER INSERT OR UPDATE ON user_roles
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_department_on_role();
