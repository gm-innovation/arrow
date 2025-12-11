-- Adicionar novo valor ao ENUM measurement_category
ALTER TYPE measurement_category ADD VALUE IF NOT EXISTS 'ISENTO';

-- Adicionar coluna de taxa para ISENTO na tabela measurement_settings
ALTER TABLE measurement_settings ADD COLUMN IF NOT EXISTS tax_isento NUMERIC DEFAULT 0.00;

-- Atualizar a função recalculate_measurement para incluir ISENTO
CREATE OR REPLACE FUNCTION recalculate_measurement()
RETURNS TRIGGER AS $$
DECLARE
  _measurement_id UUID;
  _service_order_id UUID;
  _company_id UUID;
  _measurement_category measurement_category;
  _subtotal_man_hours NUMERIC := 0;
  _subtotal_materials NUMERIC := 0;
  _subtotal_services NUMERIC := 0;
  _subtotal_travels NUMERIC := 0;
  _subtotal_expenses NUMERIC := 0;
  _subtotal NUMERIC := 0;
  _tax_percentage NUMERIC := 0;
  _tax_amount NUMERIC := 0;
  _total_amount NUMERIC := 0;
BEGIN
  -- Determinar measurement_id baseado na tabela que disparou o trigger
  IF TG_TABLE_NAME = 'measurement_man_hours' THEN
    _measurement_id := COALESCE(NEW.measurement_id, OLD.measurement_id);
  ELSIF TG_TABLE_NAME = 'measurement_materials' THEN
    _measurement_id := COALESCE(NEW.measurement_id, OLD.measurement_id);
  ELSIF TG_TABLE_NAME = 'measurement_services' THEN
    _measurement_id := COALESCE(NEW.measurement_id, OLD.measurement_id);
  ELSIF TG_TABLE_NAME = 'measurement_travels' THEN
    _measurement_id := COALESCE(NEW.measurement_id, OLD.measurement_id);
  ELSIF TG_TABLE_NAME = 'measurement_expenses' THEN
    _measurement_id := COALESCE(NEW.measurement_id, OLD.measurement_id);
  ELSIF TG_TABLE_NAME = 'measurements' THEN
    _measurement_id := COALESCE(NEW.id, OLD.id);
  END IF;

  -- Buscar informações da medição
  SELECT m.service_order_id, m.category, so.company_id
  INTO _service_order_id, _measurement_category, _company_id
  FROM measurements m
  JOIN service_orders so ON m.service_order_id = so.id
  WHERE m.id = _measurement_id;

  -- Calcular subtotais
  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_man_hours
  FROM measurement_man_hours WHERE measurement_id = _measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_materials
  FROM measurement_materials WHERE measurement_id = _measurement_id;

  SELECT COALESCE(SUM(value), 0) INTO _subtotal_services
  FROM measurement_services WHERE measurement_id = _measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_travels
  FROM measurement_travels WHERE measurement_id = _measurement_id;

  SELECT COALESCE(SUM(total_value), 0) INTO _subtotal_expenses
  FROM measurement_expenses WHERE measurement_id = _measurement_id;

  -- Calcular subtotal geral
  _subtotal := _subtotal_man_hours + _subtotal_materials + _subtotal_services + _subtotal_travels + _subtotal_expenses;

  -- Buscar taxa de imposto baseada na categoria
  SELECT 
    CASE _measurement_category
      WHEN 'CATIVO' THEN COALESCE(ms.tax_cativo, 0)
      WHEN 'EXTERNO' THEN COALESCE(ms.tax_externo, 0)
      WHEN 'LABORATORIO' THEN COALESCE(ms.tax_laboratorio, 0)
      WHEN 'ISENTO' THEN COALESCE(ms.tax_isento, 0)
      ELSE 0
    END
  INTO _tax_percentage
  FROM measurement_settings ms
  WHERE ms.company_id = _company_id;

  -- Se não encontrou configurações, usar 0
  IF _tax_percentage IS NULL THEN
    _tax_percentage := 0;
  END IF;

  -- Calcular imposto (fórmula: subtotal / (1 - taxa/100) - subtotal)
  IF _tax_percentage > 0 THEN
    _total_amount := _subtotal / (1 - _tax_percentage / 100);
    _tax_amount := _total_amount - _subtotal;
  ELSE
    _total_amount := _subtotal;
    _tax_amount := 0;
  END IF;

  -- Atualizar a medição
  UPDATE measurements
  SET 
    subtotal_man_hours = _subtotal_man_hours,
    subtotal_materials = _subtotal_materials,
    subtotal_services = _subtotal_services,
    subtotal_travels = _subtotal_travels,
    subtotal_expenses = _subtotal_expenses,
    subtotal = _subtotal,
    tax_percentage = _tax_percentage,
    tax_amount = _tax_amount,
    total_amount = _total_amount,
    updated_at = NOW()
  WHERE id = _measurement_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;