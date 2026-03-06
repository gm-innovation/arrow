import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    // Validate user
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const token = authHeader.replace("Bearer ", "");
    const { data: claimsData, error: claimsError } = await userClient.auth.getClaims(token);
    if (claimsError || !claimsData?.claims) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const userId = claimsData.claims.sub;

    // Get attachmentId from query
    const url = new URL(req.url);
    const attachmentId = url.searchParams.get("attachmentId");
    if (!attachmentId) {
      return new Response(JSON.stringify({ error: "attachmentId required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Use service role to fetch attachment + validate company
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    const { data: attachment, error: attErr } = await adminClient
      .from("corp_feed_attachments")
      .select("file_url, file_name, mime_type, post_id, corp_feed_posts!corp_feed_attachments_post_id_fkey(company_id)")
      .eq("id", attachmentId)
      .single();

    if (attErr || !attachment) {
      return new Response(JSON.stringify({ error: "Attachment not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const postCompanyId = (attachment as any).corp_feed_posts?.company_id;

    // Validate user belongs to the same company
    const { data: profile } = await adminClient
      .from("profiles")
      .select("company_id")
      .eq("id", userId)
      .single();

    if (!profile || profile.company_id !== postCompanyId) {
      return new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Extract storage path from file_url
    // URL format: .../storage/v1/object/public/corp-feed-media/<path>
    const fileUrl = attachment.file_url as string;
    const bucketPrefix = "/storage/v1/object/public/corp-feed-media/";
    const pathIndex = fileUrl.indexOf(bucketPrefix);
    let storagePath: string;

    if (pathIndex !== -1) {
      storagePath = decodeURIComponent(fileUrl.substring(pathIndex + bucketPrefix.length));
    } else {
      // Try to extract after the bucket name
      const parts = fileUrl.split("/corp-feed-media/");
      if (parts.length < 2) {
        return new Response(JSON.stringify({ error: "Cannot resolve storage path" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      storagePath = decodeURIComponent(parts[1]);
    }

    // Download file from storage using service role
    const { data: fileData, error: downloadError } = await adminClient.storage
      .from("corp-feed-media")
      .download(storagePath);

    if (downloadError || !fileData) {
      return new Response(JSON.stringify({ error: "Failed to download file" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const contentType = (attachment.mime_type as string) || "application/octet-stream";

    return new Response(fileData, {
      status: 200,
      headers: {
        ...corsHeaders,
        "Content-Type": contentType,
        "Content-Disposition": `inline; filename="${attachment.file_name}"`,
        "Cache-Control": "public, max-age=3600",
      },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
