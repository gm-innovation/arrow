// Public API v1 — endpoints externos para integrações de site/parceiros.
// Autenticação por API key (header Authorization: Bearer ark_live_...).
import { createClient } from "npm:@supabase/supabase-js@2";
import { z } from "npm:zod@3.23.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, idempotency-key",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
  auth: { persistSession: false },
});

// ---------- rate limit (in-memory, por integração) ----------
const RATE_LIMIT = 120;
const WINDOW_MS = 60_000;
const buckets = new Map<string, { count: number; reset: number }>();
function rateLimit(key: string) {
  const now = Date.now();
  const b = buckets.get(key);
  if (!b || b.reset < now) {
    buckets.set(key, { count: 1, reset: now + WINDOW_MS });
    return { ok: true, remaining: RATE_LIMIT - 1 };
  }
  if (b.count >= RATE_LIMIT) return { ok: false, remaining: 0 };
  b.count += 1;
  return { ok: true, remaining: RATE_LIMIT - b.count };
}

// ---------- helpers ----------
function rid() {
  return crypto.randomUUID();
}
function json(status: number, body: unknown, extra: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json", ...extra },
  });
}
function err(status: number, code: string, message: string, request_id: string, details?: unknown) {
  return json(status, { error: { code, message, details }, request_id });
}

async function logRequest(opts: {
  integration_id: string | null;
  company_id: string | null;
  method: string;
  path: string;
  status: number;
  latency_ms: number;
  ip: string | null;
  user_agent: string | null;
  error_message?: string | null;
}) {
  try {
    await admin.from("api_request_logs").insert(opts);
    if (opts.integration_id) {
      await admin
        .from("api_integrations")
        .update({ last_used_at: new Date().toISOString() })
        .eq("id", opts.integration_id);
    }
  } catch (_e) {/* best-effort */}
}

// ---------- auth ----------
async function authenticate(req: Request) {
  const h = req.headers.get("authorization") ?? "";
  const m = h.match(/^Bearer\s+(ark_live_[A-Za-z0-9]+)$/);
  if (!m) return null;
  const { data, error } = await admin.rpc("verify_api_key", { _key: m[1] });
  if (error || !data || data.length === 0) return null;
  return data[0] as { integration_id: string; company_id: string; scopes: string[] };
}

function requireScope(integration: { scopes: string[] }, scope: string) {
  return integration.scopes.includes(scope);
}

// ---------- idempotency ----------
async function idempotencyGet(integration_id: string, key: string | null) {
  if (!key) return null;
  const { data } = await admin
    .from("api_idempotency_keys")
    .select("response_status, response_body, created_at")
    .eq("integration_id", integration_id)
    .eq("key", key)
    .maybeSingle();
  if (!data) return null;
  // 24h TTL
  if (Date.now() - new Date(data.created_at).getTime() > 24 * 3600 * 1000) return null;
  return data;
}
async function idempotencySave(
  integration_id: string,
  key: string | null,
  status: number,
  body: unknown,
) {
  if (!key) return;
  await admin
    .from("api_idempotency_keys")
    .upsert(
      { integration_id, key, response_status: status, response_body: body },
      { onConflict: "integration_id,key" },
    );
}

// ---------- handlers ----------
const RfqSchema = z.object({
  company: z.object({
    name: z.string().min(1).max(255),
    cnpj: z.string().max(20).optional(),
    email: z.string().email().optional(),
    phone: z.string().max(50).optional(),
    segment: z.string().max(100).optional(),
  }),
  contact: z.object({
    name: z.string().min(1).max(255),
    email: z.string().email().optional(),
    phone: z.string().max(50).optional(),
    role: z.string().max(100).optional(),
  }),
  request: z.object({
    type: z.enum(["quote", "service", "product", "info"]).default("quote"),
    title: z.string().max(255).optional(),
    message: z.string().max(5000).optional(),
    estimated_value: z.number().nonnegative().optional(),
    products: z
      .array(z.object({ id: z.string().uuid(), quantity: z.number().int().positive().default(1) }))
      .optional(),
  }),
  source: z.string().max(100).optional(),
});

async function handleRfq(req: Request, integration: { integration_id: string; company_id: string; scopes: string[] }, request_id: string) {
  if (!requireScope(integration, "leads:write") || !requireScope(integration, "opportunities:write")) {
    return err(403, "scope_required", "Missing required scopes: leads:write, opportunities:write", request_id);
  }
  const idempKey = req.headers.get("idempotency-key");
  const cached = await idempotencyGet(integration.integration_id, idempKey);
  if (cached) {
    return json(cached.response_status, { ...(cached.response_body as object), request_id, idempotent_replay: true });
  }
  const parsed = RfqSchema.safeParse(await req.json().catch(() => ({})));
  if (!parsed.success) {
    return err(400, "invalid_body", "Invalid request body", request_id, parsed.error.flatten());
  }
  const { company, contact, request: r, source } = parsed.data;

  // 1. upsert client by (company_id + cnpj) ou (company_id + name)
  let clientId: string | null = null;
  if (company.cnpj) {
    const { data: existing } = await admin
      .from("clients")
      .select("id")
      .eq("company_id", integration.company_id)
      .eq("cnpj", company.cnpj)
      .maybeSingle();
    if (existing) clientId = existing.id;
  }
  if (!clientId) {
    const { data: ins, error: insErr } = await admin
      .from("clients")
      .insert({
        company_id: integration.company_id,
        name: company.name,
        cnpj: company.cnpj ?? null,
        email: company.email ?? null,
        phone: company.phone ?? null,
        segment: company.segment ?? null,
        contact_person: contact.name,
        commercial_status: "prospect",
        source: source ?? "public_api",
      })
      .select("id")
      .single();
    if (insErr) return err(500, "client_create_failed", insErr.message, request_id);
    clientId = ins.id;
  }

  // 2. upsert buyer
  let buyerId: string | null = null;
  if (contact.email || contact.phone) {
    const q = admin
      .from("crm_buyers")
      .select("id")
      .eq("company_id", integration.company_id)
      .eq("client_id", clientId);
    const { data: ex } = contact.email ? await q.eq("email", contact.email).maybeSingle() : await q.eq("name", contact.name).maybeSingle();
    if (ex) buyerId = ex.id;
  }
  if (!buyerId) {
    const { data: bIns, error: bErr } = await admin
      .from("crm_buyers")
      .insert({
        company_id: integration.company_id,
        client_id: clientId,
        name: contact.name,
        email: contact.email ?? null,
        phone: contact.phone ?? null,
        role: contact.role ?? null,
        is_primary: true,
        is_active: true,
      })
      .select("id")
      .single();
    if (bErr) return err(500, "buyer_create_failed", bErr.message, request_id);
    buyerId = bIns.id;
  }

  // 3. opportunity
  const { data: opp, error: oErr } = await admin
    .from("crm_opportunities")
    .insert({
      company_id: integration.company_id,
      client_id: clientId,
      buyer_id: buyerId,
      title: r.title ?? `RFQ via ${source ?? "site"}`,
      description: r.message ?? null,
      opportunity_type: r.type,
      stage: "identified",
      priority: "medium",
      estimated_value: r.estimated_value ?? null,
      notes: source ? `origem: ${source}` : null,
    })
    .select("id, stage, created_at")
    .single();
  if (oErr) return err(500, "opportunity_create_failed", oErr.message, request_id);

  // 4. products
  if (r.products?.length) {
    await admin.from("crm_opportunity_products").insert(
      r.products.map((p) => ({
        opportunity_id: opp.id,
        product_id: p.id,
        quantity: p.quantity,
      })),
    );
  }

  // 5. activity log
  await admin.from("crm_opportunity_activities").insert({
    opportunity_id: opp.id,
    activity_type: "note",
    description: `Lead recebido via API pública${source ? ` (${source})` : ""}`,
  });

  const body = {
    data: {
      lead_id: opp.id,
      client_id: clientId,
      buyer_id: buyerId,
      stage: opp.stage,
      created_at: opp.created_at,
    },
  };
  await idempotencySave(integration.integration_id, idempKey, 201, body);
  return json(201, { ...body, request_id });
}

const ContactSchema = z.object({
  name: z.string().min(1).max(255),
  email: z.string().email().optional(),
  phone: z.string().max(50).optional(),
  company_name: z.string().max(255).optional(),
  message: z.string().max(5000).optional(),
  source: z.string().max(100).optional(),
});

async function handleContact(req: Request, integration: { integration_id: string; company_id: string; scopes: string[] }, request_id: string) {
  if (!requireScope(integration, "leads:write")) {
    return err(403, "scope_required", "Missing scope leads:write", request_id);
  }
  const parsed = ContactSchema.safeParse(await req.json().catch(() => ({})));
  if (!parsed.success) return err(400, "invalid_body", "Invalid body", request_id, parsed.error.flatten());
  const { name, email, phone, company_name, message, source } = parsed.data;

  const { data: client, error: cErr } = await admin
    .from("clients")
    .insert({
      company_id: integration.company_id,
      name: company_name ?? name,
      email: email ?? null,
      phone: phone ?? null,
      contact_person: name,
      commercial_status: "prospect",
      source: source ?? "public_api",
      notes: message ?? null,
    })
    .select("id, created_at")
    .single();
  if (cErr) return err(500, "client_create_failed", cErr.message, request_id);

  await admin.from("crm_buyers").insert({
    company_id: integration.company_id,
    client_id: client.id,
    name,
    email: email ?? null,
    phone: phone ?? null,
    is_primary: true,
    is_active: true,
  });

  return json(201, { data: { lead_id: client.id, created_at: client.created_at }, request_id });
}

async function handleGetLead(integration: { company_id: string; scopes: string[] }, id: string, request_id: string) {
  const { data, error } = await admin
    .from("crm_opportunities")
    .select("id, title, stage, priority, estimated_value, created_at, updated_at, client_id, buyer_id")
    .eq("id", id)
    .eq("company_id", integration.company_id)
    .maybeSingle();
  if (error) return err(500, "fetch_failed", error.message, request_id);
  if (!data) return err(404, "not_found", "Lead not found", request_id);
  return json(200, { data, request_id });
}

async function handleListProducts(url: URL, integration: { company_id: string; scopes: string[] }, request_id: string) {
  if (!requireScope(integration, "catalog:read")) {
    return err(403, "scope_required", "Missing scope catalog:read", request_id);
  }
  const page = Math.max(1, parseInt(url.searchParams.get("page") ?? "1"));
  const pageSize = Math.min(100, Math.max(1, parseInt(url.searchParams.get("page_size") ?? "50")));
  const category = url.searchParams.get("category");
  const type = url.searchParams.get("type");
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;

  let q = admin
    .from("crm_products")
    .select("id, name, category, type, is_recurring, reference_value, description, lead_time_days", { count: "exact" })
    .eq("company_id", integration.company_id)
    .eq("active", true)
    .order("name");
  if (category) q = q.eq("category", category);
  if (type) q = q.eq("type", type);
  const { data, error, count } = await q.range(from, to);
  if (error) return err(500, "fetch_failed", error.message, request_id);
  return json(200, {
    data,
    pagination: { page, page_size: pageSize, total: count ?? 0 },
    request_id,
  });
}

async function handleGetProduct(integration: { company_id: string; scopes: string[] }, id: string, request_id: string) {
  if (!requireScope(integration, "catalog:read")) {
    return err(403, "scope_required", "Missing scope catalog:read", request_id);
  }
  const { data, error } = await admin
    .from("crm_products")
    .select("id, name, category, type, is_recurring, reference_value, description, lead_time_days")
    .eq("id", id)
    .eq("company_id", integration.company_id)
    .eq("active", true)
    .maybeSingle();
  if (error) return err(500, "fetch_failed", error.message, request_id);
  if (!data) return err(404, "not_found", "Product not found", request_id);
  return json(200, { data, request_id });
}

async function handleListServices(url: URL, integration: { company_id: string; scopes: string[] }, request_id: string) {
  if (!requireScope(integration, "catalog:read")) {
    return err(403, "scope_required", "Missing scope catalog:read", request_id);
  }
  const { data, error } = await admin
    .from("crm_products")
    .select("id, name, category, description, lead_time_days, reference_value")
    .eq("company_id", integration.company_id)
    .eq("active", true)
    .eq("is_recurring", true)
    .order("name");
  if (error) return err(500, "fetch_failed", error.message, request_id);
  return json(200, { data, request_id });
}

// ---------- router ----------
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  const started = Date.now();
  const request_id = rid();
  const url = new URL(req.url);
  // Strip "/public-api" prefix if present
  const fnPath = url.pathname.replace(/^\/public-api/, "");
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() ?? null;
  const ua = req.headers.get("user-agent");

  let integration: { integration_id: string; company_id: string; scopes: string[] } | null = null;
  let response: Response;

  try {
    integration = await authenticate(req);
    if (!integration) {
      response = err(401, "invalid_api_key", "Missing or invalid API key", request_id);
    } else {
      const rl = rateLimit(integration.integration_id);
      if (!rl.ok) {
        response = err(429, "rate_limited", "Rate limit exceeded (120/min)", request_id);
      } else {
        // routes
        const path = fnPath.replace(/\/+$/, "");
        if (req.method === "POST" && path === "/v1/leads/rfq") {
          response = await handleRfq(req, integration, request_id);
        } else if (req.method === "POST" && path === "/v1/leads/contact") {
          response = await handleContact(req, integration, request_id);
        } else if (req.method === "GET" && path.startsWith("/v1/leads/")) {
          const id = path.split("/").pop()!;
          response = await handleGetLead(integration, id, request_id);
        } else if (req.method === "GET" && path === "/v1/catalog/products") {
          response = await handleListProducts(url, integration, request_id);
        } else if (req.method === "GET" && path.startsWith("/v1/catalog/products/")) {
          const id = path.split("/").pop()!;
          response = await handleGetProduct(integration, id, request_id);
        } else if (req.method === "GET" && path === "/v1/catalog/services") {
          response = await handleListServices(url, integration, request_id);
        } else {
          response = err(404, "not_found", `No route for ${req.method} ${path}`, request_id);
        }
      }
    }
  } catch (e) {
    response = err(500, "internal_error", (e as Error).message, request_id);
  }

  // log async (don't await response)
  const status = response.status;
  const errorBody = status >= 400 ? await response.clone().text().catch(() => null) : null;
  logRequest({
    integration_id: integration?.integration_id ?? null,
    company_id: integration?.company_id ?? null,
    method: req.method,
    path: fnPath,
    status,
    latency_ms: Date.now() - started,
    ip,
    user_agent: ua,
    error_message: errorBody?.slice(0, 500) ?? null,
  });

  return response;
});
