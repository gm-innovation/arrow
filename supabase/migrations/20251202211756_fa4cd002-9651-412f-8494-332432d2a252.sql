-- Create table for WhatsApp conversation history
CREATE TABLE public.whatsapp_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id),
  phone_number TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  message TEXT NOT NULL,
  message_sid TEXT,
  ai_context JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.whatsapp_conversations ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view their own WhatsApp conversations"
ON public.whatsapp_conversations
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Service role can manage all WhatsApp conversations"
ON public.whatsapp_conversations
FOR ALL
USING (true)
WITH CHECK (true);

-- Index for phone number lookups
CREATE INDEX idx_whatsapp_conversations_phone ON public.whatsapp_conversations(phone_number);
CREATE INDEX idx_whatsapp_conversations_user ON public.whatsapp_conversations(user_id);
CREATE INDEX idx_whatsapp_conversations_created ON public.whatsapp_conversations(created_at DESC);