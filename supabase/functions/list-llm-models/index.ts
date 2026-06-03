import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { LOVABLE_MODELS, fetchOpenRouterModels } from "../_shared/llm.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const provider = url.searchParams.get("provider") ?? "lovable";

    if (provider === "lovable") {
      return new Response(
        JSON.stringify({ provider: "lovable", models: LOVABLE_MODELS }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (provider === "openrouter") {
      try {
        const models = await fetchOpenRouterModels();
        return new Response(
          JSON.stringify({ provider: "openrouter", models }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      } catch (e) {
        return new Response(
          JSON.stringify({ provider: "openrouter", models: [], error: (e as Error).message }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
    }

    return new Response(JSON.stringify({ error: "Provider inválido" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("list-llm-models error:", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
