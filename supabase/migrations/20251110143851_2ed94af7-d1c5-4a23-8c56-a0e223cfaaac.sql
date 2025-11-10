-- Add foreign key constraint between technicians and profiles
ALTER TABLE technicians
DROP CONSTRAINT IF EXISTS technicians_user_id_fkey;

ALTER TABLE technicians
ADD CONSTRAINT technicians_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES profiles(id) 
ON DELETE CASCADE;