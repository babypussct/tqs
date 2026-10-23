# TQSVN stable gateway: Cloudflare Named Tunnel and monitoring

## Live status — 2026-10-23, Asia/Ho_Chi_Minh

- **Named tunnel `tqsvn-gateway` was created** in the existing Cloudflare account. Tunnel UUID: `f2a6cc9c-a403-42e7-badb-c5224d4ae72d`. Last observed **inactive**; no published hostname yet.
- Pages currently serves `https://tqsvn.pages.dev` with a **Quick Tunnel** via KV `TQS_GATEWAY_CONFIG/quick-tunnel-url`. Do not disable this route until the Named Tunnel endpoint and WebSocket are proven healthy.
- The only observed Pages project domain is `tqsvn.pages.dev`; **no custom domain was verified**. Cloudflare requires a domain in a Cloudflare DNS zone to publish a Named Tunnel application. `pages.dev` is Cloudflare's domain, not an owned DNS zone. Choose an owned hostname such as `gateway.<your-zone>`, verify DNS control, then finish the route below. Never fill in an invented domain.
- Oracle watchdog `tqs-gateway-watch.timer` is **enabled**, checks every minute, and initially checks the active `tqs-quick-tunnel.service`. It writes sanitized status to `/var/lib/tqs-gateway-watch/state.json` and logs failures to the systemd journal. Its initial health/manifest check passed (`md5=845498010a0c9f790254ec86e3dfc999`, 5281 files). The Named Tunnel service file is staged but **disabled**.
- An independent Codex hourly gateway outage-watch heartbeat was created. It notifies on public health/manifest failure and recovery, and stays quiet on healthy checks. The on-host monitor can also call a configured alert webhook after three consecutive failures; no webhook was configured in this staging step.
- **No 24-hour result, named restart verification, approved login or full WebSocket room flow has been observed yet.** Those are future acceptance gates; initial health is not uptime proof.
- The staged Named service uses a soft `Wants=tqs-gateway.service` dependency so a deliberate origin restart does not tear down the connector itself. The service remains disabled until its token and Cloudflare published hostname exist.

## Target topology

`browser → https://tqsvn.pages.dev/gateway/* → Pages Function → https://gateway.<owned-zone> → Cloudflare Named Tunnel → Oracle 127.0.0.1:8080 → native 127.0.0.1:9527`.

Pages handles only GET `/healthz`, `/manifest.json`, `/bundle.zip`, `/assets/*`, and WebSocket `/ws` on the gateway route; other paths are blocked. The stable upstream comes from trusted Pages binding `TQS_NAMED_TUNNEL_HOSTNAME`. When that binding exists, the Function stops reading the Quick Tunnel KV key and the legacy `/api/tunnel/register` endpoint returns HTTP 410. An invalid named hostname fails closed (503). The browser continues to use **relative `/gateway`**, requiring no frontend URL rotation or KV writes after restart.

## Cutover procedure — only after a DNS zone is available

1. In Cloudflare **Networking → Tunnels → `tqsvn-gateway`**, configure a **Published application** with `gateway.<owned-zone>` and service `http://127.0.0.1:8080` (HTTP, not HTTPS to the local gateway). Use Cloudflare-managed DNS/CNAME pointing at this tunnel. Confirm the hostname resolves and certificates are issued. Cloudflare Pages `tqsvn.pages.dev` stays unchanged. Tunnel tokens are secrets: do not paste them into Git, logs, issue text or chat.
2. Obtain the connector token from Cloudflare's tunnel dashboard using a secure operator channel, and install it on Oracle as root-only `/etc/tqs-named-tunnel.token` (mode `0600`). The preinstalled `/etc/systemd/system/tqs-named-tunnel.service` reads the token via systemd `LoadCredential=`. Enable with `sudo systemctl enable --now tqs-named-tunnel.service`; verify `systemctl is-active tqs-named-tunnel.service`, tunnel connector status in Cloudflare, and `curl -fsS https://gateway.<owned-zone>/healthz` returning `ok`. Check the direct manifest against local `http://127.0.0.1:8080/manifest.json`. **Do not stop Quick Tunnel yet.**
3. Configure Cloudflare Pages **production** runtime binding `TQS_NAMED_TUNNEL_HOSTNAME=gateway.<owned-zone>` (prefer the project `game/web/wrangler.toml` `[vars]` once the real hostname is chosen; keep config synchronized with the dashboard). Deploy from **`game/web`** so the Pages Functions bundle is included: `npm --prefix game/web run build`, then from that directory `npx wrangler pages deploy dist --project-name tqsvn --branch main`. Validate the new deployment URL first, then `https://tqsvn.pages.dev/gateway/{healthz,manifest.json}`. Do not set the binding before the direct Named route is live.
4. Verify browser WebSocket **101 Upgrade** through Pages and execute authenticated Google login/approved game ticket, room creation/join, general selection, a native game action, and reconnect. Verify source/runtime MD5 and Page Functions at the same deployment. Capture only sanitized status/results. Existing active matches may drop while service is restarted, so run destructive restart probes in a quiet or coordinated window.
5. Once named-route HTTP, manifest, WebSocket and gameplay are healthy, change `/etc/tqs-gateway-watch.env` to `TQS_WATCH_TUNNEL_SERVICE=tqs-named-tunnel.service`, restart the one-shot watcher and inspect its state. Disable the old `tqs-tunnel-register.timer` (if enabled) and `tqs-quick-tunnel.service`. A renamed or restarted Named connector must retain **the same public DNS hostname**, require **zero KV edits**, and automatically rejoin Cloudflare after the VM reboots (`systemctl is-enabled tqs-named-tunnel.service`).
6. Record `systemctl` state, Cloudflare connector status and host/public checks before and after controlled gateway, Named Tunnel and VM restarts. Re-run authenticated login, room and WebSocket each time. For rollback, unset `TQS_NAMED_TUNNEL_HOSTNAME` and redeploy the previous Pages Functions version, then re-enable the already-tested Quick route; do not delete the Named Tunnel or secrets until rollback succeeds.

## Monitoring and acceptance

On Oracle, `tqs-gateway-watch.timer` runs every minute. The corresponding service checks native, gateway and tunnel systemd states; local/public HTTP 200 with body `ok`; local/public manifest MD5, bundle hash and file count; and the current systemd tunnel `InvocationID`. A new invocation records `tunnelRestartedAt` and starts a fresh continuous-uptime window. A missed interval over 150 seconds also resets that window.

Check `sudo cat /var/lib/tqs-gateway-watch/state.json` and `journalctl -u tqs-gateway-watch.service --since '24 hours ago'`. The testable **24-hour gate** requires `status=up`, `consecutiveFailures=0`, `healthySince` at least 24 hours ago, `consecutiveSuccesses` of approximately 1440 one-minute samples, and no gap, restart or failure across the interval. A single immediate `ok` does not satisfy this gate.

The watchdog now records an explicit `acceptance24h` boolean. It can become `true` only after a **Named Tunnel** connector has passed at least 1440 consecutive minute checks spanning 24 hours. A tunnel service change, connector restart, missed interval (>150 seconds), clock rollback or failed health/manifest request resets the streak and marks the gate false. The still-active Quick Tunnel cannot satisfy this Named Tunnel gate, regardless of how long it has been healthy. This flag covers the host-side monitoring evidence; authenticated login/room/WebSocket and controlled restart acceptance must also be validated separately.

For push alerts independent of the host, the Codex outage-watch runs hourly. For faster on-host webhook delivery, an operator may provision `/etc/tqs-gateway-watch.env` with `TQS_WATCH_ALERT_WEBHOOK=https://<private-webhook>` (file mode `0600`, never commit) and keep `TQS_WATCH_TUNNEL_SERVICE=...`; the monitor sends an outbound JSON `text`/`content` message after three failures and on recovery. A host-level outage also stops its local checks, so retain an independent external alert source.

Validation commands for this implementation:

```bash
node --test game/web/scripts/pages-gateway.test.mjs deploy/mobile/oracle-gateway-watch.test.mjs
node --check deploy/mobile/oracle-gateway-watch.mjs
ssh tqs-native-qa-replacement 'systemctl list-timers tqs-gateway-watch.timer; systemctl is-active freekill-native.service tqs-gateway.service tqs-quick-tunnel.service tqs-gateway-watch.timer'
```
