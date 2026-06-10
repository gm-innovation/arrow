// hr-document-compliance-check
// Daily cron job: scans hr_employee_document_status per company and
// inserts in-app notifications for missing / pending / expiring / expired documents.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const STATUSES_TO_NOTIFY = ["missing", "pending_review", "expiring_soon", "expired"];

const titleFor = (status: string, name: string, due?: number | null) => {
  switch (status) {
    case "missing":
      return `Documento pendente: ${name}`;
    case "pending_review":
      return `Documento aguardando revisão: ${name}`;
    case "expiring_soon":
      return `Documento a vencer: ${name}${due != null ? ` (${due} dias)` : ""}`;
    case "expired":
      return `Documento vencido: ${name}`;
    default:
      return name;
  }
};

const messageFor = (status: string, employeeName: string) => {
  switch (status) {
    case "missing":
      return `${employeeName} ainda não enviou este documento obrigatório.`;
    case "pending_review":
      return `Documento de ${employeeName} aguardando validação.`;
    case "expiring_soon":
      return `O documento de ${employeeName} vai vencer em breve.`;
    case "expired":
      return `O documento de ${employeeName} está vencido.`;
    default:
      return "";
  }
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  try {
    // 1) all companies
    const { data: companies, error: cErr } = await admin
      .from("companies")
      .select("id");
    if (cErr) throw cErr;

    const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    let inserted = 0;

    for (const company of companies ?? []) {
      // 2) compute statuses
      const { data: rows, error: sErr } = await admin
        .rpc("hr_employee_document_status", { _company_id: company.id });
      if (sErr) {
        console.error("status rpc failed", company.id, sErr);
        continue;
      }

      // 3) HR users (one query per company)
      const { data: hrRoleRows } = await admin
        .from("user_roles")
        .select("user_id")
        .eq("role", "hr");
      const hrIds = new Set((hrRoleRows ?? []).map((r: any) => r.user_id));
      // filter HR users to this company
      let companyHrIds: string[] = [];
      if (hrIds.size) {
        const { data: hrProfiles } = await admin
          .from("profiles")
          .select("id")
          .in("id", [...hrIds])
          .eq("company_id", company.id);
        companyHrIds = (hrProfiles ?? []).map((p: any) => p.id);
      }

      const pendings = (rows ?? []).filter((r: any) => STATUSES_TO_NOTIFY.includes(r.status));

      for (const r of pendings) {
        const recipients = new Set<string>();
        // employee always
        recipients.add(r.employee_id);
        // direct manager when responsible
        if (
          (r.responsible_role === "direct_manager" || r.responsible_role === "both") &&
          r.direct_manager_id
        ) {
          recipients.add(r.direct_manager_id);
        }
        // HR when responsible OR fallback (direct_manager without manager set)
        if (
          r.responsible_role === "hr" ||
          r.responsible_role === "both" ||
          (r.responsible_role === "direct_manager" && !r.direct_manager_id)
        ) {
          companyHrIds.forEach((id) => recipients.add(id));
        }

        const title = titleFor(r.status, r.catalog_name, r.due_in_days);
        const message = messageFor(r.status, r.employee_name);
        const referenceId = r.document_id ?? r.catalog_id;

        for (const userId of recipients) {
          // dedupe: skip if any unread notification with same reference_id in last 24h
          const { data: existing } = await admin
            .from("notifications")
            .select("id")
            .eq("user_id", userId)
            .eq("reference_id", referenceId)
            .eq("read", false)
            .gte("created_at", since)
            .limit(1);
          if (existing && existing.length > 0) continue;

          const { error: insErr } = await admin.from("notifications").insert({
            user_id: userId,
            notification_type: "system",
            title,
            message,
            reference_id: referenceId,
          });
          if (insErr) {
            console.error("insert notification failed", userId, insErr.message);
          } else {
            inserted += 1;
          }
        }
      }
    }

    return new Response(JSON.stringify({ ok: true, inserted }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    console.error("compliance check failed", err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
