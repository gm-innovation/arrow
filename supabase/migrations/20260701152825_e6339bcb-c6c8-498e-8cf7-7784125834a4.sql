
-- Fase Onda 4: aprimoramentos em Conscientização
-- 1) participantes externos (texto livre) + 2) ciência opt-in + 3) notificação in-app

ALTER TABLE public.quality_awareness_events
  ADD COLUMN IF NOT EXISTS external_attendees jsonb NOT NULL DEFAULT '[]'::jsonb;

-- Passa a exigir confirmação explícita de ciência (novos registros começam sem ack)
ALTER TABLE public.quality_awareness_attendees
  ALTER COLUMN acknowledged_at DROP DEFAULT;

-- Trigger de notificação in-app ao adicionar participante interno
CREATE OR REPLACE FUNCTION public.notify_awareness_attendee()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_topic text;
BEGIN
  SELECT topic INTO v_topic FROM public.quality_awareness_events WHERE id = NEW.event_id;
  IF v_topic IS NULL THEN RETURN NEW; END IF;
  INSERT INTO public.notifications (user_id, notification_type, title, message, reference_id)
  VALUES (
    NEW.user_id,
    'quality_alert',
    'Conscientização registrada',
    'Você foi incluído no evento de conscientização: ' || v_topic || '. Confirme a ciência na sua área.',
    NEW.event_id
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_awareness_attendee ON public.quality_awareness_attendees;
CREATE TRIGGER trg_notify_awareness_attendee
AFTER INSERT ON public.quality_awareness_attendees
FOR EACH ROW EXECUTE FUNCTION public.notify_awareness_attendee();

-- Permitir que o próprio participante marque ciência
DROP POLICY IF EXISTS "attendees_ack_self" ON public.quality_awareness_attendees;
CREATE POLICY "attendees_ack_self"
ON public.quality_awareness_attendees
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
