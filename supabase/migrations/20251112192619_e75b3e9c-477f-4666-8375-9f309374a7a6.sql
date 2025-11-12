-- Add cnpj column to clients table
ALTER TABLE public.clients 
ADD COLUMN cnpj TEXT;

-- Add comment to column
COMMENT ON COLUMN public.clients.cnpj IS 'CNPJ do cliente (Cadastro Nacional da Pessoa Jurídica)';