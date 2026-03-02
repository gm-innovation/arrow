
-- Table for join requests
CREATE TABLE public.corp_group_join_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.corp_groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  requested_at timestamptz NOT NULL DEFAULT now(),
  reviewed_by uuid REFERENCES auth.users(id),
  reviewed_at timestamptz,
  UNIQUE(group_id, user_id)
);

ALTER TABLE public.corp_group_join_requests ENABLE ROW LEVEL SECURITY;

-- Users can see their own requests
CREATE POLICY "Users can view own requests"
  ON public.corp_group_join_requests FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Admin/HR can see all requests for their company's groups
CREATE POLICY "Admin/HR can view company requests"
  ON public.corp_group_join_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM corp_groups cg
      JOIN profiles p ON p.company_id = cg.company_id
      JOIN user_roles ur ON ur.user_id = p.id
      WHERE cg.id = corp_group_join_requests.group_id
        AND p.id = auth.uid()
        AND ur.role IN ('admin', 'hr')
    )
  );

-- Users can insert their own requests
CREATE POLICY "Users can request to join"
  ON public.corp_group_join_requests FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Admin/HR can update requests (approve/reject)
CREATE POLICY "Admin/HR can update requests"
  ON public.corp_group_join_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM corp_groups cg
      JOIN profiles p ON p.company_id = cg.company_id
      JOIN user_roles ur ON ur.user_id = p.id
      WHERE cg.id = corp_group_join_requests.group_id
        AND p.id = auth.uid()
        AND ur.role IN ('admin', 'hr')
    )
  );

-- Users can delete their own pending requests
CREATE POLICY "Users can cancel own pending requests"
  ON public.corp_group_join_requests FOR DELETE
  TO authenticated
  USING (user_id = auth.uid() AND status = 'pending');

-- Trigger: auto-add to group when approved
CREATE OR REPLACE FUNCTION public.auto_add_member_on_approval()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    INSERT INTO corp_group_members (group_id, user_id)
    VALUES (NEW.group_id, NEW.user_id)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_add_member_on_approval
  AFTER UPDATE ON public.corp_group_join_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_add_member_on_approval();
