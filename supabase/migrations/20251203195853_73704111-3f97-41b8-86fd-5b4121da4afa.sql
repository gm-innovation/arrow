-- Fix: ai_proactive_alerts - Restrict INSERT to service_role only
DROP POLICY IF EXISTS "System can insert AI alerts" ON public.ai_proactive_alerts;

CREATE POLICY "Service role can insert AI alerts" 
ON public.ai_proactive_alerts 
FOR INSERT 
WITH CHECK (auth.role() = 'service_role');