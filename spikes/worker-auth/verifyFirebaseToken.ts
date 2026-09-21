/**
 * Firebase ID Token Verification using Web Crypto API
 * Compliant with Cloudflare Workers runtime and Firebase specifications
 * Reference: https://firebase.google.com/docs/auth/admin/verify-id-tokens
 */

import { jwksCache, JwksCache } from './jwks';
import { FirebaseIdTokenHeader, FirebaseIdTokenPayload } from './types';

export class TokenVerificationError extends Error {
  constructor(message: string, public readonly code: string) {
    super(message);
    this.name = 'TokenVerificationError';
  }
}

/**
 * Base64URL to Uint8Array (RFC 7515)
 */
export function base64UrlToUint8Array(base64Url: string): Uint8Array {
  const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
  const pad = base64.length % 4;
  const padded = pad ? base64 + '='.repeat(4 - pad) : base64;
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

/**
 * Decode Base64URL string to JSON object
 */
export function decodeBase64UrlJson<T>(base64Url: string): T {
  const bytes = base64UrlToUint8Array(base64Url);
  const jsonStr = new TextDecoder().decode(bytes);
  return JSON.parse(jsonStr) as T;
}

export interface VerifyTokenOptions {
  projectId: string;
  clockSkewSeconds?: number;
  customJwksCache?: JwksCache;
}

/**
 * Verify a Firebase ID Token using Web Crypto RS256 verification
 */
export async function verifyFirebaseIdToken(
  token: string,
  options: VerifyTokenOptions
): Promise<FirebaseIdTokenPayload> {
  const { projectId, clockSkewSeconds = 60 } = options;
  const cache = options.customJwksCache || jwksCache;

  if (!token || typeof token !== 'string') {
    throw new TokenVerificationError('Firebase ID token must be a non-empty string', 'TOKEN_INVALID');
  }

  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new TokenVerificationError('Invalid token format: must have 3 parts separated by dots', 'TOKEN_MALFORMED');
  }

  const [headerB64, payloadB64, signatureB64] = parts;

  // 1. Decode Header
  let header: FirebaseIdTokenHeader;
  try {
    header = decodeBase64UrlJson<FirebaseIdTokenHeader>(headerB64);
  } catch {
    throw new TokenVerificationError('Failed to parse token header', 'HEADER_PARSE_ERROR');
  }

  if (header.alg !== 'RS256') {
    throw new TokenVerificationError(`Unsupported algorithm '${header.alg}', expected 'RS256'`, 'INVALID_ALGORITHM');
  }

  if (!header.kid) {
    throw new TokenVerificationError('Token header missing "kid" property', 'MISSING_KID');
  }

  // 2. Decode Payload
  let payload: FirebaseIdTokenPayload;
  try {
    payload = decodeBase64UrlJson<FirebaseIdTokenPayload>(payloadB64);
  } catch {
    throw new TokenVerificationError('Failed to parse token payload', 'PAYLOAD_PARSE_ERROR');
  }

  // 3. Validate Timing Claims
  const nowInSeconds = Math.floor(Date.now() / 1000);

  if (typeof payload.exp !== 'number' || payload.exp <= nowInSeconds - clockSkewSeconds) {
    throw new TokenVerificationError('Firebase ID token has expired', 'TOKEN_EXPIRED');
  }

  if (typeof payload.iat !== 'number' || payload.iat > nowInSeconds + clockSkewSeconds) {
    throw new TokenVerificationError('Firebase ID token issued in the future (iat)', 'INVALID_IAT');
  }

  if (typeof payload.auth_time !== 'number' || payload.auth_time > nowInSeconds + clockSkewSeconds) {
    throw new TokenVerificationError('Firebase ID token authentication in the future (auth_time)', 'INVALID_AUTH_TIME');
  }

  // 4. Validate Audience & Issuer per Firebase specifications
  if (payload.aud !== projectId) {
    throw new TokenVerificationError(
      `Firebase ID token has invalid audience '${payload.aud}', expected '${projectId}'`,
      'INVALID_AUDIENCE'
    );
  }

  const expectedIssuer = `https://securetoken.google.com/${projectId}`;
  if (payload.iss !== expectedIssuer) {
    throw new TokenVerificationError(
      `Firebase ID token has invalid issuer '${payload.iss}', expected '${expectedIssuer}'`,
      'INVALID_ISSUER'
    );
  }

  // 5. Validate Subject (UID)
  if (!payload.sub || typeof payload.sub !== 'string' || payload.sub.trim().length === 0) {
    throw new TokenVerificationError('Firebase ID token must have a valid non-empty "sub" claim', 'INVALID_SUBJECT');
  }

  // 6. Cryptographic Signature Verification with Web Crypto
  const cryptoKey = await cache.getKey(header.kid);
  if (!cryptoKey) {
    throw new TokenVerificationError(`No public key found for kid '${header.kid}'`, 'UNKNOWN_KID');
  }

  const dataToVerify = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signatureBytes = base64UrlToUint8Array(signatureB64);

  const isValidSignature = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    signatureBytes,
    dataToVerify
  );

  if (!isValidSignature) {
    throw new TokenVerificationError('Firebase ID token signature verification failed', 'INVALID_SIGNATURE');
  }

  return payload;
}
