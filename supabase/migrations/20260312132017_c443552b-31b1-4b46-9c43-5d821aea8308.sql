
-- Table for HR notes/observations about employees
CREATE TABLE public.employee_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  employee_user_id UUID NOT NULL,
  author_id UUID NOT NULL,
  note_type TEXT NOT NULL DEFAULT 'general',
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_confidential BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.employee_notes ENABLE ROW LEVEL SECURITY;

-- Security definer function to check if user is HR or Director in same company
CREATE OR REPLACE FUNCTION public.is_hr_or_director_in_company(_user_id uuid, _company_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM user_roles ur
    JOIN profiles p ON p.id = ur.user_id
    WHERE ur.user_id = _user_id
      AND ur.role IN ('hr', 'director')
      AND p.company_id = _company_id
  )
$$;

-- RLS: HR and Directors can SELECT notes from their company
CREATE POLICY "HR/Director can view employee notes"
ON public.employee_notes
FOR SELECT
TO authenticated
USING (public.is_hr_or_director_in_company(auth.uid(), company_id));

-- RLS: HR and Directors can INSERT notes for their company
CREATE POLICY "HR/Director can insert employee notes"
ON public.employee_notes
FOR INSERT
TO authenticated
WITH CHECK (public.is_hr_or_director_in_company(auth.uid(), company_id));

-- RLS: HR and Directors can UPDATE notes from their company
CREATE POLICY "HR/Director can update employee notes"
ON public.employee_notes
FOR UPDATE
TO authenticated
USING (public.is_hr_or_director_in_company(auth.uid(), company_id));

-- RLS: HR and Directors can DELETE notes from their company
CREATE POLICY "HR/Director can delete employee notes"
ON public.employee_notes
FOR DELETE
TO authenticated
USING (public.is_hr_or_director_in_company(auth.uid(), company_id));

-- Trigger for updated_at
CREATE TRIGGER update_employee_notes_updated_at
  BEFORE UPDATE ON public.employee_notes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();
