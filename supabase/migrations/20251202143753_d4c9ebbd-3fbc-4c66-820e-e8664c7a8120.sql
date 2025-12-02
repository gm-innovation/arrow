-- Remover constraint antigo que só permite draft/submitted
ALTER TABLE public.task_reports DROP CONSTRAINT task_reports_status_check;

-- Criar novo constraint com todos os status válidos
ALTER TABLE public.task_reports ADD CONSTRAINT task_reports_status_check 
CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'approved'::text, 'rejected'::text]));