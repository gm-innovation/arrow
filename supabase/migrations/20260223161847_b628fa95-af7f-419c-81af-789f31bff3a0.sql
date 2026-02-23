
-- Create crm_tasks table for commercial task management
CREATE TABLE public.crm_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  opportunity_id UUID REFERENCES public.crm_opportunities(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'medium',
  status TEXT NOT NULL DEFAULT 'pending',
  due_date DATE,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.crm_tasks ENABLE ROW LEVEL SECURITY;

-- Helper function to check user company
CREATE OR REPLACE FUNCTION public.user_company_id(_user_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT company_id FROM profiles WHERE id = _user_id
$$;

-- RLS: commercial and admin users in same company can do full CRUD
CREATE POLICY "Users can view crm_tasks in their company"
ON public.crm_tasks
FOR SELECT
TO authenticated
USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "Users can insert crm_tasks in their company"
ON public.crm_tasks
FOR INSERT
TO authenticated
WITH CHECK (company_id = user_company_id(auth.uid()));

CREATE POLICY "Users can update crm_tasks in their company"
ON public.crm_tasks
FOR UPDATE
TO authenticated
USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "Users can delete crm_tasks in their company"
ON public.crm_tasks
FOR DELETE
TO authenticated
USING (company_id = user_company_id(auth.uid()));

-- Trigger for updated_at
CREATE TRIGGER update_crm_tasks_updated_at
BEFORE UPDATE ON public.crm_tasks
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();
