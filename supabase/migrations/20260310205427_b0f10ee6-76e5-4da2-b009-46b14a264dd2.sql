ALTER TABLE task_types
  ADD COLUMN is_recurrent boolean NOT NULL DEFAULT false,
  ADD COLUMN recurrence_type text,
  ADD COLUMN pricing_type text,
  ADD COLUMN default_periodicity integer,
  ADD COLUMN default_estimated_value numeric;