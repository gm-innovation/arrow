import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { historicalData } = await req.json();
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    
    if (!LOVABLE_API_KEY) {
      throw new Error("LOVABLE_API_KEY is not configured");
    }

    const systemPrompt = `Você é um analista de dados especializado em previsão de demanda para ordens de serviço.
Analise os dados históricos fornecidos e faça previsões para os próximos 3 meses.
Considere tendências sazonais, crescimento/decrescimento, e padrões mensais.
Seja preciso e baseie-se nos dados fornecidos.`;

    const userPrompt = `Analise os seguintes dados históricos de ordens de serviço e forneça previsões:

Dados históricos (últimos 12 meses):
${JSON.stringify(historicalData, null, 2)}

Por favor, analise e retorne previsões usando a função forecast_demand.`;

    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-2.5-flash",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ],
        tools: [
          {
            type: "function",
            function: {
              name: "forecast_demand",
              description: "Return demand forecast for the next 3 months with analysis",
              parameters: {
                type: "object",
                properties: {
                  predictions: {
                    type: "array",
                    items: {
                      type: "object",
                      properties: {
                        month: { type: "string", description: "Month name in Portuguese (e.g., Janeiro, Fevereiro)" },
                        predicted_orders: { type: "number", description: "Predicted number of orders" },
                        confidence: { type: "string", enum: ["alta", "média", "baixa"], description: "Confidence level" },
                        predicted_completed: { type: "number", description: "Predicted completed orders" }
                      },
                      required: ["month", "predicted_orders", "confidence", "predicted_completed"]
                    }
                  },
                  trend_analysis: {
                    type: "string",
                    description: "Brief analysis of the trend in Portuguese (max 100 words)"
                  },
                  growth_rate: {
                    type: "number",
                    description: "Expected growth rate percentage for the next quarter"
                  },
                  recommendations: {
                    type: "array",
                    items: { type: "string" },
                    description: "3 actionable recommendations in Portuguese based on the forecast"
                  }
                },
                required: ["predictions", "trend_analysis", "growth_rate", "recommendations"]
              }
            }
          }
        ],
        tool_choice: { type: "function", function: { name: "forecast_demand" } }
      }),
    });

    if (!response.ok) {
      if (response.status === 429) {
        return new Response(JSON.stringify({ error: "Rate limit exceeded. Please try again later." }), {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (response.status === 402) {
        return new Response(JSON.stringify({ error: "Payment required. Please add credits to your workspace." }), {
          status: 402,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const errorText = await response.text();
      console.error("AI gateway error:", response.status, errorText);
      throw new Error(`AI gateway error: ${response.status}`);
    }

    const data = await response.json();
    const toolCall = data.choices?.[0]?.message?.tool_calls?.[0];
    
    if (!toolCall?.function?.arguments) {
      throw new Error("No forecast data returned from AI");
    }

    const forecast = JSON.parse(toolCall.function.arguments);

    return new Response(JSON.stringify(forecast), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Demand forecast error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unknown error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
