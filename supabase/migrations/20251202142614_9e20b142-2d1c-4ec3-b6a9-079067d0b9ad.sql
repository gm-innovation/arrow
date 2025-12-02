-- Parte 1: Permitir admins gerenciarem configurações de WhatsApp da sua empresa

-- Política para admins fazerem CRUD em configurações da sua empresa
CREATE POLICY "Admins can manage their company settings"
ON public.system_settings
FOR ALL
USING (
  public.has_role(auth.uid(), 'admin'::app_role) 
  AND key LIKE '%_' || public.user_company_id(auth.uid())::text
)
WITH CHECK (
  public.has_role(auth.uid(), 'admin'::app_role) 
  AND key LIKE '%_' || public.user_company_id(auth.uid())::text
);

-- Parte 2: Corrigir recursão infinita em conversation_participants

-- Criar função security definer para verificar participação
CREATE OR REPLACE FUNCTION public.is_conversation_participant(_user_id uuid, _conversation_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM conversation_participants
    WHERE user_id = _user_id
      AND conversation_id = _conversation_id
  )
$$;

-- Dropar política problemática com recursão
DROP POLICY IF EXISTS "Users can view participants of their conversations" 
ON public.conversation_participants;

-- Criar nova política usando a função security definer
CREATE POLICY "Users can view participants of their conversations"
ON public.conversation_participants
FOR SELECT
USING (
  user_id = auth.uid() OR public.is_conversation_participant(auth.uid(), conversation_id)
);