
-- Function to auto-create default request types for a new company
CREATE OR REPLACE FUNCTION public.auto_create_corp_request_types_for_company()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO corp_request_types (company_id, name, category, requires_approval, active) VALUES
    (NEW.id, 'Produto / Material', 'product', true, true),
    (NEW.id, 'Assinatura / Software', 'subscription', true, true),
    (NEW.id, 'Documento', 'document', false, true),
    (NEW.id, 'Folga / Férias', 'time_off', true, true),
    (NEW.id, 'Geral', 'general', false, true);
  RETURN NEW;
END;
$$;

-- Trigger for new companies
CREATE TRIGGER trg_auto_create_corp_request_types
  AFTER INSERT ON public.companies
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_corp_request_types_for_company();

-- Seed default types for existing companies that don't have any
INSERT INTO corp_request_types (company_id, name, category, requires_approval, active)
SELECT c.id, t.name, t.category, t.requires_approval, true
FROM companies c
CROSS JOIN (
  VALUES 
    ('Produto / Material', 'product', true),
    ('Assinatura / Software', 'subscription', true),
    ('Documento', 'document', false),
    ('Folga / Férias', 'time_off', true),
    ('Geral', 'general', false)
) AS t(name, category, requires_approval)
WHERE NOT EXISTS (
  SELECT 1 FROM corp_request_types crt WHERE crt.company_id = c.id
);
