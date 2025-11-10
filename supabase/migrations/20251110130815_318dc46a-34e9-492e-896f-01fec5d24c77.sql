-- Create system_settings table for global configurations
CREATE TABLE IF NOT EXISTS public.system_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Super admins can manage settings
CREATE POLICY "Super admins can manage settings"
ON public.system_settings
FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- Super admins can view settings
CREATE POLICY "Super admins can view settings"
ON public.system_settings
FOR SELECT
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- Create trigger for updated_at
CREATE TRIGGER update_system_settings_updated_at
BEFORE UPDATE ON public.system_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();

-- Insert default settings
INSERT INTO public.system_settings (key, value) VALUES
  ('notifications_enabled', '{"enabled": true}'::jsonb),
  ('email_notifications_enabled', '{"enabled": true}'::jsonb),
  ('whatsapp_api_key', '{"key": ""}'::jsonb),
  ('whatsapp_schedule', '{"schedule": "anytime"}'::jsonb),
  ('theme', '{"theme": "system"}'::jsonb),
  ('primary_color', '{"color": "blue"}'::jsonb),
  ('audit_logs_enabled', '{"enabled": true}'::jsonb),
  ('audit_retention_period', '{"days": 90}'::jsonb)
ON CONFLICT (key) DO NOTHING;