-- Atualizar bucket technician-documents para permitir acesso público às fotos
UPDATE storage.buckets 
SET public = true 
WHERE id = 'technician-documents';