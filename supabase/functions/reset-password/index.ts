import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    const supabaseAuth = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user: caller }, error: callerError } = await supabaseAuth.auth.getUser();
    if (callerError || !caller) {
      throw new Error('Unauthorized: Could not verify caller identity');
    }

    const callerId = caller.id;

    // Get caller role
    const { data: callerRoleData, error: callerRoleError } = await supabaseAdmin
      .from('user_roles')
      .select('role')
      .eq('user_id', callerId)
      .single();

    if (callerRoleError || !callerRoleData) {
      throw new Error('Unauthorized: Caller role not found');
    }

    const callerRole = callerRoleData.role;

    // Only super_admin, hr, and director can reset passwords
    const authorizedRoles = ['super_admin', 'hr', 'director'];
    if (!authorizedRoles.includes(callerRole)) {
      throw new Error('Forbidden: Only super admins, HR and directors can reset passwords');
    }

    const { user_id, new_password } = await req.json();

    if (!user_id || !new_password) {
      throw new Error('user_id and new_password are required');
    }

    if (new_password.length < 8) {
      throw new Error('Password must be at least 8 characters');
    }

    // Get target user's role
    const { data: targetRoleData } = await supabaseAdmin
      .from('user_roles')
      .select('role')
      .eq('user_id', user_id)
      .single();

    const targetRole = targetRoleData?.role;

    // Only super_admin can reset another super_admin's password
    if (targetRole === 'super_admin' && callerRole !== 'super_admin') {
      throw new Error('Forbidden: Only super_admins can reset super_admin passwords');
    }

    // Non-super_admin must be in the same company
    if (callerRole !== 'super_admin') {
      const { data: callerProfile } = await supabaseAdmin
        .from('profiles')
        .select('company_id')
        .eq('id', callerId)
        .single();

      const { data: targetProfile } = await supabaseAdmin
        .from('profiles')
        .select('company_id')
        .eq('id', user_id)
        .single();

      if (!callerProfile?.company_id || !targetProfile?.company_id ||
          callerProfile.company_id !== targetProfile.company_id) {
        throw new Error('Forbidden: Can only reset passwords for users in your own company');
      }
    }

    // Reset the password
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(user_id, {
      password: new_password,
    });

    if (updateError) throw updateError;

    console.log(`User ${callerId} (${callerRole}) reset password for user ${user_id}`);

    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Reset password error:', error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
