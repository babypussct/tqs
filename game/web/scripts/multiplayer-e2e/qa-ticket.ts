import { createHmac } from 'node:crypto';

const NATIVE_NAME_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;

export function assertQaNativeName(nativeName: string): void {
  if (!NATIVE_NAME_PATTERN.test(nativeName)) {
    throw new Error('QA native account name is not metadata-safe');
  }
}

export function createTqs1Ticket(nativeName: string, expiresAt: number, secret: string): string {
  assertQaNativeName(nativeName);
  if (!Number.isSafeInteger(expiresAt) || expiresAt <= 0) {
    throw new Error('QA ticket expiry must be a positive Unix timestamp');
  }
  if (secret.length < 32) {
    throw new Error('QA ticket secret must contain at least 32 characters');
  }
  const payload = `TQS1|${nativeName}|${expiresAt}`;
  const signature = createHmac('sha256', secret).update(payload).digest('hex');
  return `TQS1|${expiresAt}|${signature}`;
}

export function assertTqs1Ticket(ticket: string, expectedExpiry: number): void {
  const match = /^TQS1\|(\d+)\|([a-f0-9]{64})$/.exec(ticket);
  if (!match || Number(match[1]) !== expectedExpiry) {
    throw new Error('QA ticket helper returned an invalid TQS1 ticket');
  }
}
