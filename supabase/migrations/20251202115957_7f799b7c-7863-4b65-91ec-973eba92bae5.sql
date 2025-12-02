-- Add manager role to app_role enum
-- This must be in a separate migration from policies that use it
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'manager';