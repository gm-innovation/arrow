update public.ai_agents
set identity = jsonb_set(coalesce(identity, '{}'::jsonb), '{avatar_url}', to_jsonb('/__l5e/assets-v1/03acb8d3-5aa3-442f-8168-5c7ed6f568e8/ai-agent-avatar.png'::text), true)
where is_default = true and company_id is null;