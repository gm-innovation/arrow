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
  nextVisitWork?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { task_report_id, batch } = await req.json();
    
    console.log("=== generate-embeddings called ===");
    console.log("task_report_id:", task_report_id);
    console.log("batch:", batch);
    
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const lovableApiKey = Deno.env.get("LOVABLE_API_KEY")!;
    
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Function to extract actual report data from nested structure
    function extractReportData(rawData: unknown): ReportData | null {
      if (!rawData || typeof rawData !== 'object') {
        console.log("Report data is null or not an object");
        return null;
      }
      
      const data = rawData as Record<string, unknown>;
      
      // Check if data has the expected fields at top level
      if (data.reportedIssue || data.executedWork || data.result) {
        console.log("Report data is at top level");
        return data as unknown as ReportData;
      }
      
      // Otherwise, data might be nested under a task UUID key
      // Structure: { "uuid-task": { reportedIssue, executedWork, ... } }
      const keys = Object.keys(data).filter(key => key !== 'satisfaction');
      console.log("Report data keys:", keys);
      
      for (const key of keys) {
        const nested = data[key];
        if (nested && typeof nested === 'object') {
          const nestedObj = nested as Record<string, unknown>;
          if (nestedObj.reportedIssue || nestedObj.executedWork || nestedObj.result) {
            console.log(`Found report data nested under key: ${key}`);
            return nestedObj as unknown as ReportData;
          }
        }
      }
      
      console.log("Could not find report data in expected structure");
      return null;
    }

    // Function to generate embedding for a single report
    async function generateEmbeddingForReport(reportId: string) {
      console.log(`\n--- Processing report: ${reportId} ---`);
      
      // Fetch the report
      const { data: report, error: reportError } = await supabase
        .from("task_reports")
        .select("id, report_data, status, task_id")
        .eq("id", reportId)
        .single();

      if (reportError || !report) {
        console.error(`Error fetching report ${reportId}:`, reportError);
        return { success: false, reportId, error: "Report not found" };
      }

      console.log(`Report status: ${report.status}`);
      console.log(`Report task_id: ${report.task_id}`);

      // Only process approved reports
      if (report.status !== "approved") {
        console.log(`Report ${reportId} is not approved, skipping`);
        return { success: false, reportId, error: "Report not approved" };
      }

      // Extract actual report data from potentially nested structure
      const reportData = extractReportData(report.report_data);
      
      if (!reportData) {
        console.log(`Report ${reportId} has no extractable data`);
        return { success: false, reportId, error: "No extractable data" };
      }
      
      // Build content text from report data
      const contentParts = [
        reportData.reportedIssue && `Problema reportado: ${reportData.reportedIssue}`,
        reportData.executedWork && `Trabalho executado: ${reportData.executedWork}`,
        reportData.result && `Resultado: ${reportData.result}`,
        reportData.brandInfo && `Marca: ${reportData.brandInfo}`,
        reportData.modelInfo && `Modelo: ${reportData.modelInfo}`,
        reportData.serialNumber && `Número de série: ${reportData.serialNumber}`,
        reportData.observations && `Observações: ${reportData.observations}`,
        reportData.nextVisitWork && `Próxima visita: ${reportData.nextVisitWork}`,
      ].filter(Boolean);

      const contentText = contentParts.join(". ");
      console.log(`Content text length: ${contentText.length}`);
      console.log(`Content preview: ${contentText.substring(0, 200)}...`);

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

      // Generate pseudo-embedding (AI embedding generation is not reliable for this use case)
      console.log(`Generating embedding for report ${reportId}`);
      const embedding = generatePseudoEmbedding(contentText);

      // Store the embedding
      const { error: upsertError } = await supabase
        .from("report_embeddings")
        .upsert({
          task_report_id: reportId,
          embedding: `[${embedding.join(",")}]`,
          content_text: contentText.substring(0, 5000), // Limit content text size
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

    // Generate pseudo-embedding based on text features
    function generatePseudoEmbedding(text: string): number[] {
      const embedding = new Array(768).fill(0);
      const normalizedText = text.toLowerCase();
      
      // Feature extraction based on character frequencies and n-grams
      for (let i = 0; i < normalizedText.length; i++) {
        const charCode = normalizedText.charCodeAt(i);
        // Distribute character influence across embedding dimensions
        const baseIdx = i % 768;
        embedding[baseIdx] += (charCode - 96) / 26;
        
        // Add bigram features
        if (i < normalizedText.length - 1) {
          const nextCharCode = normalizedText.charCodeAt(i + 1);
          const bigramIdx = (charCode + nextCharCode) % 768;
          embedding[bigramIdx] += 0.5;
        }
      }

      // Normalize the embedding to unit length
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
      console.log("Processing batch of approved reports...");
      
      // Process multiple reports (for batch indexing)
      const { data: reports, error } = await supabase
        .from("task_reports")
        .select("id")
        .eq("status", "approved")
        .limit(50);

      if (error) {
        console.error("Error fetching reports for batch:", error);
        throw error;
      }

      console.log(`Found ${reports?.length || 0} approved reports to process`);

      const results = [];
      for (const report of reports || []) {
        const result = await generateEmbeddingForReport(report.id);
        results.push(result);
        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      const successful = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      
      console.log(`Batch complete: ${successful} successful, ${failed} failed`);

      return new Response(JSON.stringify({ 
        processed: results.length, 
        successful,
        failed,
        results 
      }), {
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
