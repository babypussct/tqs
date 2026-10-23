// Oracle gateway watchdog. Systemd timer runs once per minute (no long-lived
// process). State and journal contain only public service metadata.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, renameSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { pathToFileURL } from 'node:url';

const stateFile = '/var/lib/tqs-gateway-watch/state.json';
const defaultTunnel = 'tqs-named-tunnel.service';
const acceptanceWindowMs = 24 * 60 * 60 * 1000;
const minimumSamples = 1440;

function systemctl(...args) {
  return execFileSync('/usr/bin/systemctl', args, {
    encoding: 'utf8', timeout: 5000, maxBuffer: 5120,
  }).trim();
}

function loadState(file) {
  try { return JSON.parse(readFileSync(file, 'utf8')); } catch { return {}; }
}

function saveState(file, state) {
  mkdirSync(dirname(file), { recursive: true, mode: 0o700 });
  const tmp = `${file}.tmp`;
  writeFileSync(tmp, `${JSON.stringify(state)}\n`, { mode: 0o600 });
  renameSync(tmp, file);
}

async function fetchText(fetchImpl, url) {
  const response = await fetchImpl(url, { redirect: 'manual', signal: AbortSignal.timeout(7000) });
  if (response.status !== 200) throw new Error(`HTTP ${response.status}`);
  return response.text();
}

export async function inspect({ fetchImpl = fetch, service = defaultTunnel,
  runSystemctl = systemctl, publicBase = 'https://tqsvn.pages.dev' } = {}) {
  if (!/^tqs-(?:named|quick)-tunnel\.service$/.test(service))
    throw new Error('Invalid tunnel service name');
  if (publicBase !== 'https://tqsvn.pages.dev')
    throw new Error('Unexpected public origin');
  for (const unit of ['freekill-native.service', 'tqs-gateway.service', service]) {
    if (runSystemctl('is-active', unit) !== 'active') throw new Error(`${unit} is not active`);
  }
  const invocation = runSystemctl('show', service, '-p', 'InvocationID', '--value');
  if (!/^[a-f0-9]{32}$/.test(invocation)) throw new Error('Tunnel invocation ID unavailable');

  const local = await fetchText(fetchImpl, 'http://127.0.0.1:8080/healthz');
  if (local.trim() !== 'ok') throw new Error('Local health body invalid');
  const publicHealth = await fetchText(fetchImpl, `${publicBase}/gateway/healthz`);
  if (publicHealth.trim() !== 'ok') throw new Error('Public health body invalid');
  const [localManifestText, publicManifestText] = await Promise.all([
    fetchText(fetchImpl, 'http://127.0.0.1:8080/manifest.json'),
    fetchText(fetchImpl, `${publicBase}/gateway/manifest.json`),
  ]);
  const localManifest = JSON.parse(localManifestText);
  const publicManifest = JSON.parse(publicManifestText);
  if (!/^[a-f0-9]{32}$/.test(localManifest.md5) ||
      typeof localManifest.bundleHash !== 'string' ||
      !Number.isSafeInteger(localManifest.fileCount) || localManifest.fileCount <= 0 ||
      localManifest.md5 !== publicManifest.md5 ||
      localManifest.bundleHash !== publicManifest.bundleHash ||
      localManifest.fileCount !== publicManifest.fileCount)
    throw new Error('Local/public gateway manifest mismatch');
  return { invocation, manifestMd5: localManifest.md5, bundleHash: localManifest.bundleHash,
    fileCount: localManifest.fileCount, service };
}

export function updateState(previous, result, checkedAt, threshold = 3, remindMs = 3_600_000) {
  const now = new Date(checkedAt).toISOString();
  if (result.ok) {
    const recovered = previous.status === 'down' && previous.alertedDown === true;
    const restarted = previous.invocation && previous.invocation !== result.meta.invocation;
    const switchedTunnel = previous.service && previous.service !== result.meta.service;
    // A missing timer interval is not evidence of uninterrupted 24h health.
    const gap = !previous.lastCheckedAt ||
      !Number.isFinite(Date.parse(previous.lastCheckedAt)) ||
      checkedAt < Date.parse(previous.lastCheckedAt) ||
      checkedAt - Date.parse(previous.lastCheckedAt) > 150_000;
    const continuous = previous.status === 'up' && !restarted && !switchedTunnel && !gap;
    const healthySince = continuous && Number.isFinite(Date.parse(previous.healthySince))
      ? previous.healthySince : now;
    const consecutiveSuccesses = continuous ? (previous.consecutiveSuccesses || 0) + 1 : 1;
    const acceptance24h = result.meta.service === defaultTunnel &&
      checkedAt - Date.parse(healthySince) >= acceptanceWindowMs &&
      consecutiveSuccesses >= minimumSamples;
    return { next: { ...result.meta, status: 'up', consecutiveFailures: 0,
      lastCheckedAt: now, lastSuccessAt: now, lastFailureAt: previous.lastFailureAt || null,
      healthySince, consecutiveSuccesses, acceptance24h,
      monitoringGapAt: gap && previous.lastCheckedAt ? now : previous.monitoringGapAt || null,
      tunnelRestartedAt: restarted ? now : previous.tunnelRestartedAt || null,
      alertedDown: false,
      totalChecks: (previous.totalChecks || 0) + 1,
      totalFailures: previous.totalFailures || 0, lastAlertAt: previous.lastAlertAt || null },
      alert: recovered ? 'recovered' : null };
  }
  const consecutiveFailures = (previous.consecutiveFailures || 0) + 1;
  const lastAlert = previous.lastAlertAt ? Date.parse(previous.lastAlertAt) : 0;
  const alert = consecutiveFailures >= threshold &&
    (!previous.alertedDown || checkedAt - lastAlert >= remindMs) ? 'down' : null;
  return { next: { ...previous, status: 'down', consecutiveFailures, consecutiveSuccesses: 0, acceptance24h: false,
    lastCheckedAt: now, lastFailureAt: now, healthySince: null,
    totalChecks: (previous.totalChecks || 0) + 1,
    totalFailures: (previous.totalFailures || 0) + 1,
    lastAlertAt: alert ? now : previous.lastAlertAt || null,
    alertedDown: alert ? true : previous.alertedDown || false,
    failureCode: result.code }, alert };
}

async function sendWebhook(webhook, state, kind, fetchImpl) {
  if (!webhook) return;
  if (!/^https:\/\//.test(webhook)) throw new Error('Alert webhook requires HTTPS');
  const content = `TQSVN gateway ${kind === 'down' ? 'DOWN' : 'RECOVERED'} — ${state.lastCheckedAt} (${state.consecutiveFailures} failed checks)`;
  const response = await fetchImpl(webhook, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: content, content }), signal: AbortSignal.timeout(6000),
  });
  if (!response.ok) throw new Error(`Alert delivery HTTP ${response.status}`);
}

export async function runWatch({ fetchImpl = fetch, runSystemctl = systemctl,
  file = stateFile, now = Date.now(), service = process.env.TQS_WATCH_TUNNEL_SERVICE || defaultTunnel,
  webhook = process.env.TQS_WATCH_ALERT_WEBHOOK || '' } = {}) {
  const previous = loadState(file);
  let result;
  try {
    const meta = await inspect({ fetchImpl, runSystemctl, service });
    result = { ok: true, meta };
  } catch (error) {
    // Never serialize raw error objects or request details to logs/state.
    result = { ok: false, code: (error.message || '').includes('manifest') ? 'manifest' : 'unreachable' };
  }
  const { next, alert } = updateState(previous, result, now);
  saveState(file, next);
  console.log(`TQS gateway ${next.status}; checked=${next.lastCheckedAt}; failures=${next.consecutiveFailures}; tunnel=${service}`);
  if (alert) {
    console.error(`TQS gateway alert: ${alert}`);
    try { await sendWebhook(webhook, next, alert, fetchImpl); }
    catch { console.error('TQS gateway alert delivery failed'); }
  }
  return { next, alert };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  runWatch().then(({ next }) => { if (next.status !== 'up') process.exitCode = 1; })
    .catch(() => { console.error('TQS gateway monitor internal failure'); process.exitCode = 1; });
}
