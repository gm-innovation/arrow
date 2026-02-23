
ALTER TABLE public.crm_knowledge_base
  ADD COLUMN target_segment text DEFAULT 'todos',
  ADD COLUMN priority text DEFAULT 'media',
  ADD COLUMN version text DEFAULT '1.0',
  ADD COLUMN notes text;
