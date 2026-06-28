import { assertEquals } from "jsr:@std/assert@1";
import { handler } from "./main.ts";


Deno.test("returns html on /", async () => {
  const res = await handler(new Request("http://localhost/"));
  assertEquals(res.headers.get("content-type"), "text/html");
  const body = await res.text();
  assertEquals(body.includes("Welcome to Deno"), true);
});

Deno.test("returns json on /api", async () => {
  const res = await handler(new Request("http://localhost/api"));
  const data = await res.json();
  assertEquals(data.message, "Hello, world!");
  assertEquals(typeof data.time, "string");
});

Deno.test("rate limits requests to /api", async () => {
  const req = () => new Request("http://localhost/api", {
    headers: { "X-Forwarded-For": "1.2.3.4" }
  });

  // Make 5 successful requests (since maxRequests is 5 in main.ts)
  for (let i = 0; i < 5; i++) {
    const res = await handler(req());
    assertEquals(res.status, 200);
    assertEquals(res.headers.get("X-RateLimit-Limit"), "5");
  }

  // 6th request should fail with 429
  const res = await handler(req());
  assertEquals(res.status, 429);
  const data = await res.json();
  assertEquals(data.error, "Too many requests. Please slow down.");
});

