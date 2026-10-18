// One-shot Oracle systemd timer job: reconcile current Quick Tunnel with Pages KV.
// Runs on Oracle only. The registration secret is never stored in this repository.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const stateDir = '/var/lib/tqs-tunnel-register';
const stateFile = `${stateDir}/state.json`;
const secretFile = '/etc/tqs-tunnel-register.secret';
const registerUrl = 'https://tqsvn.pages.dev/api/tunnel/register';
const hostnamePattern = /^[a-z0-9]+(?:-[a-z0-9]+)*\.trycloudflare\.com$/;

function command(cmd, args) {
  return execFileSync(cmd, args, { encoding: 'utf8', timeout: 10_000, maxBuffer: 256 * 1024 }).trim();
}

function loadState() {
  try { return JSON.parse(readFileSync(stateFile, 'utf8')); } catch { return {}; }
}

async function main() {
  if (command('/usr/bin/systemctl', ['is-active', 'tqs-quick-tunnel.service']) !== 'active')
    throw new Error('Quick Tunnel is not active');
  if (command('/usr/bin/systemctl', ['is-active', 'tqs-gateway.service']) !== 'active')
    throw new Error('Gateway is not active');
  const invocationId = command('/usr/bin/systemctl', ['show', 'tqs-quick-tunnel.service', '-p', 'InvocationID', '--value']);
  if (!/^[a-f0-9]{32}$/.test(invocationId)) throw new Error('No live systemd invocation ID');
  const journal = command('/usr/bin/journalctl', [`_SYSTEMD_INVOCATION_ID=${invocationId}`, '-o', 'cat', '--no-pager', '-n', '120']);
  const matches = [...journal.matchAll(/https:\/\/([a-z0-9-]+\.trycloudflare\.com)\b/g)];
  const hostname = matches.at(-1)?.[1];
  if (!hostname || hostname.length > 110 || !hostnamePattern.test(hostname))
    throw new Error('No valid hostname in current tunnel invocation');

  const current = await fetch('http://127.0.0.1:8080/healthz', { signal: AbortSignal.timeout(4000) });
  if (!current.ok || (await current.text()).trim() !== 'ok') throw new Error('Local gateway not healthy');
  const remote = await fetch(`https://${hostname}/healthz`, { signal: AbortSignal.timeout(8000) });
  if (!remote.ok || (await remote.text()).trim() !== 'ok') throw new Error('Tunnel gateway not healthy');

  const state = loadState();
  const now = Date.now();
  // Reconcile once an hour even if URL is unchanged; stays well within KV free write quota.
  if (state.hostname === hostname && now - state.registeredAt < 60 * 60 * 1000) {
    console.log('Tunnel registration current');
    return;
  }
  const secret = readFileSync(secretFile, 'utf8').trim();
  if (secret.length < 32) throw new Error('Missing registration secret');
  const registered = await fetch(registerUrl, {
    method: 'POST',
    headers: { Authorization: `Bearer ${secret}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ hostname }),
    signal: AbortSignal.timeout(15000),
  });
  if (!registered.ok) throw new Error(`Tunnel registration HTTP ${registered.status}`);
  const result = await registered.json();
  if (result.registered !== true) throw new Error('Registration was not confirmed');
  mkdirSync(stateDir, { recursive: true, mode: 0o700 });
  writeFileSync(stateFile, JSON.stringify({ hostname, registeredAt: now }), { mode: 0o600 });
  console.log('Tunnel registration synchronized');
}

main().catch((error) => {
  console.error(`Tunnel registration failed: ${error.message}`);
  process.exitCode = 1;
});
