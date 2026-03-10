DROP POLICY IF EXISTS dept_select ON departments;
CREATE POLICY dept_select ON departments FOR SELECT TO authenticated
USING (
  company_id = user_company_id(auth.uid())
  OR has_role(auth.uid(), 'super_admin')
);