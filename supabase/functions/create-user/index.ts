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
    // Get the authorization header from the request
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      console.error('No authorization header provided');
      return new Response(
        JSON.stringify({ error: 'Não autorizado - token não fornecido' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      );
    }

    // Create a client with the user's JWT to verify their identity and permissions
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    // Verify the calling user's identity
    const { data: { user: callerUser }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !callerUser) {
      console.error('Auth verification failed:', authError);
      return new Response(
        JSON.stringify({ error: 'Não autorizado - token inválido' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      );
    }

    console.log('Caller authenticated:', callerUser.id);

    // Create admin client for privileged operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get the caller's role and company
    const { data: callerRoleData, error: callerRoleError } = await supabaseAdmin
      .from('user_roles')
      .select('role')
      .eq('user_id', callerUser.id)
      .single();

    if (callerRoleError || !callerRoleData) {
      console.error('Could not fetch caller role:', callerRoleError);
      return new Response(
        JSON.stringify({ error: 'Não foi possível verificar permissões do usuário' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
      );
    }

    const callerRole = callerRoleData.role;
    console.log('Caller role:', callerRole);

    // Only super_admin, hr and director can create users
    if (callerRole !== 'super_admin' && callerRole !== 'hr' && callerRole !== 'director') {
      console.error('Unauthorized role attempted to create user:', callerRole);
      return new Response(
        JSON.stringify({ error: 'Permissão negada - apenas RH, diretores e super admins podem criar usuários' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
      );
    }

    const { email, password, full_name, phone, company_id, role } = await req.json();

    // Validate required fields
    if (!email || !password || !full_name || !company_id || !role) {
      return new Response(
        JSON.stringify({ error: 'Campos obrigatórios não fornecidos' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      );
    }

    // Role-based authorization checks
    const allowedRoles = ['technician', 'coordinator', 'manager', 'hr', 'commercial', 'director', 'compras', 'qualidade', 'financeiro'];
    
    // Admin and HR can only create users in their own company
    if (callerRole === 'coordinator' || callerRole === 'hr') {
      // Get caller's company
      const { data: callerProfile, error: callerProfileError } = await supabaseAdmin
        .from('profiles')
        .select('company_id')
        .eq('id', callerUser.id)
        .single();

      if (callerProfileError || !callerProfile) {
        console.error('Could not fetch caller profile:', callerProfileError);
        return new Response(
          JSON.stringify({ error: 'Não foi possível verificar empresa do usuário' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
        );
      }

      if (company_id !== callerProfile.company_id) {
        console.error(`${callerRole} tried to create user in different company`);
        return new Response(
          JSON.stringify({ error: 'Permissão negada - você só pode criar usuários na sua empresa' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
        );
      }
      
      // Coordinator cannot create super_admin
      if (callerRole === 'coordinator' && role === 'super_admin') {
        console.error('Coordinator tried to create super_admin');
        return new Response(
          JSON.stringify({ error: 'Permissão negada - você não pode criar super administradores' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
        );
      }
      
      // HR can only create technicians
      if (callerRole === 'hr' && role !== 'technician') {
        console.error('HR tried to create non-technician user:', role);
        return new Response(
          JSON.stringify({ error: 'Permissão negada - RH só pode criar técnicos' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
        );
      }
    }

    // Super admin can create users in any company but validate role
    if (callerRole === 'super_admin') {
      allowedRoles.push('super_admin');
    }

    if (!allowedRoles.includes(role)) {
      console.error('Invalid role requested:', role);
      return new Response(
        JSON.stringify({ error: `Função inválida: ${role}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      );
    }

    console.log('Creating user with email:', email, 'in company:', company_id, 'with role:', role);

    // Create auth user
    const { data: authData, error: createAuthError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name,
      },
    });

    if (createAuthError) {
      console.error('Auth error:', createAuthError);
      throw createAuthError;
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
    const { error: roleError } = await supabaseAdmin
      .from('user_roles')
      .insert({
        user_id: authData.user.id,
        role: role,
      });

    if (roleError) {
      console.error('Role error:', roleError);
      throw roleError;
    }

    console.log('Role created:', role);

    // If role is technician, create technician entry
    if (role === 'technician') {
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

    // Note: manager and admin roles don't need additional table entries
    console.log('User type:', role, '- no additional setup needed');

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
