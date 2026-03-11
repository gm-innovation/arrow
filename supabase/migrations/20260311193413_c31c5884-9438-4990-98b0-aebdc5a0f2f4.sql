DROP POLICY IF EXISTS "Admins can create notifications" ON public.notifications;

CREATE POLICY "Authorized roles can create notifications"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'super_admin'::app_role) OR
  has_role(auth.uid(), 'coordinator'::app_role) OR
  has_role(auth.uid(), 'director'::app_role)
);