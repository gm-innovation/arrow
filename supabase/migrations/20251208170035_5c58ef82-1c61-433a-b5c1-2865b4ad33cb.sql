-- Função para criar time_entry automaticamente a partir de check-out
CREATE OR REPLACE FUNCTION public.create_time_entry_from_checkout()
RETURNS TRIGGER AS $$
DECLARE
  v_check_in_record RECORD;
  v_task_record RECORD;
BEGIN
  -- Só processa check_outs com task_id
  IF NEW.location_type = 'check_out' AND NEW.task_id IS NOT NULL THEN
    -- Busca o último check_in para a mesma task e técnico no mesmo dia
    SELECT * INTO v_check_in_record
    FROM technician_locations
    WHERE technician_id = NEW.technician_id
      AND task_id = NEW.task_id
      AND location_type = 'check_in'
      AND DATE(recorded_at) = DATE(NEW.recorded_at)
    ORDER BY recorded_at DESC
    LIMIT 1;
    
    IF FOUND THEN
      -- Verifica se já existe um time_entry para este par check-in/check-out
      IF NOT EXISTS (
        SELECT 1 FROM time_entries
        WHERE task_id = NEW.task_id
          AND technician_id = NEW.technician_id
          AND entry_date = DATE(NEW.recorded_at)
          AND start_time = v_check_in_record.recorded_at::time
      ) THEN
        -- Cria o time_entry automaticamente
        INSERT INTO time_entries (
          task_id,
          technician_id,
          entry_type,
          entry_date,
          start_time,
          end_time
        ) VALUES (
          NEW.task_id,
          NEW.technician_id,
          'work_normal',
          DATE(NEW.recorded_at),
          v_check_in_record.recorded_at::time,
          NEW.recorded_at::time
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger que dispara ao inserir check-out
DROP TRIGGER IF EXISTS trigger_create_time_entry_on_checkout ON technician_locations;
CREATE TRIGGER trigger_create_time_entry_on_checkout
  AFTER INSERT ON technician_locations
  FOR EACH ROW
  EXECUTE FUNCTION create_time_entry_from_checkout();

-- Função para importar dados históricos de check-in/check-out para time_entries
CREATE OR REPLACE FUNCTION public.import_historical_time_entries()
RETURNS INTEGER AS $$
DECLARE
  v_checkout RECORD;
  v_checkin RECORD;
  v_count INTEGER := 0;
BEGIN
  -- Processa todos os check-outs que têm task_id
  FOR v_checkout IN 
    SELECT * FROM technician_locations 
    WHERE location_type = 'check_out' 
      AND task_id IS NOT NULL
    ORDER BY recorded_at
  LOOP
    -- Busca o check-in correspondente
    SELECT * INTO v_checkin
    FROM technician_locations
    WHERE technician_id = v_checkout.technician_id
      AND task_id = v_checkout.task_id
      AND location_type = 'check_in'
      AND DATE(recorded_at) = DATE(v_checkout.recorded_at)
      AND recorded_at < v_checkout.recorded_at
    ORDER BY recorded_at DESC
    LIMIT 1;
    
    IF FOUND THEN
      -- Verifica se já existe
      IF NOT EXISTS (
        SELECT 1 FROM time_entries
        WHERE task_id = v_checkout.task_id
          AND technician_id = v_checkout.technician_id
          AND entry_date = DATE(v_checkout.recorded_at)
          AND start_time = v_checkin.recorded_at::time
          AND end_time = v_checkout.recorded_at::time
      ) THEN
        -- Insere o time_entry
        INSERT INTO time_entries (
          task_id,
          technician_id,
          entry_type,
          entry_date,
          start_time,
          end_time
        ) VALUES (
          v_checkout.task_id,
          v_checkout.technician_id,
          'work_normal',
          DATE(v_checkout.recorded_at),
          v_checkin.recorded_at::time,
          v_checkout.recorded_at::time
        );
        v_count := v_count + 1;
      END IF;
    END IF;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Executa a importação de dados históricos
SELECT import_historical_time_entries();