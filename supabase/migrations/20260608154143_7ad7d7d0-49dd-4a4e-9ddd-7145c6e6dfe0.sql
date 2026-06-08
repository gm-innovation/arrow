
ALTER TABLE public.quality_settings
  ADD COLUMN IF NOT EXISTS document_layout jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS quality_policy_text text,
  ADD COLUMN IF NOT EXISTS quality_policy_version integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS quality_policy_published_at timestamptz;

ALTER TABLE public.quality_context_versions
  ADD COLUMN IF NOT EXISTS scenario text;

CREATE TABLE IF NOT EXISTS public.quality_deviations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  origin_type text NOT NULL CHECK (origin_type IN ('document','process','product','ncr','other')),
  origin_ref_id uuid,
  title text NOT NULL,
  description text NOT NULL,
  justification text,
  requested_by uuid REFERENCES auth.users(id),
  approved_by uuid REFERENCES auth.users(id),
  approved_at timestamptz,
  expires_at date,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','approved','rejected','expired','closed')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_deviations TO authenticated;
GRANT ALL ON public.quality_deviations TO service_role;
ALTER TABLE public.quality_deviations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members view deviations" ON public.quality_deviations
  FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "Quality roles insert deviations" ON public.quality_deviations
  FOR INSERT TO authenticated
  WITH CHECK (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role)
      OR public.has_role(auth.uid(),'coordinator'::app_role)
      OR public.has_role(auth.uid(),'director'::app_role)
      OR public.has_role(auth.uid(),'super_admin'::app_role)));
CREATE POLICY "Quality roles update deviations" ON public.quality_deviations
  FOR UPDATE TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role)
      OR public.has_role(auth.uid(),'coordinator'::app_role)
      OR public.has_role(auth.uid(),'director'::app_role)
      OR public.has_role(auth.uid(),'super_admin'::app_role)));
CREATE POLICY "Quality roles delete deviations" ON public.quality_deviations
  FOR DELETE TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role)
      OR public.has_role(auth.uid(),'director'::app_role)
      OR public.has_role(auth.uid(),'super_admin'::app_role)));

CREATE TRIGGER update_quality_deviations_updated_at
  BEFORE UPDATE ON public.quality_deviations
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE INDEX IF NOT EXISTS idx_quality_deviations_company ON public.quality_deviations(company_id);
CREATE INDEX IF NOT EXISTS idx_quality_deviations_status ON public.quality_deviations(status);
CREATE INDEX IF NOT EXISTS idx_quality_deviations_origin ON public.quality_deviations(origin_type, origin_ref_id);

CREATE TABLE IF NOT EXISTS public.quality_policy_acknowledgements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  policy_version integer NOT NULL,
  acknowledged_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, user_id, policy_version)
);
GRANT SELECT, INSERT ON public.quality_policy_acknowledgements TO authenticated;
GRANT ALL ON public.quality_policy_acknowledgements TO service_role;
ALTER TABLE public.quality_policy_acknowledgements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members view acknowledgements" ON public.quality_policy_acknowledgements
  FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "Users insert own acknowledgement" ON public.quality_policy_acknowledgements
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND company_id = public.user_company_id(auth.uid()));

CREATE INDEX IF NOT EXISTS idx_policy_ack_company_user
  ON public.quality_policy_acknowledgements(company_id, user_id);

CREATE TABLE IF NOT EXISTS public.quality_it_safeguards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('backup','antivirus','restore_test','other')),
  performed_at timestamptz NOT NULL DEFAULT now(),
  performed_by uuid REFERENCES auth.users(id),
  target text,
  result text NOT NULL DEFAULT 'ok' CHECK (result IN ('ok','fail','partial')),
  evidence_url text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_it_safeguards TO authenticated;
GRANT ALL ON public.quality_it_safeguards TO service_role;
ALTER TABLE public.quality_it_safeguards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members view IT safeguards" ON public.quality_it_safeguards
  FOR SELECT TO authenticated
  USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "Quality IT insert safeguards" ON public.quality_it_safeguards
  FOR INSERT TO authenticated
  WITH CHECK (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role)
      OR public.has_role(auth.uid(),'coordinator'::app_role)
      OR public.has_role(auth.uid(),'director'::app_role)
      OR public.has_role(auth.uid(),'super_admin'::app_role)));
CREATE POLICY "Quality IT update safeguards" ON public.quality_it_safeguards
  FOR UPDATE TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role)
      OR public.has_role(auth.uid(),'coordinator'::app_role)
      OR public.has_role(auth.uid(),'director'::app_role)
      OR public.has_role(auth.uid(),'super_admin'::app_role)));
CREATE POLICY "Quality IT delete safeguards" ON public.quality_it_safeguards
  FOR DELETE TO authenticated
  USING (company_id = public.user_company_id(auth.uid())
    AND (public.has_role(auth.uid(),'qualidade'::app_role)
      OR public.has_role(auth.uid(),'director'::app_role)
      OR public.has_role(auth.uid(),'super_admin'::app_role)));

CREATE TRIGGER update_quality_it_safeguards_updated_at
  BEFORE UPDATE ON public.quality_it_safeguards
  FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();

CREATE INDEX IF NOT EXISTS idx_it_safeguards_company_date
  ON public.quality_it_safeguards(company_id, performed_at DESC);
