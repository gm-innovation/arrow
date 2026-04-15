
-- Add personal data columns to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS cpf text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS rg text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birth_date date;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS gender text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS nationality text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS height integer;

-- Add status column for employee lifecycle management
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active';

-- Create index for status filtering
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);
