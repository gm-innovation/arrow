import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { query, company_id, match_count = 10, match_threshold = 0.3 } = await req.json();

    if (!query || query.trim().length < 3) {
      return new Response(JSON.stringify({ error: "Query deve ter pelo menos 3 caracteres" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const lovableApiKey = Deno.env.get("LOVABLE_API_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseKey);

    console.log(`Searching for: "${query}" in company: ${company_id || 'all'}`);

    // Generate embedding for the query using the same method as generate-embeddings
    let queryEmbedding: number[];
    
    try {
      const embeddingResponse = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${lovableApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "google/gemini-2.5-flash-lite",
          messages: [
            {
              role: "system",
              content: "Você é um sistema de indexação. Crie uma representação vetorial do texto fornecido retornando APENAS um array JSON de 768 números decimais entre -1 e 1, representando o embedding semântico do conteúdo. Não inclua nenhum texto adicional."
            },
            {
              role: "user",
              content: query
            }
          ],
        }),
      });

      if (!embeddingResponse.ok) {
        console.log("AI embedding failed, using fallback");
        queryEmbedding = generatePseudoEmbedding(query);
      } else {
        const responseData = await embeddingResponse.json();
        const responseContent = responseData.choices?.[0]?.message?.content;
        
        try {
          queryEmbedding = JSON.parse(responseContent);
          if (!Array.isArray(queryEmbedding) || queryEmbedding.length !== 768) {
            throw new Error("Invalid embedding format");
          }
        } catch {
          console.log("Could not parse AI embedding, using fallback");
          queryEmbedding = generatePseudoEmbedding(query);
        }
      }
    } catch (error) {
      console.error("Error generating embedding:", error);
      queryEmbedding = generatePseudoEmbedding(query);
    }

    // Call the search_similar_reports function
    const { data: results, error: searchError } = await supabase.rpc('search_similar_reports', {
      query_embedding: `[${queryEmbedding.join(",")}]`,
      match_threshold: match_threshold,
      match_count: match_count,
      p_company_id: company_id || null
    });

    if (searchError) {
      console.error("Search error:", searchError);
      throw searchError;
    }

    console.log(`Found ${results?.length || 0} results`);

    // Enrich results with additional data
    const enrichedResults = await Promise.all(
      (results || []).map(async (result: any) => {
        const { data: report } = await supabase
          .from('task_reports')
          .select(`
            id,
            task_id,
            status,
            created_at,
            task:tasks!task_reports_task_uuid_fkey (
              title,
              service_order:service_orders (
                order_number,
                vessel:vessels (name),
                client:clients (name)
              )
            )
          `)
          .eq('id', result.task_report_id)
          .single();

        return {
          ...result,
          report_details: report
        };
      })
    );

    return new Response(JSON.stringify({ results: enrichedResults }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Error in search-reports:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// Generate pseudo-embedding based on text features (same as generate-embeddings)
function generatePseudoEmbedding(text: string): number[] {
  const embedding = new Array(768).fill(0);
  const normalizedText = text.toLowerCase();
  
  for (let i = 0; i < normalizedText.length && i < 768; i++) {
    const charCode = normalizedText.charCodeAt(i);
    embedding[i % 768] += (charCode - 96) / 26;
  }

  const magnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
  if (magnitude > 0) {
    for (let i = 0; i < 768; i++) {
      embedding[i] = embedding[i] / magnitude;
    }
  }

  return embedding;
}
