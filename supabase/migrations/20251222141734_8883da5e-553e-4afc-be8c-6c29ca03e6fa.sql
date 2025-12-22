-- Alterar FKs para ON DELETE SET NULL para preservar históricos

-- time_entries: preservar registros de ponto
ALTER TABLE time_entries DROP CONSTRAINT IF EXISTS time_entries_technician_id_fkey;
ALTER TABLE time_entries ADD CONSTRAINT time_entries_technician_id_fkey 
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL;

-- visit_technicians: preservar histórico de visitas
ALTER TABLE visit_technicians DROP CONSTRAINT IF EXISTS visit_technicians_technician_id_fkey;
ALTER TABLE visit_technicians ADD CONSTRAINT visit_technicians_technician_id_fkey 
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL;

-- measurement_man_hours: preservar medições
ALTER TABLE measurement_man_hours DROP CONSTRAINT IF EXISTS measurement_man_hours_technician_id_fkey;
ALTER TABLE measurement_man_hours ADD CONSTRAINT measurement_man_hours_technician_id_fkey 
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL;

-- productivity_snapshots: preservar métricas
ALTER TABLE productivity_snapshots DROP CONSTRAINT IF EXISTS productivity_snapshots_technician_id_fkey;
ALTER TABLE productivity_snapshots ADD CONSTRAINT productivity_snapshots_technician_id_fkey 
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL;

-- checklist_responses: preservar respostas de checklist
ALTER TABLE checklist_responses DROP CONSTRAINT IF EXISTS checklist_responses_technician_id_fkey;
ALTER TABLE checklist_responses ADD CONSTRAINT checklist_responses_technician_id_fkey 
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL;

-- technician_absences: preservar histórico de ausências
ALTER TABLE technician_absences DROP CONSTRAINT IF EXISTS technician_absences_technician_id_fkey;
ALTER TABLE technician_absences ADD CONSTRAINT technician_absences_technician_id_fkey 
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL;

-- technician_on_call: preservar histórico de plantões
ALTER TABLE technician_on_call DROP CONSTRAINT IF EXISTS technician_on_call_technician_id_fkey;
ALTER TABLE technician_on_call ADD CONSTRAINT technician_on_call_technician_id_fkey 
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL;

-- hr_time_adjustments: preservar ajustes de ponto
ALTER TABLE hr_time_adjustments DROP CONSTRAINT IF EXISTS hr_time_adjustments_technician_id_fkey;
ALTER TABLE hr_time_adjustments ADD CONSTRAINT hr_time_adjustments_technician_id_fkey 
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL;