
-- RLS policies for hr-health-exams bucket
CREATE POLICY "Employees view own health exam files"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'hr-health-exams'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "HR views all health exam files"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'hr-health-exams'
    AND (
      public.has_role(auth.uid(), 'hr'::app_role)
      OR public.has_role(auth.uid(), 'director'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );

CREATE POLICY "Manager views subordinate health exam files"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'hr-health-exams'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id::text = (storage.foldername(name))[1]
        AND p.direct_manager_id = auth.uid()
    )
  );

CREATE POLICY "HR manages health exam files"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'hr-health-exams'
    AND (
      public.has_role(auth.uid(), 'hr'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  )
  WITH CHECK (
    bucket_id = 'hr-health-exams'
    AND (
      public.has_role(auth.uid(), 'hr'::app_role)
      OR public.has_role(auth.uid(), 'super_admin'::app_role)
    )
  );
