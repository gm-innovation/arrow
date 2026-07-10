
CREATE SEQUENCE IF NOT EXISTS public.support_ticket_number_seq START 1000;

CREATE TABLE public.support_tickets (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_number INTEGER NOT NULL DEFAULT nextval('public.support_ticket_number_seq') UNIQUE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id UUID,
  user_role TEXT,
  user_name TEXT,
  user_email TEXT,
  category TEXT NOT NULL DEFAULT 'other' CHECK (category IN ('bug','feature_request','question','complaint','other')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low','medium','high','critical')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  conversation_excerpt JSONB,
  page_url TEXT,
  user_agent TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','in_review','in_progress','resolved','wont_fix')),
  admin_notes TEXT,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.support_tickets TO authenticated;
GRANT ALL ON public.support_tickets TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.support_ticket_number_seq TO authenticated, service_role;

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_insert_own_tickets"
  ON public.support_tickets FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users_read_own_tickets"
  ON public.support_tickets FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "super_admin_update_tickets"
  ON public.support_tickets FOR UPDATE
  TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "super_admin_delete_tickets"
  ON public.support_tickets FOR DELETE
  TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'));

CREATE TABLE public.support_ticket_messages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  author_role TEXT,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, DELETE ON public.support_ticket_messages TO authenticated;
GRANT ALL ON public.support_ticket_messages TO service_role;

ALTER TABLE public.support_ticket_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_ticket_messages"
  ON public.support_ticket_messages FOR SELECT
  TO authenticated
  USING (
    public.has_role(auth.uid(), 'super_admin')
    OR EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

CREATE POLICY "insert_ticket_messages"
  ON public.support_ticket_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = author_id AND (
      public.has_role(auth.uid(), 'super_admin')
      OR EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
    )
  );

CREATE POLICY "super_admin_delete_ticket_messages"
  ON public.support_ticket_messages FOR DELETE
  TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'));

CREATE OR REPLACE FUNCTION public.support_tickets_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_support_tickets_updated_at
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.support_tickets_set_updated_at();

CREATE INDEX idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX idx_support_tickets_created ON public.support_tickets(created_at DESC);
CREATE INDEX idx_support_ticket_messages_ticket ON public.support_ticket_messages(ticket_id, created_at);

CREATE OR REPLACE FUNCTION public.notify_support_ticket_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_user RECORD;
BEGIN
  FOR admin_user IN
    SELECT ur.user_id FROM public.user_roles ur WHERE ur.role = 'super_admin'
  LOOP
    INSERT INTO public.notifications (user_id, type, title, message, link, read)
    VALUES (
      admin_user.user_id,
      'support_ticket_created',
      'Novo chamado #' || NEW.ticket_number,
      COALESCE(NEW.user_name, 'Usuário') || ' abriu: ' || NEW.title,
      '/super-admin/support-inbox?ticket=' || NEW.id::text,
      false
    );
  END LOOP;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_support_ticket_created
  AFTER INSERT ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.notify_support_ticket_created();

CREATE OR REPLACE FUNCTION public.notify_support_ticket_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ticket_row RECORD;
  admin_user RECORD;
BEGIN
  SELECT * INTO ticket_row FROM public.support_tickets WHERE id = NEW.ticket_id;
  IF NEW.is_admin THEN
    INSERT INTO public.notifications (user_id, type, title, message, link, read)
    VALUES (
      ticket_row.user_id,
      'support_ticket_reply',
      'Resposta no chamado #' || ticket_row.ticket_number,
      'Você recebeu uma resposta do suporte.',
      '/account/support?ticket=' || ticket_row.id::text,
      false
    );
  ELSE
    FOR admin_user IN
      SELECT ur.user_id FROM public.user_roles ur WHERE ur.role = 'super_admin'
    LOOP
      INSERT INTO public.notifications (user_id, type, title, message, link, read)
      VALUES (
        admin_user.user_id,
        'support_ticket_reply',
        'Nova mensagem no chamado #' || ticket_row.ticket_number,
        COALESCE(ticket_row.user_name, 'Usuário') || ' respondeu.',
        '/super-admin/support-inbox?ticket=' || ticket_row.id::text,
        false
      );
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_support_ticket_message
  AFTER INSERT ON public.support_ticket_messages
  FOR EACH ROW EXECUTE FUNCTION public.notify_support_ticket_message();
