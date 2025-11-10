-- Adicionar campos para informações extraídas dos certificados
ALTER TABLE technician_documents 
ADD COLUMN IF NOT EXISTS certificate_name TEXT,
ADD COLUMN IF NOT EXISTS issue_date DATE,
ADD COLUMN IF NOT EXISTS expiry_date DATE;