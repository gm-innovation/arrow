REVOKE EXECUTE ON FUNCTION public.update_company_careers_page(uuid, text, text, text, text[]) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.update_company_careers_page(uuid, text, text, text, text[]) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_company_careers_page(uuid, text, text, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_company_careers_page(uuid, text, text, text, text[]) TO service_role;