# Free-only deployment profile

## Chosen architecture

```text
FreeKill desktop clients
          │ TCP/UDP 9527
          ▼
One Oracle Always Free E2 Micro x86_64 Linux VM
  ├── freekill-asio
  ├── freekill-core
  ├── utility
  ├── hegemony
  └── SQLite + local logs
```

This profile is intentionally native-client-first. It does not use Firebase,
Cloud Run, Render, a managed database, a paid object store, a custom domain or
a web gateway. The future browser gateway can be added to the same VM later,
or moved to another free/paid host without changing the game server protocol.

## Cost policy

| Resource | Decision | Cost target |
|---|---|---:|
| Compute | One Oracle E2 Micro Always Free VM | 0 |
| Game runtime | FreeKill/asio + Lua packages | 0 |
| Database | SQLite on the VM | 0 |
| Client | Original FreeKill desktop client | 0 |
| Domain | Not used initially; connect by IP | 0 |
| TLS/WSS | Deferred with the web gateway | 0 |
| Backup | Download encrypted archives to the owner’s computer | 0 |
| Monitoring | SSH, logs and local checks | 0 |
| Web frontend | Deferred | 0 |

## Limits

- Keep the server private and target 4–8 people.
- E2 Micro has 1 GB RAM and a 1/8 OCPU AMD allocation with burst capacity; use
  the pinned static amd64 runtime and avoid compiling on the VM.
- Do not host unrelated websites or databases on the VM.
- Do not open the admin HTTP port 9000 to the Internet.
- Keep only one VM and one running game instance until the native smoke test
  passes.
- Do not add paid billing to Firebase or cloud services during this phase.
- Do not add a custom domain just for the first test.

## Current deployment state

The first Oracle VM is provisioned in Tokyo as `VM.Standard.E2.1.Micro`
(Ubuntu 24.04 x86_64). The server is managed by
`freekill-native.service`, keeps its admin CLI in a root `tmux` session, and
opens only game port 9527 publicly. The upstream Admin HTTP port 9000 is
bound on the VM for local administration but is not allowed by either the OCI
security list or the Ubuntu host firewall.

## First external action

If this deployment needs to be recreated, create one Linux VM in an Oracle
Always Free tenancy. Use ARM64/A1 if available, then run:

```sh
cd /tmp/freekill-native
sudo ./scripts/bootstrap-source.sh
sudo ./scripts/verify-install.sh
```

If A1 capacity is unavailable, use an E2 Micro or another free amd64-compatible
provider and run `bootstrap-amd64.sh` instead. The free profile is suitable
for a private proof of concept, not an uptime guarantee.
