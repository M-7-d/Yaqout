import { RateLimiter } from "./rate_limiter.ts";

const limiter = new RateLimiter({
  maxRequests: 5,
  windowMs: 10000, // 5 requests per 10 seconds for demo/safety
});

export async function handler(req: Request, info?: { remoteAddr?: Deno.Addr }): Promise<Response> {
  const url = new URL(req.url);
  const clientIp = limiter.getClientIp(req, info);
  
  const status = await limiter.check(clientIp);
  const headers: Record<string, string> = {
    ...limiter.getHeaders(status),
  };

  if (!status.allowed) {
    headers["content-type"] = "application/json";
    return new Response(
      JSON.stringify({ error: "Too many requests. Please slow down." }),
      { status: 429, headers }
    );
  }

  if (url.pathname === "/api") {
    headers["content-type"] = "application/json";
    return new Response(
      JSON.stringify({
        message: "Hello, world!",
        time: new Date().toISOString(),
      }),
      { headers }
    );
  }

  headers["content-type"] = "text/html";
  return new Response("<h1>Welcome to Deno!</h1>", {
    headers,
  });
}

if (import.meta.main) {
  Deno.serve((req, info) => handler(req, info));
}

