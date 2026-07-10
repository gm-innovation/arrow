// HMAC-signed confirmation token for destructive AI assistant actions.
// Token binds {userId, table, rowId, exp} — no DB state.

const encoder = new TextEncoder();

function b64url(bytes: Uint8Array): string {
  let s = btoa(String.fromCharCode(...bytes));
  return s.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function b64urlDecode(s: string): Uint8Array {
  s = s.replace(/-/g, "+").replace(/_/g, "/");
  while (s.length % 4) s += "=";
  const bin = atob(s);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function hmac(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", key, encoder.encode(payload)));
  return b64url(sig);
}

function getSecret(): string {
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
      ?? Deno.env.get("SUPABASE_JWT_SECRET")
      ?? "fallback-please-set-service-role-key";
}

export interface ConfirmPayload {
  u: string;         // user id
  t: string;         // table
  r: string;         // row id
  exp: number;       // unix ms
}

export async function signConfirmToken(p: Omit<ConfirmPayload, "exp"> & { ttlMs?: number }): Promise<string> {
  const payload: ConfirmPayload = {
    u: p.u, t: p.t, r: p.r,
    exp: Date.now() + (p.ttlMs ?? 120_000),
  };
  const body = b64url(encoder.encode(JSON.stringify(payload)));
  const sig = await hmac(getSecret(), body);
  return `del.${body}.${sig}`;
}

export async function verifyConfirmToken(
  token: string,
  expected: { u: string; t: string; r: string },
): Promise<{ ok: true } | { ok: false; reason: string }> {
  if (!token?.startsWith("del.")) return { ok: false, reason: "formato inválido" };
  const parts = token.split(".");
  if (parts.length !== 3) return { ok: false, reason: "formato inválido" };
  const [, body, sig] = parts;
  const expectedSig = await hmac(getSecret(), body);
  if (sig !== expectedSig) return { ok: false, reason: "assinatura inválida" };
  let payload: ConfirmPayload;
  try { payload = JSON.parse(new TextDecoder().decode(b64urlDecode(body))); }
  catch { return { ok: false, reason: "payload corrompido" }; }
  if (payload.exp < Date.now()) return { ok: false, reason: "token expirado" };
  if (payload.u !== expected.u) return { ok: false, reason: "usuário divergente" };
  if (payload.t !== expected.t) return { ok: false, reason: "tabela divergente" };
  if (payload.r !== expected.r) return { ok: false, reason: "registro divergente" };
  return { ok: true };
}
