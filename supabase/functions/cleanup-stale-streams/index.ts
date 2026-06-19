// Supabase Edge Function: supabase/functions/cleanup-stale-streams/index.ts
// Deploy with: supabase functions deploy cleanup-stale-streams
//
// This function calls cleanup_stale_live_streams() to mark any live
// stream as 'ended' if its host hasn't sent a heartbeat in 60 seconds.
//
// You can invoke this on a schedule using:
//   - Supabase Dashboard → Database → Extensions → pg_cron
//   - Or an external cron service (e.g. cron-job.org) hitting the function URL

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data, error } = await supabase.rpc("cleanup_stale_live_streams");

    if (error) throw error;

    return new Response(
      JSON.stringify({
        success: true,
        streams_ended: data,
        timestamp: new Date().toISOString(),
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
