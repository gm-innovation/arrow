-- Add marketing role if missing
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'marketing';