export interface RateLimitConfig {
  maxRequests: number; // Maximum number of requests allowed in the window
  windowMs: number; // Time window in milliseconds
  keyPrefix?: string; // Cache key prefix (default: 'rl')
}

export interface RateLimitStatus {
  allowed: boolean;
  limit: number;
  remaining: number;
  reset: number; // Epoch timestamp in milliseconds when the limit resets
}

export class RateLimiter {
  private maxRequests: number;
  private windowMs: number;
  private keyPrefix: string;
  private memoryStore: Map<string, { count: number; resetTime: number }> = new Map();
  private kvPromise: Promise<unknown | null> | null = null;
  private useKv = false;

  constructor(config: RateLimitConfig) {
    this.maxRequests = config.maxRequests;
    this.windowMs = config.windowMs;
    this.keyPrefix = config.keyPrefix ?? "rl";

    // Attempt to open Deno KV if it is available in the global Deno namespace
    // and is not disabled (e.g. during simple unit testing where Deno.openKv isn't mocked or fails)
    if (typeof Deno !== "undefined" && typeof Deno.openKv === "function") {
      try {
        // We initialize the KV promise without blocking the constructor
        this.kvPromise = Deno.openKv()
          .then((kv) => {
            this.useKv = true;
            return kv;
          })
          .catch((err) => {
            console.warn("[RateLimiter] Deno KV failed to open, falling back to in-memory store:", err);
            this.useKv = false;
            return null;
          });
      } catch (err) {
        console.warn("[RateLimiter] Exception when attempting to open Deno KV:", err);
        this.useKv = false;
      }
    }
  }

  /**
   * Helper to resolve the client's IP address from a Request and/or Deno connection info.
   */
  public getClientIp(req: Request, info?: { remoteAddr?: Deno.Addr }): string {
    // 1. Check standard proxy headers (useful when deployed behind Supabase API Gateway, Kong, Cloudflare, etc.)
    const forwardedFor = req.headers.get("x-forwarded-for");
    if (forwardedFor) {
      const parts = forwardedFor.split(",");
      return parts[0].trim();
    }

    const realIp = req.headers.get("x-real-ip");
    if (realIp) {
      return realIp.trim();
    }

    // 2. Fall back to remote connection info
    if (info?.remoteAddr && "hostname" in info.remoteAddr) {
      return info.remoteAddr.hostname;
    }

    // 3. Fallback identifier
    return "unknown-ip";
  }

  /**
   * Checks if the given identifier (usually IP address) is within the rate limit.
   */
  public async check(identifier: string): Promise<RateLimitStatus> {
    const now = Date.now();

    // Check with Deno KV if active
    if (this.useKv && this.kvPromise) {
      const kv = await this.kvPromise;
      if (kv) {
        try {
          const kvKey = [this.keyPrefix, identifier];
          // deno-lint-ignore no-explicit-any
          const result = await (kv as any).get(kvKey);
          
          let count = 0;
          let resetTime = now + this.windowMs;

          if (result && result.value) {
            const data = result.value as { count: number; resetTime: number };
            if (now < data.resetTime) {
              count = data.count;
              resetTime = data.resetTime;
            } else {
              // Reset window
              count = 0;
              resetTime = now + this.windowMs;
            }
          }

          if (count >= this.maxRequests) {
            return {
              allowed: false,
              limit: this.maxRequests,
              remaining: 0,
              reset: resetTime,
            };
          }

          count++;
          // Save with expiration to clean up old keys automatically
          const expireIn = Math.ceil(this.windowMs / 1000);
          await (kv as any).set(kvKey, { count, resetTime }, { expireIn });

          return {
            allowed: true,
            limit: this.maxRequests,
            remaining: this.maxRequests - count,
            reset: resetTime,
          };
        } catch (err) {
          console.warn("[RateLimiter] Error querying Deno KV store, falling back to memory store:", err);
          // Don't throw, let it fall back to memoryStore below
        }
      }
    }

    // Fallback: In-memory store
    const key = `${this.keyPrefix}:${identifier}`;
    let record = this.memoryStore.get(key);

    if (!record || now >= record.resetTime) {
      record = { count: 0, resetTime: now + this.windowMs };
    }

    if (record.count >= this.maxRequests) {
      return {
        allowed: false,
        limit: this.maxRequests,
        remaining: 0,
        reset: record.resetTime,
      };
    }

    record.count++;
    this.memoryStore.set(key, record);

    return {
      allowed: true,
      limit: this.maxRequests,
      remaining: this.maxRequests - record.count,
      reset: record.resetTime,
    };
  }

  /**
   * Resets the rate limit statistics for the given identifier. Useful in tests.
   */
  public async reset(identifier: string): Promise<void> {
    const key = `${this.keyPrefix}:${identifier}`;
    this.memoryStore.delete(key);

    if (this.useKv && this.kvPromise) {
      const kv = await this.kvPromise;
      if (kv) {
        try {
          const kvKey = [this.keyPrefix, identifier];
          await (kv as any).delete(kvKey);
        } catch (err) {
          console.warn("[RateLimiter] Error resetting Deno KV store:", err);
        }
      }
    }
  }

  /**
   * Generates standard HTTP response headers for rate limiting.
   */
  public getHeaders(status: RateLimitStatus): Record<string, string> {
    const resetTimeSeconds = Math.ceil(status.reset / 1000);
    const retryAfter = Math.max(0, Math.ceil((status.reset - Date.now()) / 1000));

    return {
      "X-RateLimit-Limit": String(status.limit),
      "X-RateLimit-Remaining": String(status.remaining),
      "X-RateLimit-Reset": String(resetTimeSeconds),
      "Retry-After": String(retryAfter),
    };
  }
}
