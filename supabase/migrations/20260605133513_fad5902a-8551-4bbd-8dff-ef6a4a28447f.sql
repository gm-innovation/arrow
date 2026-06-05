
CREATE POLICY "qe_read_company" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'quality-evidences'
    AND (storage.foldername(name))[1] = public.user_company_id(auth.uid())::text
  );

CREATE POLICY "qe_write_qualidade" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'quality-evidences'
    AND (storage.foldername(name))[1] = public.user_company_id(auth.uid())::text
    AND (
      public.has_role(auth.uid(), 'qualidade')
      OR public.has_role(auth.uid(), 'director')
      OR public.has_role(auth.uid(), 'super_admin')
    )
  );

CREATE POLICY "qe_update_qualidade" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'quality-evidences'
    AND (storage.foldername(name))[1] = public.user_company_id(auth.uid())::text
    AND (
      public.has_role(auth.uid(), 'qualidade')
      OR public.has_role(auth.uid(), 'director')
      OR public.has_role(auth.uid(), 'super_admin')
    )
  );

CREATE POLICY "qe_delete_qualidade" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'quality-evidences'
    AND (storage.foldername(name))[1] = public.user_company_id(auth.uid())::text
    AND (
      public.has_role(auth.uid(), 'qualidade')
      OR public.has_role(auth.uid(), 'director')
      OR public.has_role(auth.uid(), 'super_admin')
    )
  );
