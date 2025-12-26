-- Create technician reservations table
CREATE TABLE public.technician_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  technician_id UUID NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  reserved_by UUID NOT NULL REFERENCES public.profiles(id),
  
  -- Período da reserva
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  
  -- Informações do serviço potencial
  client_id UUID REFERENCES public.clients(id),
  vessel_id UUID REFERENCES public.vessels(id),
  service_order_id UUID REFERENCES public.service_orders(id),
  
  -- Status e detalhes
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'released', 'converted', 'cancelled')),
  reason TEXT,
  includes_travel BOOLEAN DEFAULT false,
  includes_overnight BOOLEAN DEFAULT false,
  notes TEXT,
  
  -- Metadados
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.technician_reservations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Admins can manage reservations in their company
CREATE POLICY "Admins can manage reservations in their company"
ON public.technician_reservations
FOR ALL
USING (
  has_role(auth.uid(), 'admin') AND 
  company_id = user_company_id(auth.uid())
)
WITH CHECK (
  has_role(auth.uid(), 'admin') AND 
  company_id = user_company_id(auth.uid())
);

-- Managers can view reservations in their company
CREATE POLICY "Managers can view reservations in their company"
ON public.technician_reservations
FOR SELECT
USING (
  has_role(auth.uid(), 'manager') AND 
  company_id = user_company_id(auth.uid())
);

-- Technicians can view their own reservations
CREATE POLICY "Technicians can view their own reservations"
ON public.technician_reservations
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.technicians t 
    WHERE t.id = technician_reservations.technician_id 
    AND t.user_id = auth.uid()
  )
);

-- Create index for performance
CREATE INDEX idx_technician_reservations_technician_dates 
ON public.technician_reservations(technician_id, start_date, end_date);

CREATE INDEX idx_technician_reservations_company_status 
ON public.technician_reservations(company_id, status);

-- Create or replace function to check technician availability including reservations
CREATE OR REPLACE FUNCTION public.get_technician_availability_v2(
  _technician_id UUID,
  _check_date DATE
)
RETURNS TABLE (
  is_available BOOLEAN,
  status_type TEXT,
  status_description TEXT,
  blocked_by TEXT,
  reservation_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_absence RECORD;
  v_oncall RECORD;
  v_reservation RECORD;
BEGIN
  -- Check for absences first
  SELECT ta.*, p.full_name as technician_name
  INTO v_absence
  FROM technician_absences ta
  JOIN technicians t ON t.id = ta.technician_id
  LEFT JOIN profiles p ON p.id = t.user_id
  WHERE ta.technician_id = _technician_id
    AND ta.status != 'cancelled'
    AND _check_date BETWEEN ta.start_date AND ta.end_date
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT 
      false::BOOLEAN,
      v_absence.absence_type::TEXT,
      CASE v_absence.absence_type
        WHEN 'vacation' THEN 'Férias'
        WHEN 'sick_leave' THEN 'Atestado médico'
        WHEN 'personal' THEN 'Licença pessoal'
        WHEN 'training' THEN 'Em treinamento'
        ELSE 'Ausente'
      END,
      NULL::TEXT,
      NULL::UUID;
    RETURN;
  END IF;

  -- Check for active reservations
  SELECT tr.*, p.full_name as reserved_by_name
  INTO v_reservation
  FROM technician_reservations tr
  JOIN profiles p ON p.id = tr.reserved_by
  WHERE tr.technician_id = _technician_id
    AND tr.status IN ('pending', 'confirmed')
    AND _check_date BETWEEN tr.start_date AND tr.end_date
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT 
      false::BOOLEAN,
      'reserved'::TEXT,
      'Reservado por ' || v_reservation.reserved_by_name,
      v_reservation.reserved_by_name::TEXT,
      v_reservation.id;
    RETURN;
  END IF;

  -- Check for on-call
  SELECT toc.*
  INTO v_oncall
  FROM technician_on_call toc
  WHERE toc.technician_id = _technician_id
    AND toc.on_call_date = _check_date
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT 
      true::BOOLEAN,
      'on_call'::TEXT,
      'De sobreaviso',
      NULL::TEXT,
      NULL::UUID;
    RETURN;
  END IF;

  -- Available
  RETURN QUERY SELECT 
    true::BOOLEAN,
    'available'::TEXT,
    'Disponível',
    NULL::TEXT,
    NULL::UUID;
END;
$$;