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

    console.log('Creating user with email:', email);

    // Create auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name,
      },
    });

    if (authError) {
      console.error('Auth error:', authError);
      throw authError;
    }
    if (!authData.user) {
      console.error('No user data returned');
      throw new Error('Usuário não foi criado');
    }

    console.log('User created, ID:', authData.user.id);

    // Wait a bit for the trigger to create the profile
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Update profile with company_id and phone (profile should exist from trigger)
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({
        company_id,
        phone: phone || null,
      })
      .eq('id', authData.user.id);

    if (profileError) {
      console.error('Profile error:', profileError);
      throw profileError;
    }

    console.log('Profile updated');

    // Create user role
    const roleValue = role === 'tech' ? 'technician' : role;
    const { error: roleError } = await supabaseAdmin
      .from('user_roles')
      .insert({
        user_id: authData.user.id,
        role: roleValue,
      });

    if (roleError) {
      console.error('Role error:', roleError);
      throw roleError;
    }

    console.log('Role created:', roleValue);

    // If role is tech, create technician entry
    if (role === 'tech') {
      const { error: techError } = await supabaseAdmin
        .from('technicians')
        .insert({
          user_id: authData.user.id,
          company_id,
          active: true,
        });

      if (techError) {
        console.error('Technician error:', techError);
        throw techError;
      }

      console.log('Technician entry created');
    }

    console.log('User creation completed successfully');

    return new Response(
      JSON.stringify({ success: true, user_id: authData.user.id }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Function error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
