// Public access to a Quality document via a signed token.
// verify_jwt = false — validated per-request via the token in the URL.
import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const url = new URL(req.url);
    const token = url.searchParams.get('token');
    if (!token) return json({ error: 'missing_token' }, 400);

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 1. Look up link
    const { data: link, error: linkErr } = await supabase
      .from('quality_document_public_links')
      .select('*')
      .eq('token', token)
      .maybeSingle();

    if (linkErr) return json({ error: 'lookup_failed', detail: linkErr.message }, 500);
    if (!link) return json({ error: 'invalid_token' }, 404);
    if (link.revoked_at) return json({ error: 'revoked' }, 403);
    if (new Date(link.expires_at).getTime() < Date.now())
      return json({ error: 'expired' }, 403);
    if (link.max_uses != null && link.access_count >= link.max_uses)
      return json({ error: 'limit_reached' }, 403);

    // 2. Load document
    const { data: doc, error: docErr } = await supabase
      .from('quality_documents')
      .select(
        'id, code, title, status, current_version_id, control_mode, next_review_date, published_at',
      )
      .eq('id', link.document_id)
      .maybeSingle();

    if (docErr) return json({ error: 'doc_lookup_failed', detail: docErr.message }, 500);
    if (!doc) return json({ error: 'document_missing' }, 404);
    if (doc.status === 'obsolete' || doc.status === 'archived')
      return json({ error: 'document_unavailable' }, 403);

    // 3. Load current version
    let signedUrl: string | null = null;
    let versionInfo: any = null;
    if (doc.current_version_id) {
      const { data: version } = await supabase
        .from('quality_document_versions')
        .select('id, revision_label, file_path, file_name, file_mime, content_kind, rich_content')
        .eq('id', doc.current_version_id)
        .maybeSingle();
      versionInfo = version;
      if (version?.file_path) {
        const { data: signed } = await supabase.storage
          .from('quality-documents')
          .createSignedUrl(version.file_path, 300);
        signedUrl = signed?.signedUrl ?? null;
      }
    }

    // 4. Increment counter + log access (best-effort)
    await supabase
      .from('quality_document_public_links')
      .update({ access_count: (link.access_count ?? 0) + 1 })
      .eq('id', link.id);

    const ip = req.headers.get('x-forwarded-for') || req.headers.get('cf-connecting-ip') || null;
    const ua = req.headers.get('user-agent') || null;
    await supabase.from('quality_document_access_log').insert({
      document_id: doc.id,
      version_id: doc.current_version_id,
      user_id: null,
      action: 'public_view',
      ip_address: ip,
      user_agent: ua,
    } as any);


    return json({
      document: {
        id: doc.id,
        code: doc.code,
        title: doc.title,
        status: doc.status,
        control_mode: doc.control_mode,
        next_review_date: doc.next_review_date,
        published_at: doc.published_at,
      },
      version: versionInfo
        ? {
            id: versionInfo.id,
            revision_label: versionInfo.revision_label,
            file_name: versionInfo.file_name,
            file_mime: versionInfo.file_mime,
            content_kind: versionInfo.content_kind,
            rich_content: versionInfo.rich_content,
          }
        : null,
      signed_url: signedUrl,
      link: {
        expires_at: link.expires_at,
        access_count: (link.access_count ?? 0) + 1,
        max_uses: link.max_uses,
      },
    });
  } catch (e: any) {
    return json({ error: 'unexpected', detail: String(e?.message ?? e) }, 500);
  }
});
