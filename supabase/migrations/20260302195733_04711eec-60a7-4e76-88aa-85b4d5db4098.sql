CREATE POLICY "Users can view profiles in their company"
ON profiles FOR SELECT TO authenticated
USING (company_id = user_company_id(auth.uid()));