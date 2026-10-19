import assert from 'node:assert/strict';
import { googleLoginErrorMessage, shouldUseShopAuthProxy } from './googleAuthFlow';

const proxy = {
  hostname: 'tqsshop.vercel.app',
  enabled: true,
  authDomainOverridden: false,
  projectId: 'shop-firebase',
  expectedProjectId: 'shop-firebase',
};

assert.equal(shouldUseShopAuthProxy(proxy), true, 'canonical production enables same-origin auth on every device');
assert.equal(shouldUseShopAuthProxy({ ...proxy, enabled: false }), false, 'feature disabled until OAuth callback is registered');
assert.equal(shouldUseShopAuthProxy({ ...proxy, hostname: 'preview.vercel.app' }), false, 'preview keeps its configured auth domain');
assert.equal(shouldUseShopAuthProxy({ ...proxy, authDomainOverridden: true }), false, 'explicit auth domain takes priority');
assert.equal(shouldUseShopAuthProxy({ ...proxy, projectId: 'another-project' }), false, 'different Firebase project is isolated');

assert.equal(googleLoginErrorMessage({ code: 'auth/popup-closed-by-user' }), null);
assert.match(googleLoginErrorMessage({ code: 'auth/operation-not-supported-in-this-environment' })!, /trình duyệt/i);
assert.match(googleLoginErrorMessage({ code: 'auth/unauthorized-domain' })!, /Tên miền TQSShop/);
assert.match(googleLoginErrorMessage({ code: 'auth/network-request-failed' })!, /Kiểm tra mạng/);
assert.match(googleLoginErrorMessage({ code: 'auth/unknown' })!, /auth\/unknown/);

console.log('TQSShop Google login proxy/messages: 10/10 PASS');
