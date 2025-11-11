-- Add columns for tools, steps, and photo labels to task_types table
ALTER TABLE task_types 
ADD COLUMN tools text[] DEFAULT '{}',
ADD COLUMN steps text[] DEFAULT '{}', 
ADD COLUMN photo_labels text[] DEFAULT '{}';