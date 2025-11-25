-- Add missing notification types to the enum
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'schedule_change';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'service_order';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'payment_overdue';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'new_company';