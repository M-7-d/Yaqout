import { assertEquals } from "jsr:@std/assert@1";
import { RateLimiter } from "./rate_limiter.ts";

Deno.test("RateLimiter - allows requests under the limit", async () => {
  const limiter = new RateLimiter({
    maxRequests: 3,
    windowMs: 5000,
    keyPrefix: "test-under",
  });

  const ip = "192.168.1.1";

  // Reset to be safe
  await limiter.reset(ip);

  let status = await limiter.check(ip);
  assertEquals(status.allowed, true);
  assertEquals(status.remaining, 2);

  status = await limiter.check(ip);
  assertEquals(status.allowed, true);
  assertEquals(status.remaining, 1);

  status = await limiter.check(ip);
  assertEquals(status.allowed, true);
  assertEquals(status.remaining, 0);
});

Deno.test("RateLimiter - blocks requests exceeding the limit", async () => {
  const limiter = new RateLimiter({
    maxRequests: 2,
    windowMs: 10000,
    keyPrefix: "test-block",
  });

  const ip = "192.168.1.2";
  await limiter.reset(ip);

  // 1st request
  await limiter.check(ip);
  // 2nd request
  await limiter.check(ip);

  // 3rd request - should be blocked
  const status = await limiter.check(ip);
  assertEquals(status.allowed, false);
  assertEquals(status.remaining, 0);

  const headers = limiter.getHeaders(status);
  assertEquals(headers["X-RateLimit-Limit"], "2");
  assertEquals(headers["X-RateLimit-Remaining"], "0");
  assertEquals(typeof headers["X-RateLimit-Reset"], "string");
  assertEquals(typeof headers["Retry-After"], "string");
});

Deno.test("RateLimiter - correctly parses client IP from headers", () => {
  const limiter = new RateLimiter({
    maxRequests: 5,
    windowMs: 5000,
  });

  // Test X-Forwarded-For
  const req1 = new Request("http://localhost/api", {
    headers: { "X-Forwarded-For": "203.0.113.195, 70.41.3.18" },
  });
  assertEquals(limiter.getClientIp(req1), "203.0.113.195");

  // Test X-Real-IP
  const req2 = new Request("http://localhost/api", {
    headers: { "X-Real-IP": "198.51.100.1" },
  });
  assertEquals(limiter.getClientIp(req2), "198.51.100.1");

  // Test hostname info fallback
  const req3 = new Request("http://localhost/api");
  const info = {
    remoteAddr: {
      transport: "tcp" as const,
      hostname: "127.0.0.1",
      port: 12345,
    },
  };
  assertEquals(limiter.getClientIp(req3, info), "127.0.0.1");

  // Fallback default
  assertEquals(limiter.getClientIp(req3), "unknown-ip");
});
