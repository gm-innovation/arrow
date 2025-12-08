-- Política para HR atualizar profiles da empresa
CREATE POLICY "HR can update profiles in their company"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'hr'::app_role) 
  AND company_id = user_company_id(auth.uid())
)
WITH CHECK (
  has_role(auth.uid(), 'hr'::app_role) 
  AND company_id = user_company_id(auth.uid())
);

-- Políticas de Storage para technician-avatars
CREATE POLICY "HR can upload technician avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'technician-avatars' 
  AND has_role(auth.uid(), 'hr'::app_role)
);

CREATE POLICY "HR can update technician avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'technician-avatars' 
  AND has_role(auth.uid(), 'hr'::app_role)
);

-- Políticas de Storage para technician-documents
CREATE POLICY "HR can upload technician documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'technician-documents' 
  AND has_role(auth.uid(), 'hr'::app_role)
);

CREATE POLICY "HR can update technician documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'technician-documents' 
  AND has_role(auth.uid(), 'hr'::app_role)
);

CREATE POLICY "HR can delete technician documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'technician-documents' 
  AND has_role(auth.uid(), 'hr'::app_role)
);