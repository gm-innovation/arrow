
-- Add admin_user_id column to corp_groups
ALTER TABLE public.corp_groups ADD COLUMN admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- Recreate trigger function without SESMT
CREATE OR REPLACE FUNCTION public.auto_create_corp_groups_for_company()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    (NEW.id, 'Brigada de Incêndio', 'Brigada de combate a incêndio', 'custom', NULL);
  RETURN NEW;
END;
$function$;

-- Allow group admin to manage members
CREATE POLICY "Group admin can add members"
ON public.corp_group_members
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM corp_groups
    WHERE id = group_id
    AND admin_user_id = auth.uid()
  )
);

CREATE POLICY "Group admin can remove members"
ON public.corp_group_members
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM corp_groups
    WHERE id = group_id
    AND admin_user_id = auth.uid()
  )
);
