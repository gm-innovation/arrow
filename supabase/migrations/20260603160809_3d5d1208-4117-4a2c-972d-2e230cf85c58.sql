
-- Habilitar pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- =========================
-- ai_agents
-- =========================
CREATE TABLE public.ai_agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  description TEXT,
  is_default BOOLEAN NOT NULL DEFAULT false,
  enabled BOOLEAN NOT NULL DEFAULT true,
  identity JSONB NOT NULL DEFAULT '{}'::jsonb,
  behavior JSONB NOT NULL DEFAULT '{}'::jsonb,
  guardrails JSONB NOT NULL DEFAULT '{}'::jsonb,
  tools_model JSONB NOT NULL DEFAULT '{}'::jsonb,
  appearance JSONB NOT NULL DEFAULT '{}'::jsonb,
  scope JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (company_id, slug)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_agents TO authenticated;
GRANT ALL ON public.ai_agents TO service_role;

ALTER TABLE public.ai_agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_agents super admin all"
  ON public.ai_agents FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "ai_agents company managers manage"
  ON public.ai_agents FOR ALL TO authenticated
  USING (
    company_id IS NOT NULL
    AND company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'hr'::app_role)
    )
  )
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'hr'::app_role)
    )
  );

CREATE POLICY "ai_agents authenticated read enabled"
  ON public.ai_agents FOR SELECT TO authenticated
  USING (
    enabled = true
    AND (
      company_id IS NULL
      OR company_id = public.user_company_id(auth.uid())
    )
  );

CREATE TRIGGER trg_ai_agents_updated_at
  BEFORE UPDATE ON public.ai_agents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =========================
-- ai_knowledge_sources
-- =========================
CREATE TABLE public.ai_knowledge_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.ai_agents(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL CHECK (source_type IN ('pdf','docx','txt','url','manual')),
  title TEXT NOT NULL,
  storage_path TEXT,
  url TEXT,
  raw_text TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','indexed','error')),
  error_message TEXT,
  chunk_count INTEGER NOT NULL DEFAULT 0,
  tags TEXT[] NOT NULL DEFAULT '{}',
  scope JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_knowledge_sources TO authenticated;
GRANT ALL ON public.ai_knowledge_sources TO service_role;

ALTER TABLE public.ai_knowledge_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_knowledge_sources super admin all"
  ON public.ai_knowledge_sources FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "ai_knowledge_sources company managers"
  ON public.ai_knowledge_sources FOR ALL TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'hr'::app_role)
    )
  )
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
  );

CREATE TRIGGER trg_ai_knowledge_sources_updated_at
  BEFORE UPDATE ON public.ai_knowledge_sources
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =========================
-- ai_knowledge_chunks (RAG)
-- =========================
CREATE TABLE public.ai_knowledge_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID NOT NULL REFERENCES public.ai_knowledge_sources(id) ON DELETE CASCADE,
  agent_id UUID REFERENCES public.ai_agents(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  chunk_index INTEGER NOT NULL,
  content TEXT NOT NULL,
  embedding vector(1536),
  token_count INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ai_knowledge_chunks_source ON public.ai_knowledge_chunks(source_id);
CREATE INDEX idx_ai_knowledge_chunks_agent ON public.ai_knowledge_chunks(agent_id);
CREATE INDEX idx_ai_knowledge_chunks_embedding ON public.ai_knowledge_chunks
  USING hnsw (embedding vector_cosine_ops);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_knowledge_chunks TO authenticated;
GRANT ALL ON public.ai_knowledge_chunks TO service_role;

ALTER TABLE public.ai_knowledge_chunks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_knowledge_chunks super admin all"
  ON public.ai_knowledge_chunks FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "ai_knowledge_chunks company managers"
  ON public.ai_knowledge_chunks FOR ALL TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'hr'::app_role)
    )
  )
  WITH CHECK (
    company_id = public.user_company_id(auth.uid())
  );

-- Função de busca semântica
CREATE OR REPLACE FUNCTION public.match_ai_knowledge(
  query_embedding vector(1536),
  p_agent_id UUID DEFAULT NULL,
  p_company_id UUID DEFAULT NULL,
  match_threshold FLOAT DEFAULT 0.5,
  match_count INT DEFAULT 5
)
RETURNS TABLE (
  id UUID,
  source_id UUID,
  content TEXT,
  similarity FLOAT
)
LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT
    c.id,
    c.source_id,
    c.content,
    1 - (c.embedding <=> query_embedding) AS similarity
  FROM public.ai_knowledge_chunks c
  WHERE c.embedding IS NOT NULL
    AND (p_agent_id IS NULL OR c.agent_id = p_agent_id OR c.agent_id IS NULL)
    AND (p_company_id IS NULL OR c.company_id = p_company_id OR c.company_id IS NULL)
    AND 1 - (c.embedding <=> query_embedding) > match_threshold
  ORDER BY c.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- =========================
-- ai_training_examples (few-shot)
-- =========================
CREATE TABLE public.ai_training_examples (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.ai_agents(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  ideal_answer TEXT NOT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}',
  source TEXT,
  source_message_id UUID,
  active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_training_examples TO authenticated;
GRANT ALL ON public.ai_training_examples TO service_role;

ALTER TABLE public.ai_training_examples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_training_examples super admin all"
  ON public.ai_training_examples FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "ai_training_examples company managers"
  ON public.ai_training_examples FOR ALL TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'hr'::app_role)
    )
  )
  WITH CHECK (company_id = public.user_company_id(auth.uid()));

CREATE TRIGGER trg_ai_training_examples_updated_at
  BEFORE UPDATE ON public.ai_training_examples
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =========================
-- ai_fine_tune_jobs
-- =========================
CREATE TABLE public.ai_fine_tune_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.ai_agents(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  provider TEXT NOT NULL DEFAULT 'openai',
  base_model TEXT NOT NULL,
  external_job_id TEXT,
  fine_tuned_model TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  dataset_storage_path TEXT,
  example_count INTEGER NOT NULL DEFAULT 0,
  cost_estimate NUMERIC(12,4),
  error_message TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_fine_tune_jobs TO authenticated;
GRANT ALL ON public.ai_fine_tune_jobs TO service_role;

ALTER TABLE public.ai_fine_tune_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_fine_tune_jobs super admin all"
  ON public.ai_fine_tune_jobs FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE TRIGGER trg_ai_fine_tune_jobs_updated_at
  BEFORE UPDATE ON public.ai_fine_tune_jobs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =========================
-- ai_channel_bindings
-- =========================
CREATE TABLE public.ai_channel_bindings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES public.ai_agents(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp','teams','outlook','api')),
  enabled BOOLEAN NOT NULL DEFAULT true,
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_channel_bindings TO authenticated;
GRANT ALL ON public.ai_channel_bindings TO service_role;

ALTER TABLE public.ai_channel_bindings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_channel_bindings super admin all"
  ON public.ai_channel_bindings FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "ai_channel_bindings company managers"
  ON public.ai_channel_bindings FOR ALL TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
    )
  )
  WITH CHECK (company_id = public.user_company_id(auth.uid()));

CREATE TRIGGER trg_ai_channel_bindings_updated_at
  BEFORE UPDATE ON public.ai_channel_bindings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =========================
-- ai_email_activity
-- =========================
CREATE TABLE public.ai_email_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.ai_agents(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  external_message_id TEXT,
  from_address TEXT,
  subject TEXT,
  action TEXT NOT NULL CHECK (action IN ('draft_created','auto_replied','skipped','error')),
  response_preview TEXT,
  error_message TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_email_activity TO authenticated;
GRANT ALL ON public.ai_email_activity TO service_role;

ALTER TABLE public.ai_email_activity ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_email_activity super admin all"
  ON public.ai_email_activity FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "ai_email_activity company read"
  ON public.ai_email_activity FOR SELECT TO authenticated
  USING (
    company_id = public.user_company_id(auth.uid())
    AND (
      public.has_role(auth.uid(), 'coordinator'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
    )
  );

-- =========================
-- Seed: agente padrão global
-- =========================
INSERT INTO public.ai_agents (company_id, name, slug, description, is_default, enabled, identity, behavior, guardrails, tools_model, appearance, scope)
VALUES (
  NULL,
  'NavalOS AI',
  'navalos-ai',
  'Agente padrão do sistema',
  true,
  true,
  '{"name":"NavalOS AI","tagline":"Assistente inteligente","welcome_message":"Olá! Como posso ajudar?","tone":"amigavel","language":"pt-BR","persona":"Você é um assistente para o sistema NavalOS, especialista em operações navais, gestão de OS, técnicos e relatórios."}'::jsonb,
  '{"suggested_prompts":["Resumo das OS pendentes","Quais técnicos estão disponíveis hoje?","Gerar relatório"],"role_instructions":{},"auto_flows":{"detect_report":true,"availability":true,"order_status":true},"memory_size":20}'::jsonb,
  '{"forbidden_topics":["politica","religiao"],"pii_filter":true,"blocked_message":"Não posso ajudar com este tópico.","daily_limit":100,"max_tokens":2000,"disclaimer":""}'::jsonb,
  '{"model":"google/gemini-2.5-flash","image_model":"google/gemini-2.5-pro","temperature":0.7,"max_tokens":2000,"enabled_tools":["search_reports","availability","order_status","report_generation","vision","proactive_alerts","knowledge_base"]}'::jsonb,
  '{"position":"bottom-right","primary_color":"hsl(var(--primary))","size":"medium","shape":"circle","icon":"Bot","animation":"fade","theme":"auto","visible_roles":["technician","coordinator","manager","director","hr","commercial","financeiro","qualidade","compras"],"hidden_routes":[]}'::jsonb,
  '{"roles":[],"routes":[]}'::jsonb
)
ON CONFLICT (company_id, slug) DO NOTHING;
