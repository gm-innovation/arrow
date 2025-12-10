
-- Corrigir função recalculate_measurement com cast para text
CREATE OR REPLACE FUNCTION public.recalculate_measurement(p_measurement_id UUID)
RETURNS void
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
  _measurement_category TEXT;
BEGIN
  -- Get measurement category (cast enum to text, then upper)
  SELECT UPPER(category::text) INTO _measurement_category
  FROM measurements
  WHERE id = p_measurement_id;

  -- Calculate subtotals
  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_man_hours
  FROM measurement_man_hours WHERE measurement_id = p_measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_materials
  FROM measurement_materials WHERE measurement_id = p_measurement_id;

  SELECT COALESCE(SUM(value), 0) INTO _subtotal_services
  FROM measurement_services WHERE measurement_id = p_measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_travels
  FROM measurement_travels WHERE measurement_id = p_measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_expenses
  FROM measurement_expenses WHERE measurement_id = p_measurement_id;

  _subtotal := _subtotal_man_hours + _subtotal_materials + _subtotal_services + _subtotal_travels + _subtotal_expenses;

  -- Get tax rate
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
  WHERE m.id = p_measurement_id;

  IF _tax_rate IS NULL THEN _tax_rate := 0; END IF;

  -- ISS "por dentro"
  IF _tax_rate > 0 AND _subtotal > 0 THEN
    _total_amount := _subtotal / (1 - (_tax_rate / 100));
    _tax_amount := _total_amount - _subtotal;
  ELSE
    _total_amount := _subtotal;
    _tax_amount := 0;
  END IF;

  -- Update
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
    total_amount = ROUND(_total_amount, 2)
  WHERE id = p_measurement_id;
END;
$function$;

-- Também corrigir update_measurement_totals
CREATE OR REPLACE FUNCTION public.update_measurement_totals()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  _measurement_id UUID;
BEGIN
  -- Evitar recursão
  IF pg_trigger_depth() > 1 THEN
    RETURN NEW;
  END IF;

  -- Determine measurement_id
  IF TG_TABLE_NAME = 'measurements' THEN
    _measurement_id := COALESCE(NEW.id, OLD.id);
  ELSE
    _measurement_id := COALESCE(NEW.measurement_id, OLD.measurement_id);
  END IF;

  -- Chamar função de recálculo
  PERFORM recalculate_measurement(_measurement_id);

  RETURN NEW;
END;
$function$;
