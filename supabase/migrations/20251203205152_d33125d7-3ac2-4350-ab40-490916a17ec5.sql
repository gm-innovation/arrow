-- FASE 1: Estrutura do Banco de Dados para Integração AIS

-- 1.1 Criar tabela de pontos de acesso recorrentes
CREATE TABLE IF NOT EXISTS public.access_points (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  location TEXT,
  latitude DECIMAL(10, 7),
  longitude DECIMAL(10, 7),
  instructions TEXT,
  point_type TEXT DEFAULT 'port', -- 'port', 'shipyard', 'marina', 'heliport', 'other'
  is_mainland BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS para access_points
ALTER TABLE public.access_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view access points in their company"
ON public.access_points FOR SELECT
USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "Admins can manage access points in their company"
ON public.access_points FOR ALL
USING (has_role(auth.uid(), 'admin') AND company_id = user_company_id(auth.uid()));

-- 1.2 Adicionar campos AIS na tabela vessels
ALTER TABLE public.vessels 
  ADD COLUMN IF NOT EXISTS mmsi VARCHAR(9),
  ADD COLUMN IF NOT EXISTS call_sign VARCHAR(20),
  ADD COLUMN IF NOT EXISTS ship_type INTEGER,
  ADD COLUMN IF NOT EXISTS gross_tonnage INTEGER,
  ADD COLUMN IF NOT EXISTS length_overall DECIMAL(6, 2),
  ADD COLUMN IF NOT EXISTS beam DECIMAL(6, 2),
  ADD COLUMN IF NOT EXISTS ais_source TEXT DEFAULT 'manual';

-- Índice para busca por MMSI
CREATE UNIQUE INDEX IF NOT EXISTS idx_vessels_mmsi ON public.vessels(mmsi) WHERE mmsi IS NOT NULL;

-- 1.3 Criar tabela de posições AIS dos navios
CREATE TABLE IF NOT EXISTS public.vessel_positions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vessel_id UUID NOT NULL REFERENCES vessels(id) ON DELETE CASCADE,
  latitude DECIMAL(10, 7) NOT NULL,
  longitude DECIMAL(10, 7) NOT NULL,
  speed_over_ground DECIMAL(5, 1),
  course_over_ground DECIMAL(5, 1),
  heading DECIMAL(5, 1),
  navigation_status INTEGER, -- 0=underway, 1=at_anchor, 5=moored
  destination TEXT,
  eta TIMESTAMP WITH TIME ZONE,
  location_context TEXT DEFAULT 'unknown', -- 'port', 'bay', 'offshore', 'at_sea'
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índice para buscar posições recentes
CREATE INDEX IF NOT EXISTS idx_vessel_positions_recent ON public.vessel_positions(vessel_id, recorded_at DESC);

-- RLS para vessel_positions
ALTER TABLE public.vessel_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view vessel positions in their company"
ON public.vessel_positions FOR SELECT
USING (EXISTS (
  SELECT 1 FROM vessels v
  JOIN clients c ON c.id = v.client_id
  WHERE v.id = vessel_positions.vessel_id
  AND c.company_id = user_company_id(auth.uid())
));

CREATE POLICY "System can insert vessel positions"
ON public.vessel_positions FOR INSERT
WITH CHECK (true);

-- 1.4 Adicionar campos de planejamento na service_orders
ALTER TABLE public.service_orders
  ADD COLUMN IF NOT EXISTS planned_location TEXT,
  ADD COLUMN IF NOT EXISTS access_point_id UUID REFERENCES access_points(id),
  ADD COLUMN IF NOT EXISTS access_instructions TEXT,
  ADD COLUMN IF NOT EXISTS expected_context TEXT DEFAULT 'docked', -- 'docked', 'anchored', 'offshore', 'at_sea'
  ADD COLUMN IF NOT EXISTS boarding_method TEXT DEFAULT 'gangway'; -- 'gangway', 'launch', 'helicopter', 'other'

-- 1.5 Adicionar campos de contexto AIS na technician_locations
ALTER TABLE public.technician_locations
  ADD COLUMN IF NOT EXISTS visit_id UUID REFERENCES service_visits(id),
  ADD COLUMN IF NOT EXISTS vessel_position_snapshot JSONB,
  ADD COLUMN IF NOT EXISTS vessel_distance_meters DECIMAL,
  ADD COLUMN IF NOT EXISTS location_matches_planned BOOLEAN,
  ADD COLUMN IF NOT EXISTS check_in_forced BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS force_reason TEXT;

-- Trigger para updated_at em access_points
CREATE TRIGGER update_access_points_updated_at
  BEFORE UPDATE ON public.access_points
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Função para limpar posições antigas (manter últimas 24h)
CREATE OR REPLACE FUNCTION public.cleanup_old_vessel_positions()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM vessel_positions
  WHERE recorded_at < now() - INTERVAL '24 hours';
END;
$$;