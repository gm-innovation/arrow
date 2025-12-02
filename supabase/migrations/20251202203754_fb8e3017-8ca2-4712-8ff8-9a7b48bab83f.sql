-- Enable pgvector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Create table for report embeddings
CREATE TABLE IF NOT EXISTS public.report_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_report_id UUID NOT NULL REFERENCES task_reports(id) ON DELETE CASCADE,
  embedding VECTOR(768),
  content_text TEXT,
  content_hash TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(task_report_id)
);

-- Create index for vector similarity search
CREATE INDEX IF NOT EXISTS report_embeddings_embedding_idx 
ON report_embeddings USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Enable RLS
ALTER TABLE report_embeddings ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view embeddings from their company
CREATE POLICY "Users can view report embeddings in their company"
ON report_embeddings FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM task_reports tr
    JOIN tasks t ON t.id::text = tr.task_id
    JOIN service_orders so ON so.id = t.service_order_id
    WHERE tr.id = task_report_id 
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- Policy: Admins can manage embeddings
CREATE POLICY "Admins can manage report embeddings"
ON report_embeddings FOR ALL
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  EXISTS (
    SELECT 1 FROM task_reports tr
    JOIN tasks t ON t.id::text = tr.task_id
    JOIN service_orders so ON so.id = t.service_order_id
    WHERE tr.id = task_report_id 
    AND so.company_id = user_company_id(auth.uid())
  )
);

-- Function to search similar reports using cosine similarity
CREATE OR REPLACE FUNCTION search_similar_reports(
  query_embedding VECTOR(768),
  match_threshold FLOAT DEFAULT 0.5,
  match_count INT DEFAULT 5,
  p_company_id UUID DEFAULT NULL
) RETURNS TABLE (
  task_report_id UUID,
  similarity FLOAT,
  report_data JSONB,
  content_text TEXT
) 
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    re.task_report_id,
    1 - (re.embedding <=> query_embedding) as similarity,
    tr.report_data,
    re.content_text
  FROM report_embeddings re
  JOIN task_reports tr ON tr.id = re.task_report_id
  JOIN tasks t ON t.id::text = tr.task_id
  JOIN service_orders so ON so.id = t.service_order_id
  WHERE (p_company_id IS NULL OR so.company_id = p_company_id)
    AND re.embedding IS NOT NULL
    AND 1 - (re.embedding <=> query_embedding) > match_threshold
  ORDER BY re.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- Table for AI proactive alerts (for Phase 6)
CREATE TABLE IF NOT EXISTS public.ai_proactive_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  company_id UUID REFERENCES companies(id),
  alert_type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  reference_data JSONB,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS for proactive alerts
ALTER TABLE ai_proactive_alerts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own alerts
CREATE POLICY "Users can view their own AI alerts"
ON ai_proactive_alerts FOR SELECT
USING (user_id = auth.uid());

-- Policy: Users can update their own alerts (mark as read)
CREATE POLICY "Users can update their own AI alerts"
ON ai_proactive_alerts FOR UPDATE
USING (user_id = auth.uid());

-- Policy: System can insert alerts for users in their company
CREATE POLICY "System can insert AI alerts"
ON ai_proactive_alerts FOR INSERT
WITH CHECK (true);

-- Update trigger for report_embeddings
CREATE OR REPLACE FUNCTION update_report_embeddings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_report_embeddings_timestamp
  BEFORE UPDATE ON report_embeddings
  FOR EACH ROW
  EXECUTE FUNCTION update_report_embeddings_updated_at();