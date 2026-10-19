/** An installed iOS PWA may hand Google's popup to a different browser
 * context, losing the sessionStorage state kept by Firebase's OAuth helper. */
export function isIOSStandalone(userAgent: string, standalone: boolean, maxTouchPoints: number): boolean {
  const ios = /iPad|iPhone|iPod/i.test(userAgent) ||
    (/Macintosh/i.test(userAgent) && maxTouchPoints > 1);
  return ios && standalone;
}

export type GoogleLoginMode = 'popup' | 'same-origin-redirect' | 'open-in-browser';

export function googleLoginMode(options: {
  userAgent: string;
  standalone: boolean;
  maxTouchPoints: number;
  hostname: string;
  sameOriginEnabled: boolean;
  authDomainOverridden: boolean;
  projectId: string;
  expectedProjectId: string;
}): GoogleLoginMode {
  if (!isIOSStandalone(options.userAgent, options.standalone, options.maxTouchPoints)) return 'popup';
  // The Cloudflare proxy and Google OAuth redirect allowlist must both be ready
  // before switching the Firebase authDomain on production.
  if (options.sameOriginEnabled && options.hostname === 'tqsvn.pages.dev' &&
    !options.authDomainOverridden && options.projectId === options.expectedProjectId) {
    return 'same-origin-redirect';
  }
  return 'open-in-browser';
}
