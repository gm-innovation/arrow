update public.ai_agents
set identity = jsonb_set(coalesce(identity, '{}'::jsonb), '{avatar_url}', to_jsonb('/__l5e/assets-v1/57e7c171-8330-4fc0-9a19-8db0aad10fcb/ai-agent-avatar.png'::text), true)
where is_default = true and company_id is null;