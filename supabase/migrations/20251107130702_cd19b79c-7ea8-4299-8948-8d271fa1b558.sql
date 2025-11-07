-- Add fields for report approval workflow
ALTER TABLE task_reports
ADD COLUMN IF NOT EXISTS rejection_reason text,
ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS approved_at timestamp with time zone;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_task_reports_status ON task_reports(status);
CREATE INDEX IF NOT EXISTS idx_task_reports_created_at ON task_reports(created_at DESC);