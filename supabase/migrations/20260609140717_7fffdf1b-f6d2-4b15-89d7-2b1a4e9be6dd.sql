CREATE TABLE public.quality_homologations (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  cycle text NOT NULL,
  homologated_by uuid NOT NULL,
  status text NOT NULL DEFAULT 'em_andamento' CHECK (status IN ('em_andamento','homologado','homologado_com_ressalvas','reprovado')),
  notes text,
  pdf_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  signed_at timestamptz
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_homologations TO authenticated;
GRANT ALL ON public.quality_homologations TO service_role;

ALTER TABLE public.quality_homologations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Quality leaders can view company homologations"
ON public.quality_homologations FOR SELECT TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'coordinator'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE POLICY "Quality leaders can insert homologations"
ON public.quality_homologations FOR INSERT TO authenticated
WITH CHECK (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'coordinator'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE POLICY "Quality leaders can update homologations"
ON public.quality_homologations FOR UPDATE TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'coordinator'::app_role)
    OR public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE POLICY "Directors can delete homologations"
ON public.quality_homologations FOR DELETE TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'director'::app_role)
    OR public.has_role(auth.uid(), 'super_admin'::app_role)
  )
);

CREATE TRIGGER update_quality_homologations_updated_at
BEFORE UPDATE ON public.quality_homologations
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE INDEX idx_quality_homologations_company ON public.quality_homologations(company_id, created_at DESC);