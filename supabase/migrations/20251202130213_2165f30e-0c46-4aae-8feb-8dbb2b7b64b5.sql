-- FASE 4: Tabela para Push Subscriptions
CREATE TABLE IF NOT EXISTS public.push_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  endpoint TEXT NOT NULL,
  p256dh TEXT NOT NULL,
  auth TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, endpoint)
);

ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own push subscriptions" 
ON public.push_subscriptions FOR ALL 
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- FASE 6: Tabela para Snapshots de Produtividade
CREATE TABLE IF NOT EXISTS public.productivity_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  technician_id UUID NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  snapshot_date DATE NOT NULL,
  tasks_completed INTEGER DEFAULT 0,
  tasks_assigned INTEGER DEFAULT 0,
  hours_worked DECIMAL(10,2) DEFAULT 0,
  average_task_duration DECIMAL(10,2),
  satisfaction_avg DECIMAL(3,2),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(technician_id, snapshot_date)
);

ALTER TABLE public.productivity_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view productivity in their company" 
ON public.productivity_snapshots FOR SELECT 
USING (company_id = user_company_id(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Managers can view all productivity" 
ON public.productivity_snapshots FOR SELECT 
USING (company_id = user_company_id(auth.uid()) AND has_role(auth.uid(), 'manager'::app_role));

CREATE POLICY "Super admins can manage all productivity" 
ON public.productivity_snapshots FOR ALL 
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- FASE 7: Sistema de Chat - Conversas
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  title TEXT,
  conversation_type TEXT DEFAULT 'direct' CHECK (conversation_type IN ('direct', 'group', 'service_order')),
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE SET NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- FASE 7: Participantes das Conversas
CREATE TABLE IF NOT EXISTS public.conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  last_read_at TIMESTAMPTZ,
  UNIQUE(conversation_id, user_id)
);

ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

-- FASE 7: Mensagens
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
  attachment_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  edited_at TIMESTAMPTZ
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Habilitar Realtime para mensagens
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- RLS para Conversations
CREATE POLICY "Users can view conversations they participate in" 
ON public.conversations FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM conversation_participants cp 
    WHERE cp.conversation_id = conversations.id AND cp.user_id = auth.uid()
  )
);

CREATE POLICY "Users can create conversations in their company" 
ON public.conversations FOR INSERT 
WITH CHECK (company_id = user_company_id(auth.uid()));

CREATE POLICY "Admins can view all company conversations" 
ON public.conversations FOR SELECT 
USING (company_id = user_company_id(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role));

-- RLS para Participants
CREATE POLICY "Users can view participants of their conversations" 
ON public.conversation_participants FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM conversation_participants cp 
    WHERE cp.conversation_id = conversation_participants.conversation_id AND cp.user_id = auth.uid()
  )
);

CREATE POLICY "Users can join conversations" 
ON public.conversation_participants FOR INSERT 
WITH CHECK (user_id = auth.uid() OR has_role(auth.uid(), 'admin'::app_role));

-- RLS para Messages
CREATE POLICY "Users can view messages in their conversations" 
ON public.messages FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM conversation_participants cp 
    WHERE cp.conversation_id = messages.conversation_id AND cp.user_id = auth.uid()
  )
);

CREATE POLICY "Users can send messages to their conversations" 
ON public.messages FOR INSERT 
WITH CHECK (
  sender_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM conversation_participants cp 
    WHERE cp.conversation_id = messages.conversation_id AND cp.user_id = auth.uid()
  )
);

CREATE POLICY "Users can edit their own messages" 
ON public.messages FOR UPDATE 
USING (sender_id = auth.uid());

-- Trigger para atualizar updated_at em conversations
CREATE TRIGGER update_conversations_updated_at
  BEFORE UPDATE ON public.conversations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Função para atualizar last_read_at
CREATE OR REPLACE FUNCTION public.mark_messages_as_read(_conversation_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE conversation_participants
  SET last_read_at = now()
  WHERE conversation_id = _conversation_id AND user_id = auth.uid();
END;
$$;