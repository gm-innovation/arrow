-- Create task_categories table
CREATE TABLE task_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  UNIQUE(name, company_id)
);

-- Enable RLS
ALTER TABLE task_categories ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view categories in their company"
  ON task_categories FOR SELECT
  USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "Admins can manage categories in their company"
  ON task_categories FOR ALL
  USING (has_role(auth.uid(), 'admin'::app_role) AND company_id = user_company_id(auth.uid()));

-- Trigger for updated_at
CREATE TRIGGER update_task_categories_updated_at
  BEFORE UPDATE ON task_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();