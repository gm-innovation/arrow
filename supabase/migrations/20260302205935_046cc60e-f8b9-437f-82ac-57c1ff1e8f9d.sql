ALTER TABLE corp_badges ADD COLUMN IF NOT EXISTS xp_value integer DEFAULT 10;
ALTER TABLE corp_badges ADD COLUMN IF NOT EXISTS category text DEFAULT 'manual';