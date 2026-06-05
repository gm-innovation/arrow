UPDATE public.ai_agents
SET behavior = jsonb_set(
  behavior,
  '{role_instructions}',
  (
    SELECT jsonb_object_agg(
      key,
      CASE
        WHEN key IN ('commercial','coordinator','manager','director','super_admin')
          THEN to_jsonb(
            value || E'\n\nDESAMBIGUAÇÃO POR CONTEXTO: termos genéricos logo após uma listagem ("quais as solicitações?", "o que pediram?", "me mostra os detalhes", "e os contatos?") referem-se aos itens recém-listados. Para leads, "solicitação" é o conteúdo dos campos message e items retornados por query_crm_leads — resuma esses campos sem rechamar a ferramenta e sem perguntar de qual módulo se trata.'
          )
        ELSE to_jsonb(value)
      END
    )
    FROM jsonb_each_text(behavior->'role_instructions')
  )
)
WHERE behavior ? 'role_instructions'
  AND behavior->'role_instructions' ?| array['commercial','coordinator','manager','director','super_admin'];