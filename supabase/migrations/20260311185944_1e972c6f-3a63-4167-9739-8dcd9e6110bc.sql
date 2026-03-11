
-- Remove registros inválidos com technician_id NULL
DELETE FROM visit_technicians WHERE technician_id IS NULL;

-- Remove tasks com assigned_to NULL (dados órfãos)
DELETE FROM tasks WHERE assigned_to IS NULL;

-- Torna a coluna obrigatória
ALTER TABLE visit_technicians ALTER COLUMN technician_id SET NOT NULL;
