import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")

serve(async (req) => {
  try {
    // The webhook payload from Supabase
    const payload = await req.json()
    
    // Extract the new bug report row
    const record = payload.record
    const title = record.title
    const description = record.description

    // Send the email via Resend API
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "onboarding@resend.dev", // Replace with your verified domain
        to: ["muhammadalhaddad14@gmail.com"], // Your email address
        subject: `New Bug Report: ${title}`,
        html: `
          <h2>New Bug Report Received</h2>
          <p><strong>Title:</strong> ${title}</p>
          <p><strong>Description:</strong><br/> ${description}</p>
          <hr/>
          <small>Sent from Yakut App via Supabase Webhooks</small>
        `,
      }),
    })

    const data = await res.json()

    return new Response(JSON.stringify(data), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    })
  }
})
