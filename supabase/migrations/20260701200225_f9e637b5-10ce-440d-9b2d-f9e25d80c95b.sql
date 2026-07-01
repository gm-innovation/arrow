
-- Policies for quality-norms bucket. Path convention: {company_id}/{norm_id}/{filename}
CREATE POLICY "quality_norms_select" ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'quality-norms'
  AND (storage.foldername(name))[1] = (SELECT company_id::text FROM public.profiles WHERE id = auth.uid())
);

CREATE POLICY "quality_norms_insert" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'quality-norms'
  AND (storage.foldername(name))[1] = (SELECT company_id::text FROM public.profiles WHERE id = auth.uid())
);

CREATE POLICY "quality_norms_update" ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'quality-norms'
  AND (storage.foldername(name))[1] = (SELECT company_id::text FROM public.profiles WHERE id = auth.uid())
);

CREATE POLICY "quality_norms_delete" ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'quality-norms'
  AND (storage.foldername(name))[1] = (SELECT company_id::text FROM public.profiles WHERE id = auth.uid())
);
