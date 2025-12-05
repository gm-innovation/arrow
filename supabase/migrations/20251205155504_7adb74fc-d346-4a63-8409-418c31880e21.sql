
-- Create absence_type enum
DO $$ BEGIN
  CREATE TYPE public.absence_type AS ENUM (
    'vacation',
    'day_off', 
    'medical_exam',
    'training',
    'sick_leave',
    'other'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create absence_status enum
DO $$ BEGIN
  CREATE TYPE public.absence_status AS ENUM (
    'scheduled',
    'in_progress',
    'completed',
    'cancelled'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Table: technician_absences (vacations, days off, exams, training)
CREATE TABLE public.technician_absences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  technician_id uuid NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  absence_type public.absence_type NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  start_time time,
  end_time time,
  reason text,
  status public.absence_status DEFAULT 'scheduled',
  approved_by uuid REFERENCES public.profiles(id),
  approved_at timestamptz,
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Table: technician_on_call (standby schedules)
CREATE TABLE public.technician_on_call (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  technician_id uuid NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  on_call_date date NOT NULL,
  start_time time DEFAULT '00:00',
  end_time time DEFAULT '23:59',
  is_holiday boolean DEFAULT false,
  is_weekend boolean DEFAULT false,
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(technician_id, on_call_date)
);

-- Table: company_holidays
CREATE TABLE public.company_holidays (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  holiday_date date NOT NULL,
  name text NOT NULL,
  is_recurring boolean DEFAULT false,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, holiday_date)
);

-- Table: hr_time_adjustments (manual time corrections)
CREATE TABLE public.hr_time_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  technician_id uuid NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  adjustment_date date NOT NULL,
  original_check_in time,
  adjusted_check_in time,
  original_check_out time,
  adjusted_check_out time,
  adjustment_reason text NOT NULL,
  adjusted_by uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.technician_absences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_on_call ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hr_time_adjustments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for technician_absences
CREATE POLICY "HR can manage absences in their company"
ON public.technician_absences FOR ALL
USING (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()))
WITH CHECK (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()));

CREATE POLICY "Admins can view absences in their company"
ON public.technician_absences FOR SELECT
USING (has_role(auth.uid(), 'admin'::app_role) AND company_id = user_company_id(auth.uid()));

CREATE POLICY "Technicians can view their own absences"
ON public.technician_absences FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.technicians t 
  WHERE t.id = technician_absences.technician_id AND t.user_id = auth.uid()
));

CREATE POLICY "Managers can view absences in their company"
ON public.technician_absences FOR SELECT
USING (has_role(auth.uid(), 'manager'::app_role) AND company_id = user_company_id(auth.uid()));

-- RLS Policies for technician_on_call
CREATE POLICY "HR can manage on_call in their company"
ON public.technician_on_call FOR ALL
USING (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()))
WITH CHECK (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()));

CREATE POLICY "Admins can view on_call in their company"
ON public.technician_on_call FOR SELECT
USING (has_role(auth.uid(), 'admin'::app_role) AND company_id = user_company_id(auth.uid()));

CREATE POLICY "Technicians can view their own on_call"
ON public.technician_on_call FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.technicians t 
  WHERE t.id = technician_on_call.technician_id AND t.user_id = auth.uid()
));

CREATE POLICY "Managers can view on_call in their company"
ON public.technician_on_call FOR SELECT
USING (has_role(auth.uid(), 'manager'::app_role) AND company_id = user_company_id(auth.uid()));

-- RLS Policies for company_holidays
CREATE POLICY "HR can manage holidays in their company"
ON public.company_holidays FOR ALL
USING (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()))
WITH CHECK (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()));

CREATE POLICY "Users can view holidays in their company"
ON public.company_holidays FOR SELECT
USING (company_id = user_company_id(auth.uid()));

-- RLS Policies for hr_time_adjustments
CREATE POLICY "HR can manage time adjustments in their company"
ON public.hr_time_adjustments FOR ALL
USING (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()))
WITH CHECK (has_role(auth.uid(), 'hr'::app_role) AND company_id = user_company_id(auth.uid()));

CREATE POLICY "Admins can view time adjustments in their company"
ON public.hr_time_adjustments FOR SELECT
USING (has_role(auth.uid(), 'admin'::app_role) AND company_id = user_company_id(auth.uid()));

CREATE POLICY "Technicians can view their own time adjustments"
ON public.hr_time_adjustments FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.technicians t 
  WHERE t.id = hr_time_adjustments.technician_id AND t.user_id = auth.uid()
));

-- Function: Check if technician is available on a specific date
CREATE OR REPLACE FUNCTION public.is_technician_available(
  _technician_id uuid,
  _check_date date
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM technician_absences
    WHERE technician_id = _technician_id
    AND _check_date BETWEEN start_date AND end_date
    AND status IN ('scheduled', 'in_progress')
  );
$$;

-- Function: Get detailed technician availability status
CREATE OR REPLACE FUNCTION public.get_technician_availability(
  _technician_id uuid,
  _check_date date
)
RETURNS TABLE (
  is_available boolean,
  status_type text,
  status_description text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_absence RECORD;
  v_on_call RECORD;
BEGIN
  -- Check for absence
  SELECT * INTO v_absence
  FROM technician_absences
  WHERE technician_id = _technician_id
  AND _check_date BETWEEN start_date AND end_date
  AND status IN ('scheduled', 'in_progress')
  LIMIT 1;
  
  IF FOUND THEN
    RETURN QUERY SELECT 
      false,
      v_absence.absence_type::text,
      CASE v_absence.absence_type
        WHEN 'vacation' THEN 'Férias'
        WHEN 'day_off' THEN 'Folga'
        WHEN 'medical_exam' THEN 'Exame Médico'
        WHEN 'training' THEN 'Treinamento'
        WHEN 'sick_leave' THEN 'Atestado'
        ELSE 'Ausência'
      END;
    RETURN;
  END IF;
  
  -- Check for on-call
  SELECT * INTO v_on_call
  FROM technician_on_call
  WHERE technician_id = _technician_id
  AND on_call_date = _check_date
  LIMIT 1;
  
  IF FOUND THEN
    RETURN QUERY SELECT 
      true,
      'on_call'::text,
      'Sobreaviso';
    RETURN;
  END IF;
  
  -- Available
  RETURN QUERY SELECT 
    true,
    'available'::text,
    'Disponível';
END;
$$;

-- Trigger function: Notify technician on absence scheduled
CREATE OR REPLACE FUNCTION public.notify_technician_on_absence()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_absence_name TEXT;
BEGIN
  SELECT user_id INTO v_user_id FROM technicians WHERE id = NEW.technician_id;
  
  v_absence_name := CASE NEW.absence_type
    WHEN 'vacation' THEN 'Férias'
    WHEN 'day_off' THEN 'Folga'
    WHEN 'medical_exam' THEN 'Exame Médico'
    WHEN 'training' THEN 'Treinamento'
    WHEN 'sick_leave' THEN 'Atestado'
    ELSE 'Ausência'
  END;
  
  IF v_user_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id, title, message, notification_type, reference_id, read
    ) VALUES (
      v_user_id,
      v_absence_name || ' Agendada',
      v_absence_name || ' agendada de ' || to_char(NEW.start_date, 'DD/MM/YYYY') || ' a ' || to_char(NEW.end_date, 'DD/MM/YYYY'),
      'schedule_change',
      NEW.id,
      false
    );
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER notify_absence_scheduled
AFTER INSERT ON public.technician_absences
FOR EACH ROW
EXECUTE FUNCTION public.notify_technician_on_absence();

-- Trigger function: Notify technician on on-call assigned
CREATE OR REPLACE FUNCTION public.notify_technician_on_call_assigned()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT user_id INTO v_user_id FROM technicians WHERE id = NEW.technician_id;
  
  IF v_user_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id, title, message, notification_type, reference_id, read
    ) VALUES (
      v_user_id,
      'Sobreaviso Atribuído',
      'Você foi escalado para sobreaviso em ' || to_char(NEW.on_call_date, 'DD/MM/YYYY'),
      'task_assignment',
      NEW.id,
      false
    );
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER notify_on_call_assigned
AFTER INSERT ON public.technician_on_call
FOR EACH ROW
EXECUTE FUNCTION public.notify_technician_on_call_assigned();

-- Update triggers
CREATE TRIGGER update_technician_absences_updated_at
BEFORE UPDATE ON public.technician_absences
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_technician_on_call_updated_at
BEFORE UPDATE ON public.technician_on_call
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_company_holidays_updated_at
BEFORE UPDATE ON public.company_holidays
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
