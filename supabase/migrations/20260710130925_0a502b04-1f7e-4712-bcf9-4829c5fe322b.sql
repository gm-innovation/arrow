
CREATE TABLE public.ai_assistant_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  company_id uuid,
  role text,
  agent_id uuid,
  tool_name text NOT NULL,
  table_name text,
  row_id text,
  action text NOT NULL CHECK (action IN ('create','update','delete')),
  payload_before jsonb,
  payload_after jsonb,
  success boolean NOT NULL DEFAULT true,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.ai_assistant_actions TO authenticated;
GRANT ALL ON public.ai_assistant_actions TO service_role;

CREATE INDEX ai_assistant_actions_user_idx ON public.ai_assistant_actions(user_id, created_at DESC);
CREATE INDEX ai_assistant_actions_company_idx ON public.ai_assistant_actions(company_id, created_at DESC);
CREATE INDEX ai_assistant_actions_table_idx ON public.ai_assistant_actions(table_name, row_id);

ALTER TABLE public.ai_assistant_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own AI actions"
ON public.ai_assistant_actions FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Privileged roles see company AI actions"
ON public.ai_assistant_actions FOR SELECT TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'hr')
    OR public.has_role(auth.uid(), 'coordinator')
    OR public.has_role(auth.uid(), 'admin')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'super_admin')
  )
);
