-- Create technician_documents table
CREATE TABLE IF NOT EXISTS technician_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  technician_id UUID REFERENCES technicians(id) ON DELETE CASCADE NOT NULL,
  document_type TEXT CHECK (document_type IN ('aso', 'certification', 'other')) NOT NULL,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  valid_until DATE,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Add new columns to technicians table
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS cpf TEXT UNIQUE;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS rg TEXT;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS nationality TEXT;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS height INTEGER;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS blood_type TEXT;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS blood_rh_factor TEXT;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS aso_valid_until DATE;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS medical_status TEXT CHECK (medical_status IN ('fit', 'unfit', 'pending'));

-- Enable RLS on technician_documents
ALTER TABLE technician_documents ENABLE ROW LEVEL SECURITY;

-- RLS policies for technician_documents
CREATE POLICY "Users can view documents in their company"
  ON technician_documents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM technicians 
      WHERE technicians.id = technician_documents.technician_id 
      AND technicians.company_id = user_company_id(auth.uid())
    )
  );

CREATE POLICY "Admins can manage documents in their company"
  ON technician_documents FOR ALL
  USING (
    has_role(auth.uid(), 'admin'::app_role) 
    AND EXISTS (
      SELECT 1 FROM technicians 
      WHERE technicians.id = technician_documents.technician_id 
      AND technicians.company_id = user_company_id(auth.uid())
    )
  );

-- Create storage bucket for technician documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('technician-documents', 'technician-documents', false)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for storage
CREATE POLICY "Users can view documents in their company"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'technician-documents' 
    AND EXISTS (
      SELECT 1 FROM technicians 
      WHERE technicians.company_id = user_company_id(auth.uid())
      AND (storage.foldername(name))[2] = technicians.id::text
    )
  );

CREATE POLICY "Admins can upload documents in their company"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'technician-documents' 
    AND has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "Admins can delete documents in their company"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'technician-documents' 
    AND has_role(auth.uid(), 'admin'::app_role)
  );