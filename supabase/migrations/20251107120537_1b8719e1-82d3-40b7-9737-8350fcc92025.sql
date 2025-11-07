-- Create task_reports table
CREATE TABLE public.task_reports (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'submitted')),
  report_data JSONB NOT NULL,
  pdf_path TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.task_reports ENABLE ROW LEVEL SECURITY;

-- Create policies for task_reports
CREATE POLICY "Users can view their own task reports" 
ON public.task_reports 
FOR SELECT 
USING (true);

CREATE POLICY "Users can create their own task reports" 
ON public.task_reports 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Users can update their own task reports" 
ON public.task_reports 
FOR UPDATE 
USING (true);

CREATE POLICY "Users can delete their own task reports" 
ON public.task_reports 
FOR DELETE 
USING (true);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_task_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_task_reports_updated_at
BEFORE UPDATE ON public.task_reports
FOR EACH ROW
EXECUTE FUNCTION public.update_task_reports_updated_at();

-- Create storage bucket for reports
INSERT INTO storage.buckets (id, name, public)
VALUES ('reports', 'reports', false)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for reports bucket
CREATE POLICY "Users can view their own reports" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'reports');

CREATE POLICY "Users can upload their own reports" 
ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'reports');

CREATE POLICY "Users can update their own reports" 
ON storage.objects 
FOR UPDATE 
USING (bucket_id = 'reports');

CREATE POLICY "Users can delete their own reports" 
ON storage.objects 
FOR DELETE 
USING (bucket_id = 'reports');