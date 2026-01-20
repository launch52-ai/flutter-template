// Template: Supabase Edge Function for User Deletion
//
// Location: supabase/functions/delete-user/index.ts
//
// Usage:
// 1. Create function: supabase functions new delete-user
// 2. Copy this file to supabase/functions/delete-user/index.ts
// 3. Deploy: supabase functions deploy delete-user
// 4. Set secrets: supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your-key>

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Verify user is authenticated
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Create client with user's JWT to verify identity
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseUser.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'User not authenticated' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Get userId from request body (for extra validation)
    const { userId } = await req.json();

    // Verify the userId matches the authenticated user
    if (userId !== user.id) {
      return new Response(JSON.stringify({ error: 'User ID mismatch' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Create admin client with service role key
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Delete user data from tables (customize for your schema)
    // Example: Delete user profile
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .delete()
      .eq('id', user.id);

    if (profileError) {
      console.error('Error deleting profile:', profileError);
      // Continue with user deletion even if profile deletion fails
    }

    // Example: Delete user's posts
    // const { error: postsError } = await supabaseAdmin
    //   .from('posts')
    //   .delete()
    //   .eq('user_id', user.id);

    // Example: Delete user's files from storage
    // const { data: files } = await supabaseAdmin.storage
    //   .from('avatars')
    //   .list(user.id);
    // if (files?.length) {
    //   await supabaseAdmin.storage
    //     .from('avatars')
    //     .remove(files.map((f) => `${user.id}/${f.name}`));
    // }

    // Delete the auth user (this is the main deletion)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      user.id
    );

    if (deleteError) {
      console.error('Error deleting user:', deleteError);
      return new Response(
        JSON.stringify({ error: 'Failed to delete user account' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Log deletion for audit trail (optional)
    console.log(`User ${user.id} deleted at ${new Date().toISOString()}`);

    return new Response(
      JSON.stringify({ success: true, message: 'Account deleted' }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Unexpected error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
