update public.ai_agents
set identity = jsonb_set(coalesce(identity, '{}'::jsonb), '{avatar_url}', to_jsonb('/__l5e/assets-v1/0da136d1-136e-4584-825a-df508c064c2b/ai-agent-avatar.png'::text), true)
where is_default = true and company_id is null;