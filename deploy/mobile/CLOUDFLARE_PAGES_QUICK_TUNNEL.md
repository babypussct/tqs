# CP33 candidate: Cloudflare Pages + Oracle Quick Tunnel

## Update 2026-10-17 — same-origin gateway LIVE; hostname registration STAGED

The original direct-URL procedure below describes the **previous deployment**. Production Pages deployment `da0f8a62` now serves the **CP33 commit** `69780705606cdde08047895d3b77a0119a57bd56` with `VITE_GATEWAY_URL=/gateway`. Built from isolated Git archive plus Pages Functions; concurrent uncommitted CP34 UI changes were excluded. No purchased domain is needed for `https://tqsvn.pages.dev`.

Live path: `https://tqsvn.pages.dev/gateway/{healthz,manifest.json,bundle.zip,assets/*,ws}` → Pages Function → Workers KV `TQS_GATEWAY_CONFIG` (`quick-tunnel-url`) → Cloudflare Quick Tunnel → Oracle gateway → FreeKill. Authenticated `POST /api/tunnel/register` validates hostname against `*.trycloudflare.com`, tests health, then writes KV. No client-supplied upstream URLs are accepted. The service worker does not cache gateway requests.

Preview `34675ab4.tqsvn.pages.dev`: health/manifest **200** and browser WebSocket **101**. Production `tqsvn.pages.dev`: root, health, manifest and bundle **200**; missing asset **404**; actual Chrome/Wasmoon Lua → Pages `/gateway` → Oracle C++ Setup, EnterLobby, clean disconnect **PASS**. Runtime MD5 `29653b06f1db4a1cece2941f79cbe648`, 14 packages / 5,279 files. Local Pages Function tests **5/5 PASS**. Oracle `freekill-native`, `tqs-gateway`, `tqs-quick-tunnel` still active. Full gameplay and tunnel rotation were **not** verified.

**Open blocker:** A native execution safety review blocked creation and transfer of the registration secret. Cloudflare Pages does not yet have `TQS_TUNNEL_REGISTRATION_TOKEN`; Oracle does not yet have `/etc/tqs-tunnel-register.secret`. The registration script and systemd units were staged and validated on Oracle, but `tqs-tunnel-register.timer` is **disabled** until the same token has been securely provisioned on both sides. If the tunnel hostname rotates, update the KV key manually; frontend rebuild is no longer needed. Automatic recovery has **not** been enabled or verified.

If the hostname rotates before activation, manually update the KV target after checking that the replacement tunnel serves a healthy gateway (replace the placeholder with the actual hostname):

```bash
cd game/web
npx --yes wrangler@4 kv key put quick-tunnel-url NEW_HOSTNAME.trycloudflare.com --binding TQS_GATEWAY_CONFIG --remote
curl -fsS https://tqsvn.pages.dev/gateway/healthz
```

After an operator securely provisions one matching, unpredictable 32+ character secret as the encrypted Cloudflare Pages secret `TQS_TUNNEL_REGISTRATION_TOKEN` and Oracle root-only file `/etc/tqs-tunnel-register.secret`, activate:

```bash
ssh tqs-native-qa-replacement 'sudo systemctl enable --now tqs-tunnel-register.timer'
ssh tqs-native-qa-replacement 'sudo systemctl start tqs-tunnel-register.service && sudo systemctl status tqs-tunnel-register.service --no-pager'
curl -fsS https://tqsvn.pages.dev/gateway/healthz
```

Registrar source: `deploy/mobile/oracle-tunnel-register.mjs`, with systemd units `tqs-tunnel-register.{service,timer}`. Each invocation checks the current tunnel systemd invocation and both local/public health endpoints. The timer attempts reconciliation every minute, writes when the hostname changes, and refreshes hourly. Keep the token out of repositories, CLI logs and chat. Test controlled rotation only after checking that no games are active.

Cloudflare Free KV quotas and Quick Tunnel's lack of uptime SLA (200 in-flight requests maximum) prevent a promise of uninterrupted access even after the registrar works.

Verified on 2026-10-17 (Asia/Ho_Chi_Minh). This deployment is a **temporary candidate**, not the official release. Render remains suspended independently.

## Live topology and identity

`https://tqsvn.pages.dev` (Cloudflare Pages project `tqsvn`, production branch `main`) → browser `VITE_GATEWAY_URL=https://keys-mar-evaluate-winter.trycloudflare.com` → Cloudflare Quick Tunnel → `tqs-gateway.service` on Oracle `freekill-hegemony-qa` → local TCP `127.0.0.1:9527` (`freekill-native.service`).

- Pages deployment: `https://e406acd0.tqsvn.pages.dev` (production alias `https://tqsvn.pages.dev`). 2,030 files, 63 MiB local build, none exceeding the 25 MiB Pages file limit.
- CP33 source commit: `69780705606cdde08047895d3b77a0119a57bd56` (current checkout `3b874223` adds documentation only before the live-test harness adjustment).
- Published HTML SHA-256: `02ebe3bb2da04a0891b648daeab6bfcf113d1e62102422c30661da9d6c95123a`; JS: `21e9d312e73a04e42e753f32c58032bb902eb4da7967b6f629952fee756ecd45`; CSS: `4aa3d4b5351f52f65e8bfba00979856f2e17a275492128b24d6607d27122470c`.
- Gateway manifest: 14 packages, 5,279 Lua/JSON/Markdown files, `md5=29653b06f1db4a1cece2941f79cbe648`, `bundleHash=ce342f067f61796e`. Server-only `tqs_qa` is excluded from browser assets.
- Oracle installed Node.js `v22.23.2` under `/home/ubuntu/.local/opt/node22`, `cloudflared v2026.10.1` under `/home/ubuntu/.local/bin`, gateway source and `npm ci --omit=dev` under `/home/ubuntu/tqs-gateway`.
- Dedicated systemd units `/etc/systemd/system/tqs-gateway.service` and `/etc/systemd/system/tqs-quick-tunnel.service` are `enabled` and `active`. Gateway binds `127.0.0.1:8080`, reads `FK_ROOT=/opt/freekill-hegemony/current`, restricts browser origin to `https://tqsvn.pages.dev`, and trusts the local tunnel proxy for client-IP headers. Existing FreeKill service was neither modified nor restarted.

## Critical Quick Tunnel limitation

The `trycloudflare.com` URL is **ephemeral**. A cloudflared restart/reconnect can create a different hostname; the Pages JS contains the hostname from build time. If it changes, the frontend will fail to load the gateway until it is rebuilt and redeployed with the new hostname. The systemd unit restarts cloudflared, but cannot update Cloudflare Pages automatically. This temporary tunnel cannot be presented as a stable 24/7 or official endpoint. For a permanent deployment, use a named tunnel with a domain/stable hostname (requires separate setup).

## Check health and republish after tunnel rotation

From the local repository, using the SSH alias already configured for the Oracle VM:

```bash
ssh tqs-native-qa-replacement 'systemctl is-active freekill-native.service tqs-gateway.service tqs-quick-tunnel.service'
ssh tqs-native-qa-replacement 'journalctl -u tqs-quick-tunnel.service -n 50 --no-pager | grep -oE "https://[-a-z0-9]+[.]trycloudflare[.]com" | tail -1'
ssh tqs-native-qa-replacement 'curl -fsS http://127.0.0.1:8080/manifest.json'

# Replace the URL with the current hostname printed by the tunnel journal.
VITE_GATEWAY_URL=https://keys-mar-evaluate-winter.trycloudflare.com npm --prefix game/web run build
npx --yes wrangler@4 pages deploy game/web/dist --project-name tqsvn --branch main

# Uses an existing dedicated test account from ~/.codex/secrets/tqs-live-test.env.
TQS_LIVE_URL=https://tqsvn.pages.dev \
TQS_LIVE_GATEWAY_URL=https://keys-mar-evaluate-winter.trycloudflare.com \
TQS_LIVE_HOST=161.33.209.212 \
npm --prefix game/web run test:e2e:live -- --login
```

`wrangler` needs Cloudflare OAuth login or an authorized local token. Never put credentials into repository files or the Pages build. Do not restart `freekill-native.service` as part of a web/tunnel redeploy; preserve ongoing native rooms. Existing Pages deployments can be inspected/rolled back separately via the Cloudflare dashboard.

## Actual bounded verification

- Production Pages `index.html` and `glue.wasm` byte-matched local build; production JS/CSS, `anim/slash/1.png`, `anim/fire__slash/1.png`, `anim/damage/1.png` and `audio/system/normal_damage.mp3` byte-matched individually.
- Public Quick Tunnel `/healthz` returned `ok`; `/manifest.json` returned HTTP 200 with `Access-Control-Allow-Origin: https://tqsvn.pages.dev` and the pinned bundle identity above.
- Browser E2E (actual `tqsvn.pages.dev` in headless Chrome) passed: Wasmoon/FreeKill Lua → WSS Quick Tunnel → Oracle gateway → real FreeKill C++, Setup accepted, EnterLobby rendered in React, and disconnected cleanly. This is lobby/transport coverage, not a complete gameplay or mobile-device sign-off.
- Local production build, gateway tests `5/5`, CP33 card-effects `10/10`, release tests `4/4`, and live config tests `2/2` passed.
