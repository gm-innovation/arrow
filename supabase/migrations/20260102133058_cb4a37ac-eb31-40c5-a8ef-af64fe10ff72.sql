-- Ajustar FKs que apontam para profiles para permitir exclusão de usuários

-- 1. service_orders.created_by - tornar nullable e adicionar ON DELETE SET NULL
ALTER TABLE public.service_orders ALTER COLUMN created_by DROP NOT NULL;

ALTER TABLE public.service_orders 
DROP CONSTRAINT IF EXISTS service_orders_created_by_fkey;

ALTER TABLE public.service_orders
ADD CONSTRAINT service_orders_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 2. service_visits.created_by - já é nullable, apenas ajustar FK
ALTER TABLE public.service_visits 
DROP CONSTRAINT IF EXISTS service_visits_created_by_fkey;

ALTER TABLE public.service_visits
ADD CONSTRAINT service_visits_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 3. service_visits.scheduled_by - já é nullable, ajustar FK
ALTER TABLE public.service_visits 
DROP CONSTRAINT IF EXISTS service_visits_scheduled_by_fkey;

ALTER TABLE public.service_visits
ADD CONSTRAINT service_visits_scheduled_by_fkey 
FOREIGN KEY (scheduled_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 4. technician_reservations.reserved_by - tornar nullable e adicionar ON DELETE SET NULL
ALTER TABLE public.technician_reservations ALTER COLUMN reserved_by DROP NOT NULL;

ALTER TABLE public.technician_reservations 
DROP CONSTRAINT IF EXISTS technician_reservations_reserved_by_fkey;

ALTER TABLE public.technician_reservations
ADD CONSTRAINT technician_reservations_reserved_by_fkey 
FOREIGN KEY (reserved_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 5. visit_technicians.assigned_by - já é nullable, ajustar FK
ALTER TABLE public.visit_technicians 
DROP CONSTRAINT IF EXISTS visit_technicians_assigned_by_fkey;

ALTER TABLE public.visit_technicians
ADD CONSTRAINT visit_technicians_assigned_by_fkey 
FOREIGN KEY (assigned_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 6. service_orders.coordinator_id - ajustar FK
ALTER TABLE public.service_orders 
DROP CONSTRAINT IF EXISTS service_orders_coordinator_id_fkey;

ALTER TABLE public.service_orders
ADD CONSTRAINT service_orders_coordinator_id_fkey 
FOREIGN KEY (coordinator_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 7. service_orders.supervisor_id - ajustar FK
ALTER TABLE public.service_orders 
DROP CONSTRAINT IF EXISTS service_orders_supervisor_id_fkey;

ALTER TABLE public.service_orders
ADD CONSTRAINT service_orders_supervisor_id_fkey 
FOREIGN KEY (supervisor_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 8. company_holidays.created_by - ajustar FK
ALTER TABLE public.company_holidays 
DROP CONSTRAINT IF EXISTS company_holidays_created_by_fkey;

ALTER TABLE public.company_holidays
ADD CONSTRAINT company_holidays_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 9. technician_on_call.created_by - ajustar FK
ALTER TABLE public.technician_on_call 
DROP CONSTRAINT IF EXISTS technician_on_call_created_by_fkey;

ALTER TABLE public.technician_on_call
ADD CONSTRAINT technician_on_call_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 10. technician_absences.created_by - ajustar FK
ALTER TABLE public.technician_absences 
DROP CONSTRAINT IF EXISTS technician_absences_created_by_fkey;

ALTER TABLE public.technician_absences
ADD CONSTRAINT technician_absences_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 11. hr_time_adjustments.adjusted_by - ajustar FK
ALTER TABLE public.hr_time_adjustments 
DROP CONSTRAINT IF EXISTS hr_time_adjustments_adjusted_by_fkey;

ALTER TABLE public.hr_time_adjustments
ADD CONSTRAINT hr_time_adjustments_adjusted_by_fkey 
FOREIGN KEY (adjusted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 12. forecast_history.created_by - ajustar FK
ALTER TABLE public.forecast_history 
DROP CONSTRAINT IF EXISTS forecast_history_created_by_fkey;

ALTER TABLE public.forecast_history
ADD CONSTRAINT forecast_history_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 13. forecast_history.coordinator_id - ajustar FK
ALTER TABLE public.forecast_history 
DROP CONSTRAINT IF EXISTS forecast_history_coordinator_id_fkey;

ALTER TABLE public.forecast_history
ADD CONSTRAINT forecast_history_coordinator_id_fkey 
FOREIGN KEY (coordinator_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 14. service_history.performed_by - ajustar FK
ALTER TABLE public.service_history 
DROP CONSTRAINT IF EXISTS service_history_performed_by_fkey;

ALTER TABLE public.service_history
ADD CONSTRAINT service_history_performed_by_fkey 
FOREIGN KEY (performed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 15. task_reports.approved_by - ajustar FK
ALTER TABLE public.task_reports 
DROP CONSTRAINT IF EXISTS task_reports_approved_by_fkey;

ALTER TABLE public.task_reports
ADD CONSTRAINT task_reports_approved_by_fkey 
FOREIGN KEY (approved_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 16. measurements.created_by - ajustar FK
ALTER TABLE public.measurements 
DROP CONSTRAINT IF EXISTS measurements_created_by_fkey;

ALTER TABLE public.measurements
ADD CONSTRAINT measurements_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 17. measurements.finalized_by - ajustar FK
ALTER TABLE public.measurements 
DROP CONSTRAINT IF EXISTS measurements_finalized_by_fkey;

ALTER TABLE public.measurements
ADD CONSTRAINT measurements_finalized_by_fkey 
FOREIGN KEY (finalized_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 18. conversations.created_by - ajustar FK
ALTER TABLE public.conversations 
DROP CONSTRAINT IF EXISTS conversations_created_by_fkey;

ALTER TABLE public.conversations
ADD CONSTRAINT conversations_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;