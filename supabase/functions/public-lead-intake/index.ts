// Public, unauthenticated endpoint for site forms.
// Receives RFQs and contact submissions, validates, applies anti-spam, persists.
import { createClient } from 'npm:@supabase/supabase-js@2'
import { z } from 'npm:zod@3.23.8'

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const ItemSchema = z.object({
  name: z.string().trim().min(1).max(200),
  qty: z.number().positive().max(100000).optional(),
  notes: z.string().max(500).optional(),
})

const BodySchema = z.object({
  type: z.enum(['rfq', 'contact']),
  company_slug: z.string().trim().min(1).max(80),
  name: z.string().trim().min(2).max(150),
  email: z.string().trim().email().max(255),
  phone: z.string().trim().max(40).optional().nullable(),
  company_name: z.string().trim().max(200).optional().nullable(),
  message: z.string().trim().max(4000).optional().nullable(),
  items: z.array(ItemSchema).max(50).optional(),
  // honeypot — must be empty
  website: z.string().max(0).optional(),
})

const RATE_LIMIT_PER_MIN = 5

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
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

  // Honeypot triggered → silently accept
  if (body.website && body.website.length > 0) {
    return json({ ok: true })
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

  // Rate limit per IP per minute
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

  if (rl && rl.count >= RATE_LIMIT_PER_MIN) {
    return json({ error: 'rate_limited' }, 429)
  }

  await supabase.from('public_lead_rate_limit').upsert(
    {
      ip,
      window_start: windowStart.toISOString(),
      count: (rl?.count ?? 0) + 1,
    },
    { onConflict: 'ip,window_start' },
  )

  // Insert lead
  const { data: lead, error: insertErr } = await supabase
    .from('public_site_leads')
    .insert({
      company_id: company.id,
      type: body.type,
      name: body.name,
      email: body.email,
      phone: body.phone ?? null,
      company_name: body.company_name ?? null,
      message: body.message ?? null,
      items: body.items ?? [],
      ip,
      user_agent: req.headers.get('user-agent') ?? null,
    })
    .select('id')
    .single()

  if (insertErr || !lead) {
    console.error('insert lead failed', insertErr)
    return json({ error: 'insert_failed' }, 500)
  }

  // Notify coordinators / directors (best-effort, non-blocking on failure)
  try {
    const { data: staff } = await supabase
      .from('user_roles')
      .select('user_id, role')
      .in('role', ['coordinator', 'director', 'admin', 'commercial', 'marketing'])

    if (staff && staff.length) {
      const ids = [...new Set(staff.map((s) => s.user_id))]
      const { data: profs } = await supabase
        .from('profiles')
        .select('id')
        .in('id', ids)
        .eq('company_id', company.id)

      if (profs?.length) {
        await supabase.from('notifications').insert(
          profs.map((p) => ({
            user_id: p.id,
            title: body.type === 'rfq' ? 'Nova solicitação de proposta' : 'Novo contato pelo site',
            message: `${body.name} <${body.email}>`,
            notification_type: 'request_created',
            reference_id: lead.id,
            read: false,
          })),
        )
      }
    }
  } catch (e) {
    console.warn('notify failed', e)
  }

  return json({ ok: true, id: lead.id })
})
