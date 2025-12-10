
-- Corrigir função update_measurement_totals para:
-- 1. Lidar com trigger na tabela measurements (usando NEW.id quando não há measurement_id)
-- 2. Usar comparação case-insensitive para categoria

CREATE OR REPLACE FUNCTION public.update_measurement_totals()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  _subtotal_man_hours NUMERIC := 0;
  _subtotal_materials NUMERIC := 0;
  _subtotal_services NUMERIC := 0;
  _subtotal_travels NUMERIC := 0;
  _subtotal_expenses NUMERIC := 0;
  _subtotal NUMERIC := 0;
  _tax_rate NUMERIC := 0;
  _tax_amount NUMERIC := 0;
  _total_amount NUMERIC := 0;
  _measurement_id UUID;
  _measurement_category TEXT;
BEGIN
  -- Determine measurement_id based on trigger source
  -- If trigger is on measurements table, use id; otherwise use measurement_id
  IF TG_TABLE_NAME = 'measurements' THEN
    IF TG_OP = 'DELETE' THEN
      _measurement_id := OLD.id;
    ELSE
      _measurement_id := NEW.id;
    END IF;
  ELSE
    IF TG_OP = 'DELETE' THEN
      _measurement_id := OLD.measurement_id;
    ELSE
      _measurement_id := NEW.measurement_id;
    END IF;
  END IF;

  -- Get measurement category (use UPPER for consistent comparison)
  SELECT UPPER(category) INTO _measurement_category
  FROM measurements
  WHERE id = _measurement_id;

  -- Calculate subtotals from each related table
  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_man_hours
  FROM measurement_man_hours
  WHERE measurement_id = _measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_materials
  FROM measurement_materials
  WHERE measurement_id = _measurement_id;

  SELECT COALESCE(SUM(value), 0) INTO _subtotal_services
  FROM measurement_services
  WHERE measurement_id = _measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_travels
  FROM measurement_travels
  WHERE measurement_id = _measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_expenses
  FROM measurement_expenses
  WHERE measurement_id = _measurement_id;

  -- Calculate total subtotal
  _subtotal := _subtotal_man_hours + _subtotal_materials + _subtotal_services + _subtotal_travels + _subtotal_expenses;

  -- Get tax rate based on category from measurement_settings (using UPPER for comparison)
  SELECT 
    CASE _measurement_category
      WHEN 'CATIVO' THEN COALESCE(ms.tax_cativo, 0)
      WHEN 'EXTERNO' THEN COALESCE(ms.tax_externo, 0)
      WHEN 'LABORATORIO' THEN COALESCE(ms.tax_laboratorio, 0)
      ELSE 0
    END INTO _tax_rate
  FROM measurements m
  JOIN service_orders so ON m.service_order_id = so.id
  LEFT JOIN measurement_settings ms ON ms.company_id = so.company_id
  WHERE m.id = _measurement_id;

  -- Handle null tax rate
  IF _tax_rate IS NULL THEN
    _tax_rate := 0;
  END IF;

  -- Calcular ISS "por dentro":
  -- Para ISS 2%: total = subtotal / 0.98
  -- Para ISS 5%: total = subtotal / 0.95
  -- Fórmula geral: total = subtotal / (1 - tax_rate/100)
  IF _tax_rate > 0 AND _subtotal > 0 THEN
    _total_amount := _subtotal / (1 - (_tax_rate / 100));
    _tax_amount := _total_amount - _subtotal;
  ELSE
    _total_amount := _subtotal;
    _tax_amount := 0;
  END IF;

  -- Update the measurement record
  UPDATE measurements
  SET
    subtotal_man_hours = _subtotal_man_hours,
    subtotal_materials = _subtotal_materials,
    subtotal_services = _subtotal_services,
    subtotal_travels = _subtotal_travels,
    subtotal_expenses = _subtotal_expenses,
    subtotal = _subtotal,
    tax_percentage = _tax_rate,
    tax_amount = ROUND(_tax_amount, 2),
    total_amount = ROUND(_total_amount, 2),
    updated_at = NOW()
  WHERE id = _measurement_id;

  RETURN NEW;
END;
$function$;

-- Recalcular todas as medições existentes em draft
DO $$
DECLARE
  m_record RECORD;
BEGIN
  FOR m_record IN 
    SELECT id FROM measurements WHERE status = 'draft'
  LOOP
    -- Forçar recálculo atualizando o updated_at
    UPDATE measurements 
    SET updated_at = NOW() 
    WHERE id = m_record.id;
  END LOOP;
END $$;
