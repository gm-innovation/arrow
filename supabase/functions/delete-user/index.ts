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
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

    // Create admin client for privileged operations
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Get the authorization header to identify the caller
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    // Create a client with the caller's JWT to get their identity
    const supabaseAuth = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    });

    // Get the caller's user info
    const { data: { user: caller }, error: callerError } = await supabaseAuth.auth.getUser();
    if (callerError || !caller) {
      throw new Error('Unauthorized: Could not verify caller identity');
    }

    const callerId = caller.id;

    // Get the caller's role
    const { data: callerRoleData, error: callerRoleError } = await supabaseAdmin
      .from('user_roles')
      .select('role')
      .eq('user_id', callerId)
      .single();

    if (callerRoleError || !callerRoleData) {
      throw new Error('Unauthorized: Caller role not found');
    }

    const callerRole = callerRoleData.role;

    // Allow super_admin, hr, and director to delete users
    if (callerRole !== 'super_admin' && callerRole !== 'hr' && callerRole !== 'director') {
      throw new Error('Forbidden: Only HR, directors and super admins can delete users');
    }

    const { user_id } = await req.json();

    if (!user_id) {
      throw new Error('user_id is required');
    }

    // Prevent self-deletion
    if (user_id === callerId) {
      throw new Error('Forbidden: Cannot delete your own account');
    }

    // Get the target user's role and company
    const { data: targetRoleData } = await supabaseAdmin
      .from('user_roles')
      .select('role')
      .eq('user_id', user_id)
      .single();

    const targetRole = targetRoleData?.role;

    // Prevent non-super_admins from deleting super_admins
    if (targetRole === 'super_admin' && callerRole !== 'super_admin') {
      throw new Error('Forbidden: Only super_admins can delete super_admins');
    }

    // If caller is hr or director (not super_admin), verify target is in the same company
    if (callerRole === 'hr' || callerRole === 'director') {
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

      if (!callerProfile?.company_id || !targetProfile?.company_id) {
        throw new Error('Forbidden: Could not verify company membership');
      }

      if (callerProfile.company_id !== targetProfile.company_id) {
        throw new Error('Forbidden: Can only delete users in your own company');
      }
    }

    // All checks passed, delete the user
    console.log(`User ${callerId} (${callerRole}) deleting user ${user_id}`);

    const { error } = await supabaseAdmin.auth.admin.deleteUser(user_id);

    if (error) throw error;

    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Delete user error:', error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
