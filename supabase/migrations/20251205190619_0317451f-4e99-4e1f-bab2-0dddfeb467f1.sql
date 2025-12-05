-- Policy for HR to view all technicians in their company
CREATE POLICY "HR can view all company technicians" 
ON public.technicians
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'hr'::app_role) 
  AND company_id = user_company_id(auth.uid())
);

-- Policy for HR to view all profiles in their company
CREATE POLICY "HR can view all company profiles" 
ON public.profiles
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'hr'::app_role) 
  AND company_id = user_company_id(auth.uid())
);

-- Policy for HR to view all time entries from technicians in their company
CREATE POLICY "HR can view all company time entries" 
ON public.time_entries
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'hr'::app_role) 
  AND EXISTS (
    SELECT 1 FROM technicians t
    WHERE t.id = time_entries.technician_id
    AND t.company_id = user_company_id(auth.uid())
  )
);