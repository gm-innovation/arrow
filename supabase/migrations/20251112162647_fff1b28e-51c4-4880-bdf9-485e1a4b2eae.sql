-- Add pdf_path column to measurements table
ALTER TABLE measurements ADD COLUMN IF NOT EXISTS pdf_path text;