// Supabase Edge Function: supabase/functions/agora-token/index.ts
// Deploy with: supabase functions deploy agora-token
//
// This function generates Agora RTC tokens server-side, keeping
// your APP_CERTIFICATE secret out of the client app.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  RtcRole,
  RtcTokenBuilder,
} from "https://esm.sh/agora-access-token@2.0.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { channelName, uid, role } = await req.json();

    const appId = Deno.env.get("AGORA_APP_ID")!;
    const appCertificate = Deno.env.get("AGORA_APP_CERTIFICATE")!;

    const expirationInSeconds = 3600; // 1 hour
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationInSeconds;

    const agoraRole = role === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      agoraRole,
      privilegeExpiredTs
    );

    return new Response(JSON.stringify({ token }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
