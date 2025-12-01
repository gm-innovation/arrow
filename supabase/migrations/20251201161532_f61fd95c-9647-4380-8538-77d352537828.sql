-- Add new fields to companies table
ALTER TABLE companies ADD COLUMN IF NOT EXISTS cnpj TEXT;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS cep TEXT;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS logo_url TEXT;