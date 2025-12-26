-- Add UNIQUE constraint to push_subscriptions.user_id for upsert to work
ALTER TABLE push_subscriptions 
ADD CONSTRAINT push_subscriptions_user_id_key UNIQUE (user_id);