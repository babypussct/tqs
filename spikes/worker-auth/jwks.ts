/**
 * JWKS Key Cache for Google Firebase Auth Signing Keys
 * Uses Web Crypto API (standard in Cloudflare Workers and Node 20+)
 */

export interface GoogleJwk {
  alg: string;
  e: string;
  kid: string;
  kty: string;
  n: string;
  use: string;
}

export interface GoogleJwksResponse {
  keys: GoogleJwk[];
}

export class JwksCache {
  private static readonly GOOGLE_JWKS_URL =
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

  private keyCache: Map<string, CryptoKey> = new Map();
  private cacheExpiresAt: number = 0;
  private pendingFetch: Promise<void> | null = null;
  public subrequestCount: number = 0;

  /**
   * Reset the cache (useful for testing cold vs warm states)
   */
  public clear(): void {
    this.keyCache.clear();
    this.cacheExpiresAt = 0;
    this.pendingFetch = null;
    this.subrequestCount = 0;
  }

  /**
   * Manually register a test JWK / CryptoKey (for offline benchmarks)
   */
  public registerKey(kid: string, key: CryptoKey, ttlMs: number = 3600_000): void {
    this.keyCache.set(kid, key);
    this.cacheExpiresAt = Math.max(this.cacheExpiresAt, Date.now() + ttlMs);
  }


  /**
   * Fetch JWKS from Google and import keys into Web Crypto
   */
  private async refreshCache(): Promise<void> {
    if (this.pendingFetch) {
      return this.pendingFetch;
    }

    this.pendingFetch = (async () => {
      try {
        this.subrequestCount++;
        const response = await fetch(JwksCache.GOOGLE_JWKS_URL);
        if (!response.ok) {
          throw new Error(`Failed to fetch Google JWKS: HTTP ${response.status}`);
        }

        // Parse Cache-Control header: "public, max-age=21600, must-revalidate, no-transform"
        const cacheControl = response.headers.get('cache-control') || '';
        const maxAgeMatch = cacheControl.match(/max-age=(\d+)/);
        const maxAgeSeconds = maxAgeMatch ? parseInt(maxAgeMatch[1], 10) : 3600;

        const jwks = (await response.json()) as GoogleJwksResponse;
        if (!jwks.keys || !Array.isArray(jwks.keys)) {
          throw new Error('Invalid JWKS response structure from Google');
        }

        // Store raw JWKs and clear cached CryptoKeys to allow lazy import
        this.rawJwkMap.clear();
        this.keyCache.clear();

        for (const jwk of jwks.keys) {
          if (jwk.alg === 'RS256' && jwk.kty === 'RSA') {
            this.rawJwkMap.set(jwk.kid, jwk);
          }
        }

        this.cacheExpiresAt = Date.now() + maxAgeSeconds * 1000;
      } finally {
        this.pendingFetch = null;
      }
    })();

    return this.pendingFetch;
  }

  private rawJwkMap: Map<string, GoogleJwk> = new Map();

  /**
   * Get an imported Web Crypto CryptoKey by key ID (kid)
   */
  public async getKey(kid: string): Promise<CryptoKey | null> {
    const now = Date.now();

    // Check memory cache first
    const cached = this.keyCache.get(kid);
    if (cached && now < this.cacheExpiresAt) {
      return cached;
    }

    // If raw JWKs expired or missing kid, refresh
    if (this.rawJwkMap.size === 0 || now >= this.cacheExpiresAt || !this.rawJwkMap.has(kid)) {
      await this.refreshCache();
    }

    // Lazy import key for the specific kid requested
    const rawJwk = this.rawJwkMap.get(kid);
    if (!rawJwk) {
      return null;
    }

    const cryptoKey = await crypto.subtle.importKey(
      'jwk',
      rawJwk,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['verify']
    );

    this.keyCache.set(kid, cryptoKey);
    return cryptoKey;
  }
}

// Export singleton instance
export const jwksCache = new JwksCache();
