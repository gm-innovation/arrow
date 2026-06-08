CREATE TABLE public.quality_org_chart_nodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES public.quality_org_chart_nodes(id) ON DELETE SET NULL,
  title text NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  department_id uuid REFERENCES public.departments(id) ON DELETE SET NULL,
  responsibilities text,
  authority text,
  order_index integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quality_org_chart_nodes TO authenticated;
GRANT ALL ON public.quality_org_chart_nodes TO service_role;

ALTER TABLE public.quality_org_chart_nodes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org chart read same company"
ON public.quality_org_chart_nodes FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));

CREATE POLICY "org chart manage by leaders or master"
ON public.quality_org_chart_nodes FOR ALL TO authenticated
USING (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'coordinator')
    OR public.has_role(auth.uid(), 'super_admin')
    OR EXISTS (
      SELECT 1 FROM public.quality_settings qs
      WHERE qs.company_id = public.user_company_id(auth.uid())
        AND qs.quality_master_user_id = auth.uid()
    )
  )
)
WITH CHECK (
  company_id = public.user_company_id(auth.uid())
  AND (
    public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'coordinator')
    OR public.has_role(auth.uid(), 'super_admin')
    OR EXISTS (
      SELECT 1 FROM public.quality_settings qs
      WHERE qs.company_id = public.user_company_id(auth.uid())
        AND qs.quality_master_user_id = auth.uid()
    )
  )
);

CREATE INDEX idx_qocn_company ON public.quality_org_chart_nodes(company_id);
CREATE INDEX idx_qocn_parent ON public.quality_org_chart_nodes(parent_id);

CREATE TRIGGER trg_qocn_updated_at
BEFORE UPDATE ON public.quality_org_chart_nodes
FOR EACH ROW EXECUTE FUNCTION public.quality_touch_updated_at();