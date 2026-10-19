import assert from 'node:assert/strict';
import { test } from 'node:test';
import { googleLoginMode, isIOSStandalone } from '../src/googleAuthRouting';

const iphone = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1';
const ios = {
  userAgent: iphone,
  standalone: true,
  maxTouchPoints: 5,
  hostname: 'tqsvn.pages.dev',
  sameOriginEnabled: true,
  authDomainOverridden: false,
  projectId: 'gen-lang-client-0845413094',
  expectedProjectId: 'gen-lang-client-0845413094',
};

test('iOS installed PWA detection includes iPad desktop-style user agents', () => {
  assert.equal(isIOSStandalone(iphone, true, 5), true);
  assert.equal(isIOSStandalone('Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/605.1.15', true, 5), true);
  assert.equal(isIOSStandalone(iphone, false, 5), false);
  assert.equal(isIOSStandalone('Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36', true, 5), false);
});

test('iOS standalone uses same-origin redirect only after explicit OAuth rollout', () => {
  assert.equal(googleLoginMode(ios), 'same-origin-redirect');
  assert.equal(googleLoginMode({ ...ios, sameOriginEnabled: false }), 'open-in-browser');
  assert.equal(googleLoginMode({ ...ios, hostname: 'preview.tqsvn.pages.dev' }), 'open-in-browser');
  assert.equal(googleLoginMode({ ...ios, authDomainOverridden: true }), 'open-in-browser');
  assert.equal(googleLoginMode({ ...ios, projectId: 'different-project' }), 'open-in-browser');
});

test('Safari, Chrome and Android continue to use synchronous Google popup', () => {
  assert.equal(googleLoginMode({ ...ios, standalone: false }), 'popup');
  assert.equal(googleLoginMode({ ...ios, userAgent: 'Mozilla/5.0 (Linux; Android 15)', standalone: true }), 'popup');
});
