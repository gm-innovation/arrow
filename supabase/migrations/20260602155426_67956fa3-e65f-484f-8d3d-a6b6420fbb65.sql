CREATE OR REPLACE FUNCTION public.update_company_careers_page(
  _company_id uuid,
  _about_title text,
  _about_text text,
  _mission text,
  _values text[]
)
RETURNS TABLE (
  careers_about_title text,
  careers_about_text text,
  careers_mission text,
  careers_values text[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF NOT (
    public.has_role(auth.uid(), 'super_admin'::public.app_role)
    OR (
      public.has_role(auth.uid(), 'hr'::public.app_role)
      AND public.user_company_id(auth.uid()) = _company_id
    )
  ) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  RETURN QUERY
  UPDATE public.companies c
  SET
    careers_about_title = NULLIF(BTRIM(_about_title), ''),
    careers_about_text = NULLIF(BTRIM(_about_text), ''),
    careers_mission = NULLIF(BTRIM(_mission), ''),
    careers_values = CASE
      WHEN _values IS NULL OR cardinality(_values) = 0 THEN NULL
      ELSE _values
    END
  WHERE c.id = _company_id
  RETURNING
    c.careers_about_title,
    c.careers_about_text,
    c.careers_mission,
    c.careers_values;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_company_careers_page(uuid, text, text, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_company_careers_page(uuid, text, text, text, text[]) TO service_role;