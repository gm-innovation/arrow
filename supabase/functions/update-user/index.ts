import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { user_id, full_name, phone, company_id, role } = await req.json();

    // Update profile
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({
        full_name,
        phone: phone || null,
        company_id,
      })
      .eq('id', user_id);

    if (profileError) throw profileError;

    // Update role if provided
    if (role) {
      // Delete existing roles
      await supabaseAdmin
        .from('user_roles')
        .delete()
        .eq('user_id', user_id);

      // Insert new role
      const roleValue = role === 'tech' ? 'technician' : role;
      const { error: roleError } = await supabaseAdmin
        .from('user_roles')
        .insert({
          user_id,
          role: roleValue,
        });

      if (roleError) throw roleError;

      // Handle technician entry
      if (role === 'tech') {
        // Check if technician entry exists
        const { data: existingTech } = await supabaseAdmin
          .from('technicians')
          .select('id')
          .eq('user_id', user_id)
          .maybeSingle();

        if (!existingTech && company_id) {
          await supabaseAdmin
            .from('technicians')
            .insert({
              user_id,
              company_id,
              active: true,
            });
        }
      } else {
        // Remove technician entry if role is not tech
        await supabaseAdmin
          .from('technicians')
          .delete()
          .eq('user_id', user_id);
      }
    }

    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
