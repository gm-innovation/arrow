
-- =============================================
-- MÓDULO CORPORATIVO - TABELAS + RLS + TRIGGERS
-- =============================================

-- 1. TABELAS

CREATE TABLE public.departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  manager_id uuid REFERENCES public.profiles(id),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.corp_request_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  department_id uuid REFERENCES public.departments(id),
  requires_approval boolean NOT NULL DEFAULT false,
  requires_director_approval boolean NOT NULL DEFAULT false,
  director_threshold_value numeric,
  dynamic_fields jsonb DEFAULT '[]'::jsonb,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.corp_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  priority text NOT NULL DEFAULT 'medium',
  amount numeric,
  status text NOT NULL DEFAULT 'open',
  department_id uuid REFERENCES public.departments(id),
  type_id uuid REFERENCES public.corp_request_types(id),
  requester_id uuid NOT NULL REFERENCES public.profiles(id),
  manager_approver_id uuid REFERENCES public.profiles(id),
  manager_approved_at timestamptz,
  director_approver_id uuid REFERENCES public.profiles(id),
  director_approved_at timestamptz,
  rejection_reason text,
  dynamic_data jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.corp_request_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES public.corp_requests(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_url text NOT NULL,
  file_size integer,
  uploaded_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.corp_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  owner_user_id uuid NOT NULL REFERENCES public.profiles(id),
  related_request_id uuid REFERENCES public.corp_requests(id),
  document_type text NOT NULL,
  title text NOT NULL,
  file_name text NOT NULL,
  file_url text NOT NULL,
  uploaded_by uuid NOT NULL REFERENCES public.profiles(id),
  visibility_level text NOT NULL DEFAULT 'private',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.corp_feed_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES public.profiles(id),
  title text,
  content text NOT NULL,
  post_type text NOT NULL DEFAULT 'announcement',
  pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.corp_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id),
  action text NOT NULL,
  entity_type text,
  entity_id uuid,
  details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2. HELPER FUNCTIONS

CREATE OR REPLACE FUNCTION public.user_has_corp_role(_user_id uuid, _role app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.is_department_manager(_user_id uuid, _department_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.departments WHERE id = _department_id AND manager_id = _user_id)
$$;

-- 3. RLS

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_request_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_request_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_feed_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_audit_log ENABLE ROW LEVEL SECURITY;

-- departments
CREATE POLICY "dept_select" ON public.departments FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "dept_manage" ON public.departments FOR ALL TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin')))
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin')));

-- corp_request_types
CREATE POLICY "crt_select" ON public.corp_request_types FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "crt_manage" ON public.corp_request_types FOR ALL TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin')))
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin')));

-- corp_requests
CREATE POLICY "cr_select" ON public.corp_requests FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (
  requester_id = auth.uid() OR public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin')
  OR public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director')
  OR public.is_department_manager(auth.uid(), department_id)
));
CREATE POLICY "cr_insert" ON public.corp_requests FOR INSERT TO authenticated
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND requester_id = auth.uid());
CREATE POLICY "cr_update" ON public.corp_requests FOR UPDATE TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (
  requester_id = auth.uid() OR public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin')
  OR public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director')
  OR public.is_department_manager(auth.uid(), department_id)
));

-- corp_request_attachments
CREATE POLICY "cra_select" ON public.corp_request_attachments FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.corp_requests cr WHERE cr.id = request_id AND cr.company_id = public.user_company_id(auth.uid())
  AND (cr.requester_id = auth.uid() OR public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin')
    OR public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director')
    OR public.is_department_manager(auth.uid(), cr.department_id))));
CREATE POLICY "cra_insert" ON public.corp_request_attachments FOR INSERT TO authenticated
WITH CHECK (uploaded_by = auth.uid() AND EXISTS (SELECT 1 FROM public.corp_requests cr WHERE cr.id = request_id
  AND cr.company_id = public.user_company_id(auth.uid())
  AND (cr.requester_id = auth.uid() OR public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin'))));
CREATE POLICY "cra_delete" ON public.corp_request_attachments FOR DELETE TO authenticated
USING (EXISTS (SELECT 1 FROM public.corp_requests cr WHERE cr.id = request_id AND cr.company_id = public.user_company_id(auth.uid())
  AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin') OR public.has_role(auth.uid(), 'hr'))));

-- corp_documents
CREATE POLICY "cd_select" ON public.corp_documents FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()) AND (
  owner_user_id = auth.uid() OR uploaded_by = auth.uid() OR visibility_level = 'global'
  OR public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin') OR public.has_role(auth.uid(), 'hr')));
CREATE POLICY "cd_insert" ON public.corp_documents FOR INSERT TO authenticated
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND (
  (uploaded_by = auth.uid() AND owner_user_id = auth.uid())
  OR public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin') OR public.has_role(auth.uid(), 'hr')));
CREATE POLICY "cd_delete" ON public.corp_documents FOR DELETE TO authenticated
USING (company_id = public.user_company_id(auth.uid())
  AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin') OR public.has_role(auth.uid(), 'hr')));

-- corp_feed_posts
CREATE POLICY "cfp_select" ON public.corp_feed_posts FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "cfp_insert" ON public.corp_feed_posts FOR INSERT TO authenticated
WITH CHECK (company_id = public.user_company_id(auth.uid()) AND author_id = auth.uid()
  AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin') OR public.has_role(auth.uid(), 'hr')));
CREATE POLICY "cfp_update" ON public.corp_feed_posts FOR UPDATE TO authenticated
USING (company_id = public.user_company_id(auth.uid())
  AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin') OR public.has_role(auth.uid(), 'hr')));
CREATE POLICY "cfp_delete" ON public.corp_feed_posts FOR DELETE TO authenticated
USING (company_id = public.user_company_id(auth.uid())
  AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin') OR public.has_role(auth.uid(), 'hr')));

-- corp_audit_log
CREATE POLICY "cal_select" ON public.corp_audit_log FOR SELECT TO authenticated
USING (company_id = public.user_company_id(auth.uid())
  AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'super_admin') OR public.has_role(auth.uid(), 'director')));
CREATE POLICY "cal_insert" ON public.corp_audit_log FOR INSERT TO authenticated
WITH CHECK (company_id = public.user_company_id(auth.uid()));

-- 4. TRIGGERS updated_at
CREATE TRIGGER update_corp_request_types_updated_at BEFORE UPDATE ON public.corp_request_types FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_corp_requests_updated_at BEFORE UPDATE ON public.corp_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_corp_feed_posts_updated_at BEFORE UPDATE ON public.corp_feed_posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 5. AUDIT TRIGGERS
CREATE OR REPLACE FUNCTION public.log_corp_request_audit()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.corp_audit_log (company_id, user_id, action, entity_type, entity_id, details)
    VALUES (NEW.company_id, auth.uid(), 'request_created', 'request', NEW.id,
      jsonb_build_object('title', NEW.title, 'status', NEW.status));
  ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.corp_audit_log (company_id, user_id, action, entity_type, entity_id, details)
    VALUES (NEW.company_id, auth.uid(),
      CASE
        WHEN NEW.status = 'approved' AND OLD.status = 'pending_manager' THEN 'manager_approved'
        WHEN NEW.status = 'pending_director' THEN 'manager_approved'
        WHEN NEW.status = 'approved' AND OLD.status = 'pending_director' THEN 'director_approved'
        WHEN NEW.status = 'rejected' THEN 'request_rejected'
        ELSE 'request_status_changed'
      END, 'request', NEW.id,
      jsonb_build_object('old_status', OLD.status, 'new_status', NEW.status));
  END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER corp_request_audit_trigger AFTER INSERT OR UPDATE ON public.corp_requests FOR EACH ROW EXECUTE FUNCTION public.log_corp_request_audit();

CREATE OR REPLACE FUNCTION public.log_corp_document_audit()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.corp_audit_log (company_id, user_id, action, entity_type, entity_id, details)
    VALUES (NEW.company_id, auth.uid(), 'document_uploaded', 'document', NEW.id,
      jsonb_build_object('title', NEW.title, 'document_type', NEW.document_type));
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO public.corp_audit_log (company_id, user_id, action, entity_type, entity_id, details)
    VALUES (OLD.company_id, auth.uid(), 'document_deleted', 'document', OLD.id, jsonb_build_object('title', OLD.title));
  END IF;
  RETURN COALESCE(NEW, OLD);
END; $$;
CREATE TRIGGER corp_document_audit_trigger AFTER INSERT OR DELETE ON public.corp_documents FOR EACH ROW EXECUTE FUNCTION public.log_corp_document_audit();

CREATE OR REPLACE FUNCTION public.log_corp_feed_audit()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.corp_audit_log (company_id, user_id, action, entity_type, entity_id, details)
  VALUES (NEW.company_id, auth.uid(), 'feed_post_created', 'feed', NEW.id,
    jsonb_build_object('title', NEW.title, 'post_type', NEW.post_type));
  RETURN NEW;
END; $$;
CREATE TRIGGER corp_feed_audit_trigger AFTER INSERT ON public.corp_feed_posts FOR EACH ROW EXECUTE FUNCTION public.log_corp_feed_audit();

-- 6. STORAGE
INSERT INTO storage.buckets (id, name, public) VALUES ('corp-documents', 'corp-documents', false) ON CONFLICT (id) DO NOTHING;
CREATE POLICY "corp_storage_insert" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'corp-documents');
CREATE POLICY "corp_storage_select" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'corp-documents');
CREATE POLICY "corp_storage_delete" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'corp-documents');

-- 7. INDEXES
CREATE INDEX idx_departments_company_id ON public.departments(company_id);
CREATE INDEX idx_corp_request_types_company_id ON public.corp_request_types(company_id);
CREATE INDEX idx_corp_requests_company_id ON public.corp_requests(company_id);
CREATE INDEX idx_corp_requests_status ON public.corp_requests(status);
CREATE INDEX idx_corp_requests_requester_id ON public.corp_requests(requester_id);
CREATE INDEX idx_corp_requests_department_id ON public.corp_requests(department_id);
CREATE INDEX idx_corp_request_attachments_request_id ON public.corp_request_attachments(request_id);
CREATE INDEX idx_corp_documents_company_id ON public.corp_documents(company_id);
CREATE INDEX idx_corp_documents_owner_user_id ON public.corp_documents(owner_user_id);
CREATE INDEX idx_corp_feed_posts_company_id ON public.corp_feed_posts(company_id);
CREATE INDEX idx_corp_audit_log_company_id ON public.corp_audit_log(company_id);
CREATE INDEX idx_corp_audit_log_entity ON public.corp_audit_log(entity_type, entity_id);
