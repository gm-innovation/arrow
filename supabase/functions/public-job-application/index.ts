// Public, unauthenticated endpoint for the careers form.
// Receives candidate applications + CV upload, validates, anti-spam, persists.
import { createClient } from 'npm:@supabase/supabase-js@2'
import { z } from 'npm:zod@3.23.8'

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const BodySchema = z.object({
  company_slug: z.string().trim().min(1).max(80),
  job_opening_id: z.string().uuid().optional().nullable(),
  full_name: z.string().trim().min(2).max(150),
  email: z.string().trim().email().max(255),
  phone: z.string().trim().max(40).optional().nullable(),
  city: z.string().trim().max(120).optional().nullable(),
  state: z.string().trim().max(40).optional().nullable(),
  linkedin_url: z.string().trim().url().max(300).optional().nullable().or(z.literal('')),
  area_of_interest: z.string().trim().max(120).optional().nullable(),
  salary_expectation: z.number().nonnegative().max(10_000_000).optional().nullable(),
  availability: z.string().trim().max(120).optional().nullable(),
  cover_letter: z.string().trim().max(4000).optional().nullable(),
  cv_base64: z.string().min(1).max(8_000_000), // ~6MB after base64
  cv_file_name: z.string().trim().min(1).max(200),
  cv_mime_type: z.string().trim().min(1).max(120),
  // honeypot — must be empty
  website: z.string().max(0).optional(),
})

const RATE_LIMIT_PER_MIN = 5
const ALLOWED_MIMES = new Set([
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
])

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function sanitizeFilename(name: string) {
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .slice(-120)
}

function base64ToBytes(b64: string): Uint8Array {
  const clean = b64.includes(',') ? b64.split(',')[1] : b64
  const bin = atob(clean)
  const bytes = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i)
  return bytes
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  let raw: unknown
  try {
    raw = await req.json()
  } catch {
    return json({ error: 'invalid_json' }, 400)
  }

  const parsed = BodySchema.safeParse(raw)
  if (!parsed.success) {
    return json({ error: 'validation_failed', details: parsed.error.flatten().fieldErrors }, 400)
  }
  const body = parsed.data

  // Honeypot
  if (body.website && body.website.length > 0) return json({ ok: true })

  if (!ALLOWED_MIMES.has(body.cv_mime_type)) {
    return json({ error: 'invalid_cv_type', message: 'Apenas PDF ou DOC/DOCX' }, 400)
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // Resolve company by slug
  const { data: company, error: companyErr } = await supabase
    .from('companies')
    .select('id, public_intake_enabled')
    .eq('public_site_slug', body.company_slug)
    .maybeSingle()
  if (companyErr) return json({ error: 'lookup_failed' }, 500)
  if (!company || !company.public_intake_enabled) {
    return json({ error: 'unknown_or_disabled_destination' }, 404)
  }

  // Rate limit per IP per minute (reuse public_lead_rate_limit table)
  const ip =
    req.headers.get('x-forwarded-for')?.split(',')[0].trim() ||
    req.headers.get('cf-connecting-ip') ||
    'unknown'
  const windowStart = new Date()
  windowStart.setSeconds(0, 0)
  const { data: rl } = await supabase
    .from('public_lead_rate_limit')
    .select('count')
    .eq('ip', ip)
    .eq('window_start', windowStart.toISOString())
    .maybeSingle()
  if (rl && rl.count >= RATE_LIMIT_PER_MIN) return json({ error: 'rate_limited' }, 429)
  await supabase.from('public_lead_rate_limit').upsert(
    { ip, window_start: windowStart.toISOString(), count: (rl?.count ?? 0) + 1 },
    { onConflict: 'ip,window_start' },
  )

  // Decode CV
  let cvBytes: Uint8Array
  try {
    cvBytes = base64ToBytes(body.cv_base64)
  } catch {
    return json({ error: 'invalid_cv_encoding' }, 400)
  }
  if (cvBytes.length > 5 * 1024 * 1024) {
    return json({ error: 'cv_too_large', message: 'Tamanho máximo: 5MB' }, 400)
  }

  // Insert application (without cv yet)
  const { data: app, error: insertErr } = await supabase
    .from('job_applications')
    .insert({
      company_id: company.id,
      job_opening_id: body.job_opening_id || null,
      full_name: body.full_name,
      email: body.email,
      phone: body.phone || null,
      city: body.city || null,
      state: body.state || null,
      linkedin_url: body.linkedin_url || null,
      area_of_interest: body.area_of_interest || null,
      salary_expectation: body.salary_expectation ?? null,
      availability: body.availability || null,
      cover_letter: body.cover_letter || null,
      status: 'new',
      source: 'site',
      ip,
      user_agent: req.headers.get('user-agent') ?? null,
    })
    .select('id')
    .single()
  if (insertErr || !app) {
    console.error('insert application failed', insertErr)
    return json({ error: 'insert_failed' }, 500)
  }

  // Upload CV
  const safeName = sanitizeFilename(body.cv_file_name)
  const path = `${company.id}/${app.id}/${safeName}`
  const { error: upErr } = await supabase.storage
    .from('recruitment-cvs')
    .upload(path, cvBytes, { contentType: body.cv_mime_type, upsert: true })
  if (upErr) {
    console.error('cv upload failed', upErr)
    // best-effort: keep the application row but no cv
  } else {
    await supabase
      .from('job_applications')
      .update({ cv_file_url: path, cv_file_name: safeName })
      .eq('id', app.id)
  }

  return json({ ok: true, id: app.id })
})
