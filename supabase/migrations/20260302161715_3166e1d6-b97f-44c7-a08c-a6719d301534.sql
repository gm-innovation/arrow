
-- Trigger: auto-create role_based groups when a new company is created
CREATE OR REPLACE FUNCTION public.auto_create_corp_groups_for_company()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO corp_groups (company_id, name, description, group_type, role_slug) VALUES
    (NEW.id, 'Técnicos', 'Grupo automático de técnicos', 'role_based', 'technician'),
    (NEW.id, 'Administradores', 'Grupo automático de administradores', 'role_based', 'admin'),
    (NEW.id, 'Recursos Humanos', 'Grupo automático de RH', 'role_based', 'hr'),
    (NEW.id, 'Gerentes', 'Grupo automático de gerentes', 'role_based', 'manager'),
    (NEW.id, 'Comercial', 'Grupo automático de comercial', 'role_based', 'commercial'),
    (NEW.id, 'Qualidade', 'Grupo automático de qualidade', 'role_based', 'qualidade'),
    (NEW.id, 'Financeiro', 'Grupo automático de financeiro', 'role_based', 'financeiro'),
    (NEW.id, 'Suprimentos', 'Grupo automático de suprimentos', 'role_based', 'compras'),
    (NEW.id, 'CIPA', 'Comissão Interna de Prevenção de Acidentes', 'custom', NULL),
    (NEW.id, 'Brigada de Incêndio', 'Brigada de combate a incêndio', 'custom', NULL),
    (NEW.id, 'SESMT', 'Serviço Especializado em Segurança e Medicina do Trabalho', 'custom', NULL);
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_create_corp_groups
AFTER INSERT ON companies
FOR EACH ROW
EXECUTE FUNCTION auto_create_corp_groups_for_company();

-- Trigger: auto-assign user to role-based group when role is inserted/updated
CREATE OR REPLACE FUNCTION public.auto_assign_user_to_corp_group()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_company_id uuid;
  v_group_id uuid;
BEGIN
  -- Get user's company
  SELECT company_id INTO v_company_id FROM profiles WHERE id = NEW.user_id;
  
  IF v_company_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Find matching role-based group
  SELECT id INTO v_group_id
  FROM corp_groups
  WHERE company_id = v_company_id
    AND group_type = 'role_based'
    AND role_slug = NEW.role::text;

  IF v_group_id IS NOT NULL THEN
    INSERT INTO corp_group_members (group_id, user_id)
    VALUES (v_group_id, NEW.user_id)
    ON CONFLICT DO NOTHING;
  END IF;

  -- If role changed (UPDATE), remove from old group
  IF TG_OP = 'UPDATE' AND OLD.role IS DISTINCT FROM NEW.role THEN
    DELETE FROM corp_group_members
    WHERE user_id = NEW.user_id
      AND group_id IN (
        SELECT id FROM corp_groups
        WHERE company_id = v_company_id
          AND group_type = 'role_based'
          AND role_slug = OLD.role::text
      );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_assign_corp_group
AFTER INSERT OR UPDATE ON user_roles
FOR EACH ROW
EXECUTE FUNCTION auto_assign_user_to_corp_group();
