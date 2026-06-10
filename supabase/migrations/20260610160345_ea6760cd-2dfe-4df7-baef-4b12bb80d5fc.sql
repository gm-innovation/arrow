
CREATE TABLE public.hr_employee_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  employee_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  catalog_id uuid NOT NULL REFERENCES public.hr_document_catalog(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_path text NOT NULL,
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  uploaded_by uuid,
  issue_date date,
  expiry_date date,
  review_status text NOT NULL DEFAULT 'pending_review' CHECK (review_status IN ('pending_review','approved','rejected')),
  reviewed_at timestamptz,
  reviewed_by uuid,
  rejection_reason text,
  is_current boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.hr_employee_documents TO authenticated;
GRANT ALL ON public.hr_employee_documents TO service_role;

CREATE INDEX hr_employee_documents_employee_idx ON public.hr_employee_documents(employee_id);
CREATE INDEX hr_employee_documents_catalog_idx ON public.hr_employee_documents(catalog_id);
CREATE UNIQUE INDEX hr_employee_documents_current_uq
  ON public.hr_employee_documents (employee_id, catalog_id)
  WHERE is_current = true;

ALTER TABLE public.hr_employee_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hr_emp_docs_select"
  ON public.hr_employee_documents FOR SELECT TO authenticated
  USING (
    employee_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = employee_id AND p.direct_manager_id = auth.uid())
    OR public.has_role(auth.uid(), 'hr')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'super_admin')
  );

CREATE POLICY "hr_emp_docs_insert"
  ON public.hr_employee_documents FOR INSERT TO authenticated
  WITH CHECK (
    employee_id = auth.uid()
    OR public.has_role(auth.uid(), 'hr')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'super_admin')
  );

CREATE POLICY "hr_emp_docs_update"
  ON public.hr_employee_documents FOR UPDATE TO authenticated
  USING (
    employee_id = auth.uid()
    OR public.has_role(auth.uid(), 'hr')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'super_admin')
  );

CREATE POLICY "hr_emp_docs_delete"
  ON public.hr_employee_documents FOR DELETE TO authenticated
  USING (
    employee_id = auth.uid()
    OR public.has_role(auth.uid(), 'hr')
    OR public.has_role(auth.uid(), 'director')
    OR public.has_role(auth.uid(), 'super_admin')
  );

CREATE TRIGGER hr_emp_docs_set_updated_at
  BEFORE UPDATE ON public.hr_employee_documents
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_timestamp();

CREATE OR REPLACE FUNCTION public.hr_emp_docs_supersede_previous()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.is_current THEN
    UPDATE public.hr_employee_documents
      SET is_current = false
    WHERE employee_id = NEW.employee_id
      AND catalog_id = NEW.catalog_id
      AND id <> NEW.id
      AND is_current = true;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER hr_emp_docs_supersede
  BEFORE INSERT ON public.hr_employee_documents
  FOR EACH ROW EXECUTE FUNCTION public.hr_emp_docs_supersede_previous();

CREATE OR REPLACE FUNCTION public.hr_emp_docs_compute_fields()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_cat record;
  v_base date;
BEGIN
  SELECT has_expiry, default_validity_months INTO v_cat
  FROM public.hr_document_catalog WHERE id = NEW.catalog_id;

  IF v_cat.has_expiry AND v_cat.default_validity_months IS NOT NULL AND NEW.expiry_date IS NULL THEN
    v_base := COALESCE(NEW.issue_date, NEW.uploaded_at::date, CURRENT_DATE);
    NEW.expiry_date := v_base + (v_cat.default_validity_months || ' months')::interval;
  END IF;

  IF TG_OP = 'INSERT' AND NEW.uploaded_by IS NOT NULL THEN
    IF public.has_role(NEW.uploaded_by, 'hr')
       OR public.has_role(NEW.uploaded_by, 'director')
       OR public.has_role(NEW.uploaded_by, 'super_admin') THEN
      NEW.review_status := 'approved';
      NEW.reviewed_at := now();
      NEW.reviewed_by := NEW.uploaded_by;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER hr_emp_docs_compute
  BEFORE INSERT OR UPDATE ON public.hr_employee_documents
  FOR EACH ROW EXECUTE FUNCTION public.hr_emp_docs_compute_fields();

CREATE OR REPLACE FUNCTION public.hr_employee_document_status(_company_id uuid)
RETURNS TABLE (
  employee_id uuid,
  employee_name text,
  employee_position text,
  direct_manager_id uuid,
  catalog_id uuid,
  catalog_name text,
  catalog_category text,
  responsible_role text,
  renewal_warning_days int,
  document_id uuid,
  expiry_date date,
  due_in_days int,
  status text
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH applicable AS (
    SELECT
      p.id AS employee_id,
      p.full_name AS employee_name,
      p.position AS employee_position,
      p.direct_manager_id,
      c.id AS catalog_id,
      c.name AS catalog_name,
      c.category AS catalog_category,
      c.responsible_role,
      c.renewal_warning_days
    FROM public.profiles p
    CROSS JOIN public.hr_document_catalog c
    WHERE p.company_id = _company_id
      AND p.status = 'active'
      AND c.company_id = _company_id
      AND c.is_active = true
      AND (
        c.applies_to_all = true
        OR EXISTS (
          SELECT 1 FROM public.hr_document_catalog_positions cp
          WHERE cp.catalog_id = c.id AND cp.position = p.position
        )
      )
  )
  SELECT
    a.employee_id,
    a.employee_name,
    a.employee_position,
    a.direct_manager_id,
    a.catalog_id,
    a.catalog_name,
    a.catalog_category,
    a.responsible_role,
    a.renewal_warning_days,
    d.id AS document_id,
    d.expiry_date,
    CASE WHEN d.expiry_date IS NOT NULL THEN (d.expiry_date - CURRENT_DATE) ELSE NULL END AS due_in_days,
    CASE
      WHEN d.id IS NULL THEN 'missing'
      WHEN d.review_status = 'rejected' THEN 'missing'
      WHEN d.review_status = 'pending_review' THEN 'pending_review'
      WHEN d.review_status = 'approved' AND d.expiry_date IS NULL THEN 'valid'
      WHEN d.review_status = 'approved' AND d.expiry_date < CURRENT_DATE THEN 'expired'
      WHEN d.review_status = 'approved' AND d.expiry_date <= CURRENT_DATE + (a.renewal_warning_days || ' days')::interval THEN 'expiring_soon'
      ELSE 'valid'
    END AS status
  FROM applicable a
  LEFT JOIN public.hr_employee_documents d
    ON d.employee_id = a.employee_id
   AND d.catalog_id = a.catalog_id
   AND d.is_current = true;
END;
$$;

GRANT EXECUTE ON FUNCTION public.hr_employee_document_status(uuid) TO authenticated, service_role;
