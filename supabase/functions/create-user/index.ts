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

    const { email, password, full_name, phone, company_id, role } = await req.json();

    // Create auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name,
      },
    });

    if (authError) throw authError;
    if (!authData.user) throw new Error('Usuário não foi criado');

    // Update profile with company_id and phone
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({
        company_id,
        phone: phone || null,
      })
      .eq('id', authData.user.id);

    if (profileError) throw profileError;

    // Create user role
    const roleValue = role === 'tech' ? 'technician' : role;
    const { error: roleError } = await supabaseAdmin
      .from('user_roles')
      .insert({
        user_id: authData.user.id,
        role: roleValue,
      });

    if (roleError) throw roleError;

    // If role is tech, create technician entry
    if (role === 'tech') {
      const { error: techError } = await supabaseAdmin
        .from('technicians')
        .insert({
          user_id: authData.user.id,
          company_id,
          active: true,
        });

      if (techError) throw techError;
    }

    return new Response(
      JSON.stringify({ success: true, user_id: authData.user.id }),
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
