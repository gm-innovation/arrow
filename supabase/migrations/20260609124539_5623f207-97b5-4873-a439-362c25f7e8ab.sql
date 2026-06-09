
CREATE TABLE public.quality_document_norms (
  document_id uuid NOT NULL REFERENCES public.quality_documents(id) ON DELETE CASCADE,
  norm_id uuid NOT NULL REFERENCES public.quality_reference_norms(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  PRIMARY KEY (document_id, norm_id)
);
GRANT SELECT, INSERT, DELETE ON public.quality_document_norms TO authenticated;
GRANT ALL ON public.quality_document_norms TO service_role;
ALTER TABLE public.quality_document_norms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qdn_read_company" ON public.quality_document_norms
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.quality_documents d
    JOIN public.profiles p ON p.id = auth.uid()
    WHERE d.id = document_id AND d.company_id = p.company_id
  ));

CREATE POLICY "qdn_master_cud" ON public.quality_document_norms
  FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND EXISTS (
    SELECT 1 FROM public.quality_documents d
    JOIN public.profiles p ON p.id = auth.uid()
    WHERE d.id = document_id AND d.company_id = p.company_id
  ))
  WITH CHECK (public.quality_is_master(auth.uid()) AND EXISTS (
    SELECT 1 FROM public.quality_documents d
    JOIN public.profiles p ON p.id = auth.uid()
    WHERE d.id = document_id AND d.company_id = p.company_id
  ));

CREATE INDEX idx_qdn_doc ON public.quality_document_norms(document_id);
CREATE INDEX idx_qdn_norm ON public.quality_document_norms(norm_id);

ALTER TABLE public.quality_training_plans
  ADD COLUMN IF NOT EXISTS type text NOT NULL DEFAULT 'internal'
    CHECK (type IN ('internal','external_mandatory','external_optional')),
  ADD COLUMN IF NOT EXISTS origin_type text
    CHECK (origin_type IN ('competency_gap','audit','ncr','legal_requirement','customer_requirement','iso_requirement')),
  ADD COLUMN IF NOT EXISTS institution text,
  ADD COLUMN IF NOT EXISTS instructor text,
  ADD COLUMN IF NOT EXISTS certificate_url text,
  ADD COLUMN IF NOT EXISTS program_year int,
  ADD COLUMN IF NOT EXISTS planned_date date,
  ADD COLUMN IF NOT EXISTS executed_date date;

UPDATE public.quality_training_plans
  SET origin_type = 'competency_gap'
  WHERE origin_type IS NULL AND auto_generated = true;

CREATE INDEX IF NOT EXISTS idx_tplans_program_year ON public.quality_training_plans(company_id, program_year);

CREATE TABLE public.quality_training_effectiveness (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  training_id uuid NOT NULL REFERENCES public.quality_training_plans(id) ON DELETE CASCADE,
  evaluator_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  evaluation_date date NOT NULL DEFAULT CURRENT_DATE,
  result text NOT NULL CHECK (result IN ('eficaz','parcial','nao_eficaz')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_training_effectiveness TO authenticated;
GRANT ALL ON public.quality_training_effectiveness TO service_role;
ALTER TABLE public.quality_training_effectiveness ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qte_read_company" ON public.quality_training_effectiveness
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "qte_master_cud" ON public.quality_training_effectiveness
  FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE INDEX idx_qte_training ON public.quality_training_effectiveness(training_id);

CREATE TRIGGER trg_qte_updated_at
  BEFORE UPDATE ON public.quality_training_effectiveness
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE TABLE public.quality_awareness_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  topic text NOT NULL,
  description text,
  event_date date NOT NULL DEFAULT CURRENT_DATE,
  conducted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  evidence_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_awareness_events TO authenticated;
GRANT ALL ON public.quality_awareness_events TO service_role;
ALTER TABLE public.quality_awareness_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qae_read_company" ON public.quality_awareness_events
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "qae_master_cud" ON public.quality_awareness_events
  FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (public.quality_is_master(auth.uid()) AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE TRIGGER trg_qae_updated_at
  BEFORE UPDATE ON public.quality_awareness_events
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE TABLE public.quality_awareness_attendees (
  event_id uuid NOT NULL REFERENCES public.quality_awareness_events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  acknowledged_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (event_id, user_id)
);
GRANT SELECT, INSERT, DELETE ON public.quality_awareness_attendees TO authenticated;
GRANT ALL ON public.quality_awareness_attendees TO service_role;
ALTER TABLE public.quality_awareness_attendees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qaa_read_company" ON public.quality_awareness_attendees
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.quality_awareness_events e
    WHERE e.id = event_id
      AND e.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  ));

CREATE POLICY "qaa_master_cud" ON public.quality_awareness_attendees
  FOR ALL TO authenticated
  USING (public.quality_is_master(auth.uid()) AND EXISTS (
    SELECT 1 FROM public.quality_awareness_events e
    WHERE e.id = event_id
      AND e.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  ))
  WITH CHECK (public.quality_is_master(auth.uid()) AND EXISTS (
    SELECT 1 FROM public.quality_awareness_events e
    WHERE e.id = event_id
      AND e.company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  ));
