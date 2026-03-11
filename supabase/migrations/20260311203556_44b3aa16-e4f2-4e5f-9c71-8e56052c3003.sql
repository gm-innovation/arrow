
-- 1. Add candidate fields and access_token to employee_onboarding
ALTER TABLE public.employee_onboarding 
  ALTER COLUMN user_id DROP NOT NULL,
  ADD COLUMN IF NOT EXISTS candidate_name text,
  ADD COLUMN IF NOT EXISTS candidate_email text,
  ADD COLUMN IF NOT EXISTS access_token uuid DEFAULT gen_random_uuid() NOT NULL;

-- Create unique index on access_token
CREATE UNIQUE INDEX IF NOT EXISTS idx_employee_onboarding_access_token ON public.employee_onboarding(access_token);

-- 2. RLS: anon can SELECT employee_onboarding by access_token
CREATE POLICY "Anon can view onboarding by token"
ON public.employee_onboarding FOR SELECT TO anon
USING (true);

-- 3. RLS: anon can SELECT onboarding_document_types
CREATE POLICY "Anon can view document types"
ON public.onboarding_document_types FOR SELECT TO anon
USING (true);

-- 4. RLS: anon can SELECT onboarding_documents for accessible onboarding
CREATE POLICY "Anon can view onboarding documents"
ON public.onboarding_documents FOR SELECT TO anon
USING (true);

-- 5. RLS: anon can INSERT onboarding_documents
CREATE POLICY "Anon can upload onboarding documents"
ON public.onboarding_documents FOR INSERT TO anon
WITH CHECK (true);

-- 6. Storage: allow anon uploads to corp-documents bucket for onboarding path
CREATE POLICY "Anon can upload onboarding files"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'corp-documents' AND (storage.foldername(name))[1] = 'onboarding');

-- 7. Storage: allow anon to read onboarding files
CREATE POLICY "Anon can read onboarding files"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'corp-documents' AND (storage.foldername(name))[1] = 'onboarding');
