// Public, unauthenticated endpoint that returns the company + active openings
// + benefits + about/culture content for a careers page slug.
// Avoids exposing companies/job_openings via RLS.
// v2 - includes benefits & about fields
import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const url = new URL(req.url)
  const slug = (url.searchParams.get('slug') || '').trim().toLowerCase()
  if (!slug) return json({ enabled: false, error: 'missing_slug' }, 400)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: company, error: companyErr } = await supabase
    .from('companies')
    .select('id, name, logo_url, public_intake_enabled, public_site_base_url, careers_about_title, careers_about_text, careers_mission, careers_values')
    .eq('public_site_slug', slug)
    .maybeSingle()

  if (companyErr) {
    console.error('company lookup failed', companyErr)
    return json({ enabled: false, error: 'lookup_failed' }, 500)
  }
  if (!company || !company.public_intake_enabled) {
    return json({ enabled: false })
  }

  const [{ data: openings, error: jobsErr }, { data: benefits, error: benefitsErr }] = await Promise.all([
    supabase
      .from('job_openings')
      .select('id, title, area, description, location, employment_type')
      .eq('company_id', company.id)
      .eq('is_active', true)
      .order('created_at', { ascending: false }),
    supabase
      .from('company_benefits')
      .select('id, title, description, icon, display_order')
      .eq('company_id', company.id)
      .eq('is_active', true)
      .order('display_order', { ascending: true }),
  ])

  if (jobsErr) console.error('openings lookup failed', jobsErr)
  if (benefitsErr) console.error('benefits lookup failed', benefitsErr)

  return json({
    enabled: true,
    company: {
      id: company.id,
      name: company.name ?? null,
      logo_url: company.logo_url ?? null,
      website_url: company.public_site_base_url ?? null,
      about_title: company.careers_about_title ?? null,
      about_text: company.careers_about_text ?? null,
      mission: company.careers_mission ?? null,
      values: company.careers_values ?? null,
    },
    openings: openings ?? [],
    benefits: benefits ?? [],
  })
})
