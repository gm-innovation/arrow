
-- Add 'hr' to app_role enum (will be committed separately)
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'hr';
