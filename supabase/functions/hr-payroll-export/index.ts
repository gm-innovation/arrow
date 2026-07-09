import { corsHeaders } from 'npm:@supabase/supabase-js@2/cors'
import { createClient } from 'npm:@supabase/supabase-js@2'

interface Body {
  year: number
  month: number // 1-12
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const authHeader = req.headers.get('Authorization') ?? ''
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: userRes, error: userErr } = await userClient.auth.getUser()
    if (userErr || !userRes?.user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const userId = userRes.user.id

    const admin = createClient(supabaseUrl, serviceKey)

    // Authorization: hr, coordinator, director, super_admin
    const { data: roles } = await admin.from('user_roles').select('role').eq('user_id', userId)
    const allowed = new Set(['hr', 'coordinator', 'director', 'super_admin'])
    const roleList = (roles ?? []).map((r: any) => r.role)
    if (!roleList.some((r: string) => allowed.has(r))) {
      return new Response(JSON.stringify({ error: 'Forbidden' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: myProfile } = await admin.from('profiles').select('company_id').eq('id', userId).maybeSingle()
    const companyId = myProfile?.company_id
    if (!companyId) {
      return new Response(JSON.stringify({ error: 'Company not found' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { year, month } = (await req.json()) as Body
    if (!year || !month || month < 1 || month > 12) {
      return new Response(JSON.stringify({ error: 'Invalid period' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const startDate = new Date(Date.UTC(year, month - 1, 1)).toISOString().slice(0, 10)
    const endDate = new Date(Date.UTC(year, month, 0)).toISOString().slice(0, 10)

    // Employees of the company
    const { data: employees } = await admin
      .from('profiles')
      .select('id, full_name, cpf, position, hire_date, status')
      .eq('company_id', companyId)
      .order('full_name')

    const ids = (employees ?? []).map((e: any) => e.id)

    // Time entries in the month
    const { data: timeEntries } = await admin
      .from('time_entries')
      .select('technician_id, entry_date, hours_normal, hours_extra, hours_night, hours_standby')
      .in('technician_id', ids)
      .gte('entry_date', startDate)
      .lte('entry_date', endDate)

    // Absences overlapping the month
    const { data: absences } = await admin
      .from('technician_absences')
      .select('technician_id, absence_type, start_date, end_date, status')
      .in('technician_id', ids)
      .lte('start_date', endDate)
      .gte('end_date', startDate)
      .eq('status', 'approved')

    // Vacations approved overlapping the month
    const { data: vacations } = await admin
      .from('hr_vacation_requests')
      .select('employee_id, request_type, start_date, end_date, requested_days, sell_days, status')
      .in('employee_id', ids)
      .lte('start_date', endDate)
      .gte('end_date', startDate)
      .in('status', ['approved_hr', 'approved'])

    const daysBetween = (a: string, b: string) => {
      const s = new Date(a + 'T00:00:00Z').getTime()
      const e = new Date(b + 'T00:00:00Z').getTime()
      return Math.floor((e - s) / 86400000) + 1
    }
    const clamp = (s: string, e: string) => {
      const cs = s < startDate ? startDate : s
      const ce = e > endDate ? endDate : e
      return cs > ce ? 0 : daysBetween(cs, ce)
    }

    const rows = (employees ?? []).map((emp: any) => {
      const te = (timeEntries ?? []).filter((t: any) => t.technician_id === emp.id)
      const hoursNormal = te.reduce((s: number, t: any) => s + Number(t.hours_normal ?? 0), 0)
      const hoursExtra = te.reduce((s: number, t: any) => s + Number(t.hours_extra ?? 0), 0)
      const hoursNight = te.reduce((s: number, t: any) => s + Number(t.hours_night ?? 0), 0)
      const hoursStandby = te.reduce((s: number, t: any) => s + Number(t.hours_standby ?? 0), 0)

      const empAbs = (absences ?? []).filter((a: any) => a.technician_id === emp.id)
      const absByType: Record<string, number> = {}
      for (const a of empAbs) {
        absByType[a.absence_type] = (absByType[a.absence_type] ?? 0) + clamp(a.start_date, a.end_date)
      }

      const empVac = (vacations ?? []).filter((v: any) => v.employee_id === emp.id)
      const vacationDays = empVac.reduce((s: number, v: any) => s + clamp(v.start_date, v.end_date), 0)
      const soldDays = empVac.reduce((s: number, v: any) => s + Number(v.sell_days ?? 0), 0)
      const advance13 = empVac.some((v: any) => v.advance_13th)

      return {
        employee_id: emp.id,
        full_name: emp.full_name,
        cpf: emp.cpf ?? '',
        position: emp.position ?? '',
        hire_date: emp.hire_date ?? '',
        status: emp.status ?? '',
        hours_normal: Number(hoursNormal.toFixed(2)),
        hours_extra: Number(hoursExtra.toFixed(2)),
        hours_night: Number(hoursNight.toFixed(2)),
        hours_standby: Number(hoursStandby.toFixed(2)),
        absence_days_by_type: absByType,
        vacation_days_in_period: vacationDays,
        sold_days: soldDays,
        advance_13th: advance13,
      }
    })

    return new Response(JSON.stringify({ period: { year, month, startDate, endDate }, rows }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200,
    })
  } catch (e) {
    console.error('hr-payroll-export error', e)
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
