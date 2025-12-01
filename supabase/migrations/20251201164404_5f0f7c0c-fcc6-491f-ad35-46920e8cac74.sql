-- Adicionar constraint única para prevenir duplicatas futuras
ALTER TABLE task_reports ADD CONSTRAINT task_reports_task_uuid_unique UNIQUE (task_uuid);