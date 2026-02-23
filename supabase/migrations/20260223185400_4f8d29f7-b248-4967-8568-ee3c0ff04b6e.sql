
-- Migração 1: Adicionar novos valores aos enums
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'director';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'request_created';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'request_approved';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'request_rejected';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'document_received';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'approval_pending';
