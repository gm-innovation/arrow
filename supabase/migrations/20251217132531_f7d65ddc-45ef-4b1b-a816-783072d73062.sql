-- Add column for signed report PDF path
ALTER TABLE public.task_reports 
ADD COLUMN IF NOT EXISTS signed_pdf_path TEXT;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_task_reports_signed_pdf_path 
ON public.task_reports(signed_pdf_path) WHERE signed_pdf_path IS NOT NULL;

-- Update RLS policy to allow technicians to update signed_pdf_path on their own reports
CREATE POLICY "Technicians can update signed_pdf_path on own reports" 
ON public.task_reports 
FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM tasks t
    JOIN technicians tech ON t.assigned_to = tech.id
    WHERE t.id::text = task_id
    AND tech.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM tasks t
    JOIN technicians tech ON t.assigned_to = tech.id
    WHERE t.id::text = task_id
    AND tech.user_id = auth.uid()
  )
);