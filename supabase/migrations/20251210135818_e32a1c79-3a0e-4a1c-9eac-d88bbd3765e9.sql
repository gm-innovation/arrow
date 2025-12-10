-- Corrigir cálculo do ISS para usar fórmula "por dentro"
-- ISS 2% → total = subtotal / 0.98
-- ISS 5% → total = subtotal / 0.95

CREATE OR REPLACE FUNCTION public.update_measurement_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
  -- Determine measurement_id based on trigger operation
  IF TG_OP = 'DELETE' THEN
    _measurement_id := OLD.measurement_id;
  ELSE
    _measurement_id := NEW.measurement_id;
  END IF;

  -- Get measurement category
  SELECT category INTO _measurement_category
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

  -- Get tax rate based on category from measurement_settings
  SELECT 
    CASE _measurement_category
      WHEN 'cativo' THEN COALESCE(ms.tax_cativo, 0)
      WHEN 'externo' THEN COALESCE(ms.tax_externo, 0)
      WHEN 'laboratorio' THEN COALESCE(ms.tax_laboratorio, 0)
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
$$;

-- Recalcular todas as medições em draft para aplicar a nova fórmula
DO $$
DECLARE
  _measurement RECORD;
BEGIN
  FOR _measurement IN 
    SELECT m.id 
    FROM measurements m 
    WHERE m.status = 'draft'
  LOOP
    -- Trigger recalculation by updating a man_hour entry (if exists)
    UPDATE measurement_man_hours 
    SET updated_at = NOW() 
    WHERE measurement_id = _measurement.id 
    AND id = (SELECT id FROM measurement_man_hours WHERE measurement_id = _measurement.id LIMIT 1);
    
    -- If no man_hours, try materials
    IF NOT FOUND THEN
      UPDATE measurement_materials 
      SET updated_at = NOW() 
      WHERE measurement_id = _measurement.id 
      AND id = (SELECT id FROM measurement_materials WHERE measurement_id = _measurement.id LIMIT 1);
    END IF;
    
    -- If no materials, try services
    IF NOT FOUND THEN
      UPDATE measurement_services 
      SET updated_at = NOW() 
      WHERE measurement_id = _measurement.id 
      AND id = (SELECT id FROM measurement_services WHERE measurement_id = _measurement.id LIMIT 1);
    END IF;
    
    -- If no services, try travels
    IF NOT FOUND THEN
      UPDATE measurement_travels 
      SET updated_at = NOW() 
      WHERE measurement_id = _measurement.id 
      AND id = (SELECT id FROM measurement_travels WHERE measurement_id = _measurement.id LIMIT 1);
    END IF;
    
    -- If no travels, try expenses
    IF NOT FOUND THEN
      UPDATE measurement_expenses 
      SET updated_at = NOW() 
      WHERE measurement_id = _measurement.id 
      AND id = (SELECT id FROM measurement_expenses WHERE measurement_id = _measurement.id LIMIT 1);
    END IF;
  END LOOP;
END;
$$;