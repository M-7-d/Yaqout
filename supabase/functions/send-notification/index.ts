import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const { title, body, userIds } = await req.json();

  const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID');
  const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY');

  const response = await fetch('https://onesignal.com/api/v1/notifications', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify({
      app_id: ONESIGNAL_APP_ID,
      include_aliases: {
        external_id: userIds // This targets the user IDs you passed from OneSignal.login(userId)
      },
      target_channel: "push",
      headings: { "en": title },
      contents: { "en": body },
    }),
  });

  const data = await response.json();
  return new Response(JSON.stringify(data), { headers: { 'Content-Type': 'application/json' } });
});
