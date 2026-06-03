// Shared LLM dispatcher for Lovable AI Gateway and OpenRouter.
// Use from any edge function:
//   import { callLLM, LLMProvider } from "../_shared/llm.ts";

export type LLMProvider = "lovable" | "openrouter";

export interface CallLLMOptions {
  provider?: LLMProvider;
  model: string;
  messages: any[];
  tools?: any[];
  tool_choice?: any;
  stream?: boolean;
  temperature?: number;
  max_tokens?: number;
  // OpenRouter-specific
  openrouter_route?: string; // "fallback" | "lowest-cost" | "fastest"
  openrouter_providers?: string[]; // allowed provider slugs
  // Used for OpenRouter analytics headers
  referer?: string;
  title?: string;
}

export interface CallLLMResult {
  ok: boolean;
  status: number;
  response: Response;
}

const LOVABLE_URL = "https://ai.gateway.lovable.dev/v1/chat/completions";
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

export async function callLLM(opts: CallLLMOptions): Promise<CallLLMResult> {
  const provider: LLMProvider = opts.provider ?? "lovable";

  const body: any = {
    model: opts.model,
    messages: opts.messages,
  };
  if (opts.tools) body.tools = opts.tools;
  if (opts.tool_choice) body.tool_choice = opts.tool_choice;
  if (typeof opts.stream === "boolean") body.stream = opts.stream;
  if (typeof opts.temperature === "number") body.temperature = opts.temperature;
  if (typeof opts.max_tokens === "number") body.max_tokens = opts.max_tokens;

  let url: string;
  const headers: Record<string, string> = { "Content-Type": "application/json" };

  if (provider === "openrouter") {
    const key = Deno.env.get("OPENROUTER_API_KEY");
    if (!key) {
      const r = new Response(
        JSON.stringify({ error: "OPENROUTER_API_KEY não configurada. Adicione o secret para usar OpenRouter." }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
      return { ok: false, status: 400, response: r };
    }
    url = OPENROUTER_URL;
    headers["Authorization"] = `Bearer ${key}`;
    headers["HTTP-Referer"] = opts.referer ?? "https://lovable.app";
    headers["X-Title"] = opts.title ?? "Lovable AI Agent";
    if (opts.openrouter_route || opts.openrouter_providers?.length) {
      body.provider = {
        ...(opts.openrouter_route ? { sort: opts.openrouter_route } : {}),
        ...(opts.openrouter_providers?.length ? { order: opts.openrouter_providers, allow_fallbacks: true } : {}),
      };
    }
  } else {
    const key = Deno.env.get("LOVABLE_API_KEY");
    if (!key) {
      const r = new Response(
        JSON.stringify({ error: "LOVABLE_API_KEY não configurada." }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
      return { ok: false, status: 500, response: r };
    }
    url = LOVABLE_URL;
    headers["Authorization"] = `Bearer ${key}`;
  }

  const response = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });

  return { ok: response.ok, status: response.status, response };
}

// Curated Lovable AI Gateway model list (mirrors AI Gateway catalog).
export const LOVABLE_MODELS = [
  { id: "google/gemini-3-flash-preview", name: "Gemini 3 Flash Preview", context: 1000000 },
  { id: "google/gemini-3.5-flash", name: "Gemini 3.5 Flash", context: 1000000 },
  { id: "google/gemini-3.1-pro-preview", name: "Gemini 3.1 Pro Preview", context: 1000000 },
  { id: "google/gemini-3.1-flash-lite-preview", name: "Gemini 3.1 Flash Lite", context: 1000000 },
  { id: "google/gemini-2.5-pro", name: "Gemini 2.5 Pro", context: 2000000 },
  { id: "google/gemini-2.5-flash", name: "Gemini 2.5 Flash", context: 1000000 },
  { id: "google/gemini-2.5-flash-lite", name: "Gemini 2.5 Flash Lite", context: 1000000 },
  { id: "openai/gpt-5", name: "GPT-5", context: 400000 },
  { id: "openai/gpt-5-mini", name: "GPT-5 Mini", context: 400000 },
  { id: "openai/gpt-5-nano", name: "GPT-5 Nano", context: 400000 },
  { id: "openai/gpt-5.2", name: "GPT-5.2", context: 400000 },
  { id: "openai/gpt-5.4", name: "GPT-5.4", context: 400000 },
  { id: "openai/gpt-5.4-mini", name: "GPT-5.4 Mini", context: 400000 },
  { id: "openai/gpt-5.4-pro", name: "GPT-5.4 Pro", context: 400000 },
  { id: "openai/gpt-5.5", name: "GPT-5.5", context: 400000 },
  { id: "openai/gpt-5.5-pro", name: "GPT-5.5 Pro", context: 400000 },
];

// In-memory cache for OpenRouter catalog
let openrouterCache: { ts: number; data: any[] } | null = null;
const OPENROUTER_TTL = 60 * 60 * 1000; // 1h

export async function fetchOpenRouterModels(): Promise<any[]> {
  if (openrouterCache && Date.now() - openrouterCache.ts < OPENROUTER_TTL) {
    return openrouterCache.data;
  }
  const key = Deno.env.get("OPENROUTER_API_KEY");
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (key) headers["Authorization"] = `Bearer ${key}`;
  const r = await fetch("https://openrouter.ai/api/v1/models", { headers });
  if (!r.ok) throw new Error(`OpenRouter models fetch failed: ${r.status}`);
  const json = await r.json();
  const models = (json.data ?? []).map((m: any) => ({
    id: m.id,
    name: m.name ?? m.id,
    context: m.context_length ?? 0,
    input_price: parseFloat(m.pricing?.prompt ?? "0"),
    output_price: parseFloat(m.pricing?.completion ?? "0"),
    modality: m.architecture?.modality ?? "text",
  }));
  openrouterCache = { ts: Date.now(), data: models };
  return models;
}
