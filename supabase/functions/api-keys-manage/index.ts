// API Key management — create/list/revoke.
// Auth: JWT (director ou super_admin).
import { createClient } from "npm:@supabase/supabase-js@2";
import { z } from "npm:zod@3.23.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(SUPABASE_URL, SERVICE, { auth: { persistSession: false } });

const ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
function generateKey(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  let s = "";
  for (const b of bytes) s += ALPHABET[b % ALPHABET.length];
  return `ark_live_${s}`;
}
async function sha256Hex(input: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

const CreateSchema = z.object({
  company_id: z.string().uuid(),
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  scopes: z.array(z.string()).min(1),
});

const VALID_SCOPES = new Set([
  "leads:write",
  "opportunities:write",
  "catalog:read",
  "crm:read",
  "sales:read",
]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
  const userClient = createClient(SUPABASE_URL, ANON, { global: { headers: { Authorization: auth } } });
  const token = auth.replace("Bearer ", "");
  const { data: claims } = await userClient.auth.getClaims(token);
  if (!claims?.claims) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
  const userId = claims.claims.sub as string;

  // role check — exclusivo super_admin
  const { data: roles } = await admin.from("user_roles").select("role").eq("user_id", userId);
  const roleSet = new Set((roles ?? []).map((r) => r.role));
  if (!roleSet.has("super_admin")) {
    return new Response(JSON.stringify({ error: "Forbidden: super_admin only" }), { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/api-keys-manage/, "").replace(/\/+$/, "");

  try {
    if (req.method === "POST" && (path === "" || path === "/")) {
      const parsed = CreateSchema.safeParse(await req.json().catch(() => ({})));
      if (!parsed.success) {
        return new Response(JSON.stringify({ error: parsed.error.flatten() }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
      }
      const invalid = parsed.data.scopes.filter((s) => !VALID_SCOPES.has(s));
      if (invalid.length) {
        return new Response(JSON.stringify({ error: `invalid scopes: ${invalid.join(", ")}` }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
      }
      // valida company existente
      const { data: companyRow } = await admin.from("companies").select("id").eq("id", parsed.data.company_id).maybeSingle();
      if (!companyRow) {
        return new Response(JSON.stringify({ error: "Empresa não encontrada" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
      }
      const key = generateKey();
      const key_hash = await sha256Hex(key);
      const key_prefix = key.slice(0, 17);
      const { data, error } = await admin.from("api_integrations").insert({
        company_id: parsed.data.company_id,
        name: parsed.data.name,
        description: parsed.data.description ?? null,
        key_hash,
        key_prefix,
        scopes: parsed.data.scopes,
        created_by: userId,
      }).select("id, name, key_prefix, scopes, status, created_at").single();
      if (error) throw error;
      return new Response(JSON.stringify({ integration: data, api_key: key }), {
        status: 201,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (req.method === "DELETE" && path.startsWith("/")) {
      const id = path.slice(1);
      const { error } = await admin.from("api_integrations").update({ status: "revoked" }).eq("id", id);
      if (error) throw error;
      return new Response(JSON.stringify({ ok: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "not found" }), { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
