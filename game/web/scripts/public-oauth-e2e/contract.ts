/** Public QA evidence must never include exception, URL query, account or frame contents. */
export type PublicStage = 'preflight' | 'oauth' | 'lobby' | 'room' | 'websocket' |
  'match' | 'gameover' | 'logout' | 'relogin' | 'cleanup';

export class PublicProbeError extends Error {
  constructor(readonly stage: PublicStage, readonly reason: string) {
    super(`${stage}:${reason}`);
    this.name = 'PublicProbeError';
  }
}

export function publicProbeUrl(value: string): URL {
  let url: URL;
  try { url = new URL(value); }
  catch { throw new PublicProbeError('preflight', 'invalid_public_url'); }
  if (url.protocol !== 'https:' || !url.hostname || url.username || url.password ||
      url.pathname !== '/' || url.search || url.hash || url.port) {
    throw new PublicProbeError('preflight', 'invalid_public_url');
  }
  return url;
}

export function isGameSocket(value: string, site: URL): boolean {
  try {
    const socket = new URL(value);
    return socket.protocol === 'wss:' && socket.host === site.host &&
      socket.pathname === '/gateway/ws';
  } catch { return false; }
}

export function verifyQaEmail(actual: string | null, expected: string): boolean {
  return !!actual && actual.trim().toLowerCase() === expected.trim().toLowerCase();
}

/** Inspect the Firebase ID JWT in memory only; the server still verifies its signature. */
export function matchesQaBearer(bearer: string | undefined, expected: string): boolean {
  if (!bearer?.startsWith('Bearer ')) return false;
  try {
    const parts = bearer.slice(7).split('.');
    if (parts.length !== 3) return false;
    const body = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')) as {
      email?: unknown; email_verified?: unknown;
    };
    return body.email_verified === true && typeof body.email === 'string' &&
      verifyQaEmail(body.email, expected);
  } catch { return false; }
}

export function safeFailure(error: unknown, stage: PublicStage): { stage: PublicStage; reason: string } {
  if (error instanceof PublicProbeError) return {
    stage: error.stage,
    reason: /^[a-z][a-z0-9_]{0,79}$/.test(error.reason) ? error.reason : 'unexpected_failure',
  };
  return { stage, reason: 'unexpected_failure' };
}
