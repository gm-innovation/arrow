-- =====================================================
-- FASE 1: SISTEMA DE MEDIÇÃO FINAL - BACKEND
-- =====================================================

-- ===== ENUMS =====
CREATE TYPE measurement_status AS ENUM ('draft', 'finalized');
CREATE TYPE measurement_category AS ENUM ('CATIVO', 'LABORATORIO', 'EXTERNO');
CREATE TYPE travel_type AS ENUM ('carro_proprio', 'carro_alugado', 'passagem_aerea');
CREATE TYPE expense_type AS ENUM ('hospedagem', 'alimentacao');
CREATE TYPE work_type AS ENUM ('trabalho', 'espera_deslocamento', 'laboratorio');
CREATE TYPE technician_role AS ENUM ('tecnico', 'auxiliar', 'engenheiro', 'supervisor');

-- ===== TABELA PRINCIPAL: MEASUREMENTS =====
CREATE TABLE public.measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  
  -- Campos básicos
  category measurement_category NOT NULL DEFAULT 'CATIVO',
  status measurement_status NOT NULL DEFAULT 'draft',
  
  -- Totais (calculados automaticamente por trigger)
  subtotal_man_hours DECIMAL(10,2) DEFAULT 0,
  subtotal_materials DECIMAL(10,2) DEFAULT 0,
  subtotal_services DECIMAL(10,2) DEFAULT 0,
  subtotal_travels DECIMAL(10,2) DEFAULT 0,
  subtotal_expenses DECIMAL(10,2) DEFAULT 0,
  subtotal DECIMAL(10,2) DEFAULT 0,
  tax_percentage DECIMAL(5,2) DEFAULT 2.00,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) DEFAULT 0,
  
  -- Auditoria
  created_by UUID REFERENCES auth.users(id),
  finalized_by UUID REFERENCES auth.users(id),
  finalized_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  -- Apenas uma medição por OS
  UNIQUE(service_order_id)
);

-- ===== TABELA DE DETALHAMENTO: MÃO DE OBRA =====
CREATE TABLE public.measurement_man_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  measurement_id UUID NOT NULL REFERENCES public.measurements(id) ON DELETE CASCADE,
  
  -- Dados da entrada de tempo
  entry_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  
  -- Tipo e categoria
  hour_type time_entry_type NOT NULL,
  work_type work_type NOT NULL,
  
  -- Técnico
  technician_id UUID REFERENCES public.technicians(id),
  technician_name TEXT NOT NULL,
  technician_role technician_role NOT NULL,
  
  -- Valores
  total_hours DECIMAL(5,2) NOT NULL,
  hourly_rate DECIMAL(10,2) NOT NULL,
  total_value DECIMAL(10,2) NOT NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ===== TABELA DE DETALHAMENTO: MATERIAIS =====
CREATE TABLE public.measurement_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  measurement_id UUID NOT NULL REFERENCES public.measurements(id) ON DELETE CASCADE,
  
  -- Dados do material (simplificado, sem catálogo)
  name TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  unit_value DECIMAL(10,2) NOT NULL,
  
  -- Markup
  markup_percentage DECIMAL(5,2) DEFAULT 0,
  total_value DECIMAL(10,2) NOT NULL,
  
  -- Para futura integração com estoque
  stock_item_id UUID,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ===== TABELA DE DETALHAMENTO: SERVIÇOS =====
CREATE TABLE public.measurement_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  measurement_id UUID NOT NULL REFERENCES public.measurements(id) ON DELETE CASCADE,
  
  -- Dados do serviço (simplificado)
  name TEXT NOT NULL,
  value DECIMAL(10,2) NOT NULL,
  description TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ===== TABELA DE DETALHAMENTO: DESLOCAMENTOS =====
CREATE TABLE public.measurement_travels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  measurement_id UUID NOT NULL REFERENCES public.measurements(id) ON DELETE CASCADE,
  
  -- Dados do deslocamento
  travel_type travel_type NOT NULL,
  from_city TEXT NOT NULL,
  to_city TEXT NOT NULL,
  
  -- Valores
  distance_km INTEGER,
  km_rate DECIMAL(10,2),
  fixed_value DECIMAL(10,2),
  total_value DECIMAL(10,2) NOT NULL,
  
  description TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ===== TABELA DE DETALHAMENTO: DESPESAS =====
CREATE TABLE public.measurement_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  measurement_id UUID NOT NULL REFERENCES public.measurements(id) ON DELETE CASCADE,
  
  -- Dados da despesa
  expense_type expense_type NOT NULL,
  base_value DECIMAL(10,2) NOT NULL,
  
  -- Taxa administrativa (padrão 20%)
  admin_fee_percentage DECIMAL(5,2) DEFAULT 20.00,
  admin_fee_amount DECIMAL(10,2) NOT NULL,
  total_value DECIMAL(10,2) NOT NULL,
  
  description TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ===== TABELA DE CONFIGURAÇÃO: TAXAS DE SERVIÇO =====
CREATE TABLE public.service_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  
  -- Tipo de profissional, hora e trabalho
  role_type technician_role NOT NULL,
  hour_type time_entry_type NOT NULL,
  work_type work_type NOT NULL,
  
  -- Valor da taxa
  rate_value DECIMAL(10,2) NOT NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  -- Apenas uma taxa por combinação
  UNIQUE(company_id, role_type, hour_type, work_type)
);

-- ===== TABELA DE CONFIGURAÇÃO: DISTÂNCIAS ENTRE CIDADES =====
CREATE TABLE public.city_distances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  
  from_city TEXT NOT NULL,
  to_city TEXT NOT NULL,
  distance_km INTEGER NOT NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  -- Garantir que não haja duplicatas (A->B e B->A são a mesma rota)
  UNIQUE(company_id, from_city, to_city)
);

-- ===== TABELA DE CONFIGURAÇÃO: CONFIGURAÇÕES GERAIS =====
CREATE TABLE public.measurement_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  
  -- Configurações
  km_rate DECIMAL(10,2) DEFAULT 2.50,
  default_material_markup DECIMAL(5,2) DEFAULT 30.00,
  expense_admin_fee DECIMAL(5,2) DEFAULT 20.00,
  
  -- Impostos por categoria
  tax_cativo DECIMAL(5,2) DEFAULT 2.00,
  tax_laboratorio DECIMAL(5,2) DEFAULT 5.00,
  tax_externo DECIMAL(5,2) DEFAULT 2.00,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  -- Apenas uma configuração por empresa
  UNIQUE(company_id)
);

-- ===== FUNÇÃO: CALCULAR VALOR DE HORA =====
CREATE OR REPLACE FUNCTION public.calculate_man_hour_value(
  _company_id UUID,
  _role_type technician_role,
  _hour_type time_entry_type,
  _work_type work_type,
  _total_hours DECIMAL
)
RETURNS DECIMAL
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _rate_value DECIMAL;
  _total_value DECIMAL;
BEGIN
  -- Buscar taxa configurada
  SELECT rate_value INTO _rate_value
  FROM service_rates
  WHERE company_id = _company_id
    AND role_type = _role_type
    AND hour_type = _hour_type
    AND work_type = _work_type;
  
  -- Se não encontrar taxa, retornar 0
  IF _rate_value IS NULL THEN
    RETURN 0;
  END IF;
  
  -- Calcular total
  _total_value := _rate_value * _total_hours;
  
  RETURN _total_value;
END;
$$;

-- ===== FUNÇÃO: BUSCAR DISTÂNCIA ENTRE CIDADES =====
CREATE OR REPLACE FUNCTION public.get_city_distance(
  _company_id UUID,
  _from_city TEXT,
  _to_city TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _distance INTEGER;
BEGIN
  -- Buscar distância (A->B ou B->A)
  SELECT distance_km INTO _distance
  FROM city_distances
  WHERE company_id = _company_id
    AND (
      (from_city = _from_city AND to_city = _to_city) OR
      (from_city = _to_city AND to_city = _from_city)
    );
  
  RETURN _distance;
END;
$$;

-- ===== TRIGGER: ATUALIZAR TOTAIS DA MEDIÇÃO =====
CREATE OR REPLACE FUNCTION public.update_measurement_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _measurement_id UUID;
  _category measurement_category;
  _tax_rate DECIMAL;
  _subtotal_man_hours DECIMAL := 0;
  _subtotal_materials DECIMAL := 0;
  _subtotal_services DECIMAL := 0;
  _subtotal_travels DECIMAL := 0;
  _subtotal_expenses DECIMAL := 0;
  _subtotal DECIMAL := 0;
  _tax_amount DECIMAL := 0;
  _total_amount DECIMAL := 0;
BEGIN
  -- Determinar measurement_id baseado na tabela de origem
  IF TG_TABLE_NAME = 'measurements' THEN
    _measurement_id := NEW.id;
  ELSE
    _measurement_id := NEW.measurement_id;
  END IF;
  
  -- Buscar categoria para definir taxa de imposto
  SELECT category INTO _category
  FROM measurements
  WHERE id = _measurement_id;
  
  -- Definir taxa de imposto baseada na categoria
  CASE _category
    WHEN 'CATIVO' THEN _tax_rate := 2.00;
    WHEN 'LABORATORIO' THEN _tax_rate := 5.00;
    WHEN 'EXTERNO' THEN _tax_rate := 2.00;
  END CASE;
  
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
  
  -- Calcular imposto
  _tax_amount := _subtotal * (_tax_rate / 100);
  
  -- Calcular total final
  _total_amount := _subtotal + _tax_amount;
  
  -- Atualizar medição
  UPDATE measurements SET
    subtotal_man_hours = _subtotal_man_hours,
    subtotal_materials = _subtotal_materials,
    subtotal_services = _subtotal_services,
    subtotal_travels = _subtotal_travels,
    subtotal_expenses = _subtotal_expenses,
    subtotal = _subtotal,
    tax_percentage = _tax_rate,
    tax_amount = _tax_amount,
    total_amount = _total_amount,
    updated_at = now()
  WHERE id = _measurement_id;
  
  RETURN NEW;
END;
$$;

-- Aplicar trigger em todas as tabelas de detalhamento
CREATE TRIGGER trigger_update_measurement_totals_man_hours
AFTER INSERT OR UPDATE OR DELETE ON measurement_man_hours
FOR EACH ROW EXECUTE FUNCTION update_measurement_totals();

CREATE TRIGGER trigger_update_measurement_totals_materials
AFTER INSERT OR UPDATE OR DELETE ON measurement_materials
FOR EACH ROW EXECUTE FUNCTION update_measurement_totals();

CREATE TRIGGER trigger_update_measurement_totals_services
AFTER INSERT OR UPDATE OR DELETE ON measurement_services
FOR EACH ROW EXECUTE FUNCTION update_measurement_totals();

CREATE TRIGGER trigger_update_measurement_totals_travels
AFTER INSERT OR UPDATE OR DELETE ON measurement_travels
FOR EACH ROW EXECUTE FUNCTION update_measurement_totals();

CREATE TRIGGER trigger_update_measurement_totals_expenses
AFTER INSERT OR UPDATE OR DELETE ON measurement_expenses
FOR EACH ROW EXECUTE FUNCTION update_measurement_totals();

CREATE TRIGGER trigger_update_measurement_totals_category
AFTER UPDATE OF category ON measurements
FOR EACH ROW EXECUTE FUNCTION update_measurement_totals();

-- ===== TRIGGER: REGISTRAR MUDANÇAS NO HISTÓRICO =====
CREATE OR REPLACE FUNCTION public.log_measurement_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  performer_name TEXT;
  _service_order_id UUID;
BEGIN
  SELECT full_name INTO performer_name FROM profiles WHERE id = auth.uid();
  
  IF TG_OP = 'INSERT' THEN
    _service_order_id := NEW.service_order_id;
    
    INSERT INTO service_history (
      service_order_id,
      action,
      change_type,
      description,
      new_values,
      performed_by
    ) VALUES (
      _service_order_id,
      'measurement_created',
      'create',
      'Medição Final criada por ' || COALESCE(performer_name, 'Sistema'),
      jsonb_build_object(
        'measurement_id', NEW.id,
        'category', NEW.category,
        'status', NEW.status
      ),
      auth.uid()
    );
    
  ELSIF TG_OP = 'UPDATE' THEN
    _service_order_id := NEW.service_order_id;
    
    -- Registrar finalização
    IF OLD.status = 'draft' AND NEW.status = 'finalized' THEN
      INSERT INTO service_history (
        service_order_id,
        action,
        change_type,
        description,
        new_values,
        performed_by
      ) VALUES (
        _service_order_id,
        'measurement_finalized',
        'update',
        'Medição Final finalizada por ' || COALESCE(performer_name, 'Sistema') || ' - Valor total: R$ ' || NEW.total_amount,
        jsonb_build_object(
          'measurement_id', NEW.id,
          'total_amount', NEW.total_amount,
          'finalized_at', NEW.finalized_at
        ),
        auth.uid()
      );
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_log_measurement_changes
AFTER INSERT OR UPDATE ON measurements
FOR EACH ROW EXECUTE FUNCTION log_measurement_changes();

-- ===== TRIGGER: UPDATED_AT =====
CREATE TRIGGER update_measurements_updated_at
BEFORE UPDATE ON measurements
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_measurement_man_hours_updated_at
BEFORE UPDATE ON measurement_man_hours
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_measurement_materials_updated_at
BEFORE UPDATE ON measurement_materials
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_measurement_services_updated_at
BEFORE UPDATE ON measurement_services
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_measurement_travels_updated_at
BEFORE UPDATE ON measurement_travels
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_measurement_expenses_updated_at
BEFORE UPDATE ON measurement_expenses
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_service_rates_updated_at
BEFORE UPDATE ON service_rates
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_city_distances_updated_at
BEFORE UPDATE ON city_distances
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_measurement_settings_updated_at
BEFORE UPDATE ON measurement_settings
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ===== ÍNDICES =====
CREATE INDEX idx_measurements_service_order_id ON measurements(service_order_id);
CREATE INDEX idx_measurements_status ON measurements(status);
CREATE INDEX idx_measurements_created_by ON measurements(created_by);

CREATE INDEX idx_measurement_man_hours_measurement_id ON measurement_man_hours(measurement_id);
CREATE INDEX idx_measurement_materials_measurement_id ON measurement_materials(measurement_id);
CREATE INDEX idx_measurement_services_measurement_id ON measurement_services(measurement_id);
CREATE INDEX idx_measurement_travels_measurement_id ON measurement_travels(measurement_id);
CREATE INDEX idx_measurement_expenses_measurement_id ON measurement_expenses(measurement_id);

CREATE INDEX idx_service_rates_company_id ON service_rates(company_id);
CREATE INDEX idx_city_distances_company_id ON city_distances(company_id);
CREATE INDEX idx_measurement_settings_company_id ON measurement_settings(company_id);

-- ===== RLS POLICIES =====

-- MEASUREMENTS
ALTER TABLE measurements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Coordinators can manage their measurements"
ON measurements FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM service_orders
    WHERE service_orders.id = measurements.service_order_id
      AND service_orders.created_by = auth.uid()
      AND has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "Admins can view company measurements"
ON measurements FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  EXISTS (
    SELECT 1 FROM service_orders
    WHERE service_orders.id = measurements.service_order_id
      AND service_orders.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Super admins can manage all measurements"
ON measurements FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- MEASUREMENT DETAIL TABLES (mesmas policies para todas)
ALTER TABLE measurement_man_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_travels ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Coordinators can manage their measurement details"
ON measurement_man_hours FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.created_by = auth.uid()
      AND has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "Coordinators can manage their measurement details"
ON measurement_materials FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_materials.measurement_id
      AND so.created_by = auth.uid()
      AND has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "Coordinators can manage their measurement details"
ON measurement_services FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_services.measurement_id
      AND so.created_by = auth.uid()
      AND has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "Coordinators can manage their measurement details"
ON measurement_travels FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_travels.measurement_id
      AND so.created_by = auth.uid()
      AND has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "Coordinators can manage their measurement details"
ON measurement_expenses FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.created_by = auth.uid()
      AND has_role(auth.uid(), 'admin'::app_role)
  )
);

CREATE POLICY "Admins can view company measurement details"
ON measurement_man_hours FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_man_hours.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Admins can view company measurement details"
ON measurement_materials FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_materials.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Admins can view company measurement details"
ON measurement_services FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_services.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Admins can view company measurement details"
ON measurement_travels FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_travels.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Admins can view company measurement details"
ON measurement_expenses FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  EXISTS (
    SELECT 1 FROM measurements m
    JOIN service_orders so ON m.service_order_id = so.id
    WHERE m.id = measurement_expenses.measurement_id
      AND so.company_id = user_company_id(auth.uid())
  )
);

CREATE POLICY "Super admins can manage all measurement details"
ON measurement_man_hours FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "Super admins can manage all measurement details"
ON measurement_materials FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "Super admins can manage all measurement details"
ON measurement_services FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "Super admins can manage all measurement details"
ON measurement_travels FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "Super admins can manage all measurement details"
ON measurement_expenses FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- SERVICE_RATES
ALTER TABLE service_rates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage service rates in their company"
ON service_rates FOR ALL
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  company_id = user_company_id(auth.uid())
);

CREATE POLICY "Users can view service rates in their company"
ON service_rates FOR SELECT
USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "Super admins can manage all service rates"
ON service_rates FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- CITY_DISTANCES
ALTER TABLE city_distances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage city distances in their company"
ON city_distances FOR ALL
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  company_id = user_company_id(auth.uid())
);

CREATE POLICY "Users can view city distances in their company"
ON city_distances FOR SELECT
USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "Super admins can manage all city distances"
ON city_distances FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));

-- MEASUREMENT_SETTINGS
ALTER TABLE measurement_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage measurement settings in their company"
ON measurement_settings FOR ALL
USING (
  has_role(auth.uid(), 'admin'::app_role) AND
  company_id = user_company_id(auth.uid())
);

CREATE POLICY "Users can view measurement settings in their company"
ON measurement_settings FOR SELECT
USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "Super admins can manage all measurement settings"
ON measurement_settings FOR ALL
USING (has_role(auth.uid(), 'super_admin'::app_role));