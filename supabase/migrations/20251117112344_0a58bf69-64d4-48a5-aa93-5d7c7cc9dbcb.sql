-- Remove a foreign key atual do supervisor_id que aponta para technicians
ALTER TABLE service_orders 
DROP CONSTRAINT IF EXISTS service_orders_supervisor_id_fkey;

-- Adiciona nova foreign key apontando para profiles (usuários admin)
ALTER TABLE service_orders 
ADD CONSTRAINT service_orders_supervisor_id_fkey 
FOREIGN KEY (supervisor_id) 
REFERENCES profiles(id) 
ON DELETE SET NULL;