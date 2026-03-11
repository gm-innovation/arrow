
-- Table: employee_onboarding
CREATE TABLE public.employee_onboarding (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id),
  user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  started_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  created_by uuid NOT NULL,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.employee_onboarding ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own onboarding" ON public.employee_onboarding
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "HR can manage onboarding" ON public.employee_onboarding
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role IN ('hr', 'super_admin')
    )
  );

-- Table: onboarding_document_types
CREATE TABLE public.onboarding_document_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id),
  name text NOT NULL,
  description text,
  is_required boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.onboarding_document_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can view onboarding doc types" ON public.onboarding_document_types
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "HR can manage onboarding doc types" ON public.onboarding_document_types
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role IN ('hr', 'super_admin')
    )
  );

-- Table: onboarding_documents
CREATE TABLE public.onboarding_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  onboarding_id uuid NOT NULL REFERENCES public.employee_onboarding(id) ON DELETE CASCADE,
  document_type_id uuid NOT NULL REFERENCES public.onboarding_document_types(id),
  file_name text NOT NULL,
  file_url text NOT NULL,
  uploaded_by uuid NOT NULL,
  status text DEFAULT 'pending',
  rejection_reason text,
  uploaded_at timestamptz DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by uuid
);

ALTER TABLE public.onboarding_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own onboarding docs" ON public.onboarding_documents
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.employee_onboarding eo
      WHERE eo.id = onboarding_id AND eo.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own onboarding docs" ON public.onboarding_documents
  FOR INSERT TO authenticated
  WITH CHECK (uploaded_by = auth.uid());

CREATE POLICY "HR can manage onboarding docs" ON public.onboarding_documents
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role IN ('hr', 'super_admin')
    )
  );
