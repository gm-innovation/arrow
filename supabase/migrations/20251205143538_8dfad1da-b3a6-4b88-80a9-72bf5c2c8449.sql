-- Add task_order_number column to tasks table
ALTER TABLE public.tasks ADD COLUMN task_order_number text NULL;

-- Add comment for documentation
COMMENT ON COLUMN public.tasks.task_order_number IS 'Individual OS number for this task when single_report is false. If NULL, uses parent service_order order_number.';