-- Create technician-avatars bucket for profile photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'technician-avatars',
  'technician-avatars',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
);

-- Policy: Anyone can view technician avatars (public read)
CREATE POLICY "Public can view technician avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'technician-avatars');

-- Policy: Admins can upload avatars
CREATE POLICY "Admins can upload technician avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'technician-avatars' 
  AND (
    has_role(auth.uid(), 'admin'::app_role) 
    OR has_role(auth.uid(), 'super_admin'::app_role)
  )
);

-- Policy: Admins can update avatars
CREATE POLICY "Admins can update technician avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'technician-avatars' 
  AND (
    has_role(auth.uid(), 'admin'::app_role) 
    OR has_role(auth.uid(), 'super_admin'::app_role)
  )
);

-- Policy: Admins can delete avatars
CREATE POLICY "Admins can delete technician avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'technician-avatars' 
  AND (
    has_role(auth.uid(), 'admin'::app_role) 
    OR has_role(auth.uid(), 'super_admin'::app_role)
  )
);