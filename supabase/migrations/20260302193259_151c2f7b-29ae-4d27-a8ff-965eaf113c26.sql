
-- 1. Create department_members table
CREATE TABLE public.department_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  department_id uuid NOT NULL REFERENCES public.departments(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(department_id, user_id)
);

ALTER TABLE public.department_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view department members of their company"
  ON public.department_members FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM departments d
      JOIN profiles p ON p.company_id = d.company_id
      WHERE d.id = department_members.department_id
        AND p.id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage department members"
  ON public.department_members FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur WHERE ur.user_id = auth.uid() AND ur.role IN ('admin', 'super_admin')
    )
  );

-- 2. Update trigger function to include reimbursement
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
    (NEW.id, 'Reembolso', 'reimbursement', true, true),
    (NEW.id, 'Geral', 'general', false, true);
  RETURN NEW;
END;
$$;

-- 3. Seed reimbursement for existing companies that don't have it
INSERT INTO corp_request_types (company_id, name, category, requires_approval, active)
SELECT c.id, 'Reembolso', 'reimbursement', true, true
FROM companies c
WHERE NOT EXISTS (
  SELECT 1 FROM corp_request_types crt 
  WHERE crt.company_id = c.id AND crt.category = 'reimbursement'
);
