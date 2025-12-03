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

    // Get the caller's role and company
    const { data: callerRoleData, error: callerRoleError } = await supabaseAdmin
      .from('user_roles')
      .select('role')
      .eq('user_id', callerId)
      .single();

    if (callerRoleError || !callerRoleData) {
      throw new Error('Unauthorized: Caller role not found');
    }

    const callerRole = callerRoleData.role;

    // Only admin and super_admin can update users
    if (callerRole !== 'admin' && callerRole !== 'super_admin') {
      throw new Error('Forbidden: Only admins can update users');
    }

    const { user_id, full_name, phone, company_id, role } = await req.json();

    if (!user_id) {
      throw new Error('user_id is required');
    }

    // Get the target user's current role
    const { data: targetRoleData } = await supabaseAdmin
      .from('user_roles')
      .select('role')
      .eq('user_id', user_id)
      .single();

    const targetCurrentRole = targetRoleData?.role;

    // Prevent admins from modifying super_admins
    if (callerRole === 'admin' && targetCurrentRole === 'super_admin') {
      throw new Error('Forbidden: Admins cannot modify super_admin accounts');
    }

    // Prevent admins from creating super_admins
    if (callerRole === 'admin' && role === 'super_admin') {
      throw new Error('Forbidden: Only super_admins can assign super_admin role');
    }

    // Only super_admin can change company_id
    if (callerRole === 'admin' && company_id !== undefined) {
      // Get the target's current company
      const { data: targetProfile } = await supabaseAdmin
        .from('profiles')
        .select('company_id')
        .eq('id', user_id)
        .single();

      if (targetProfile?.company_id !== company_id) {
        throw new Error('Forbidden: Only super_admins can change user company');
      }
    }

    // If caller is admin (not super_admin), verify target is in the same company
    if (callerRole === 'admin') {
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
        throw new Error('Forbidden: Can only update users in your own company');
      }
    }

    console.log(`User ${callerId} (${callerRole}) updating user ${user_id}`);

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
      const { error: roleError } = await supabaseAdmin
        .from('user_roles')
        .insert({
          user_id,
          role: role,
        });

      if (roleError) throw roleError;

      // Handle technician entry
      if (role === 'technician') {
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
    console.error('Update user error:', error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
