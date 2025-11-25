
-- Remove políticas que causam recursão infinita
DROP POLICY IF EXISTS "Technicians can view visits they are assigned to" ON service_visits;
DROP POLICY IF EXISTS "Users can view relevant visits" ON service_visits;

-- A política "Admins can view company visits" já existe e está correta
-- A política "Super admins can view all visits" já existe e está correta
-- Os técnicos acessam as visitas através de visit_technicians, não precisam de SELECT direto em service_visits
