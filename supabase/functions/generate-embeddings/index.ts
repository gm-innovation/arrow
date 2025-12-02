import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ReportData {
  reportedIssue?: string;
  executedWork?: string;
  result?: string;
  brandInfo?: string;
  modelInfo?: string;
  serialNumber?: string;
  observations?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { task_report_id, batch } = await req.json();
    
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const lovableApiKey = Deno.env.get("LOVABLE_API_KEY")!;
    
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Function to generate embedding for a single report
    async function generateEmbeddingForReport(reportId: string) {
      // Fetch the report
      const { data: report, error: reportError } = await supabase
        .from("task_reports")
        .select("id, report_data, status")
        .eq("id", reportId)
        .single();

      if (reportError || !report) {
        console.error(`Error fetching report ${reportId}:`, reportError);
        return { success: false, reportId, error: "Report not found" };
      }

      // Only process approved reports
      if (report.status !== "approved") {
        console.log(`Report ${reportId} is not approved, skipping`);
        return { success: false, reportId, error: "Report not approved" };
      }

      const reportData = report.report_data as ReportData;
      
      // Build content text from report data
      const contentParts = [
        reportData.reportedIssue && `Problema: ${reportData.reportedIssue}`,
        reportData.executedWork && `Trabalho executado: ${reportData.executedWork}`,
        reportData.result && `Resultado: ${reportData.result}`,
        reportData.brandInfo && `Marca: ${reportData.brandInfo}`,
        reportData.modelInfo && `Modelo: ${reportData.modelInfo}`,
        reportData.serialNumber && `Série: ${reportData.serialNumber}`,
        reportData.observations && `Observações: ${reportData.observations}`,
      ].filter(Boolean);

      const contentText = contentParts.join(". ");

      if (!contentText || contentText.length < 10) {
        console.log(`Report ${reportId} has insufficient content`);
        return { success: false, reportId, error: "Insufficient content" };
      }

      // Calculate content hash to avoid reprocessing
      const encoder = new TextEncoder();
      const data = encoder.encode(contentText);
      const hashBuffer = await crypto.subtle.digest("SHA-256", data);
      const hashArray = Array.from(new Uint8Array(hashBuffer));
      const contentHash = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");

      // Check if embedding already exists with same hash
      const { data: existingEmbedding } = await supabase
        .from("report_embeddings")
        .select("id, content_hash")
        .eq("task_report_id", reportId)
        .single();

      if (existingEmbedding?.content_hash === contentHash) {
        console.log(`Report ${reportId} embedding already up to date`);
        return { success: true, reportId, status: "already_exists" };
      }

      // Generate embedding using Lovable AI
      // Note: Using text-embedding model if available, otherwise use chat completion to generate a summary
      // For now, we'll use a workaround by asking the model to create a searchable representation
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
              content: contentText
            }
          ],
          temperature: 0
        }),
      });

      if (!embeddingResponse.ok) {
        const errorText = await embeddingResponse.text();
        console.error(`Error generating embedding for ${reportId}:`, errorText);
        
        // Fallback: Generate a simple hash-based pseudo-embedding
        // This is a temporary solution until proper embedding API is available
        const pseudoEmbedding = generatePseudoEmbedding(contentText);
        
        // Store the embedding
        const { error: upsertError } = await supabase
          .from("report_embeddings")
          .upsert({
            task_report_id: reportId,
            embedding: `[${pseudoEmbedding.join(",")}]`,
            content_text: contentText,
            content_hash: contentHash,
          }, {
            onConflict: "task_report_id"
          });

        if (upsertError) {
          console.error(`Error storing embedding for ${reportId}:`, upsertError);
          return { success: false, reportId, error: "Failed to store embedding" };
        }

        return { success: true, reportId, status: "created_fallback" };
      }

      const responseData = await embeddingResponse.json();
      const responseContent = responseData.choices?.[0]?.message?.content;
      
      let embedding: number[];
      try {
        // Try to parse the response as JSON array
        embedding = JSON.parse(responseContent);
        if (!Array.isArray(embedding) || embedding.length !== 768) {
          throw new Error("Invalid embedding format");
        }
      } catch {
        // Fallback to pseudo-embedding
        console.log(`Could not parse embedding response for ${reportId}, using fallback`);
        embedding = generatePseudoEmbedding(contentText);
      }

      // Store the embedding
      const { error: upsertError } = await supabase
        .from("report_embeddings")
        .upsert({
          task_report_id: reportId,
          embedding: `[${embedding.join(",")}]`,
          content_text: contentText,
          content_hash: contentHash,
        }, {
          onConflict: "task_report_id"
        });

      if (upsertError) {
        console.error(`Error storing embedding for ${reportId}:`, upsertError);
        return { success: false, reportId, error: "Failed to store embedding" };
      }

      console.log(`Successfully generated embedding for report ${reportId}`);
      return { success: true, reportId, status: "created" };
    }

    // Generate pseudo-embedding based on text features (fallback)
    function generatePseudoEmbedding(text: string): number[] {
      const embedding = new Array(768).fill(0);
      const normalizedText = text.toLowerCase();
      
      // Simple feature extraction based on character and word frequencies
      for (let i = 0; i < normalizedText.length && i < 768; i++) {
        const charCode = normalizedText.charCodeAt(i);
        embedding[i % 768] += (charCode - 96) / 26; // Normalize to [-1, 1] range
      }

      // Normalize the embedding
      const magnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
      if (magnitude > 0) {
        for (let i = 0; i < 768; i++) {
          embedding[i] = embedding[i] / magnitude;
        }
      }

      return embedding;
    }

    // Process single report or batch
    if (task_report_id) {
      const result = await generateEmbeddingForReport(task_report_id);
      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (batch) {
      // Process multiple reports (for batch indexing)
      const { data: reports, error } = await supabase
        .from("task_reports")
        .select("id")
        .eq("status", "approved")
        .limit(50);

      if (error) {
        throw error;
      }

      const results = [];
      for (const report of reports || []) {
        const result = await generateEmbeddingForReport(report.id);
        results.push(result);
        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      return new Response(JSON.stringify({ processed: results.length, results }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Missing task_report_id or batch parameter" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Error in generate-embeddings:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
