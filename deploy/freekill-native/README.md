# FreeKill native deployment

This directory is the first deployment slice for the Hegemony project. It is
intentionally separate from the existing React/Firebase storefront in this
repository.

The first target is the original FreeKill desktop client:

```text
FreeKill client -> TCP/CBOR -> freekill-asio -> freekill-core + utility + hegemony
```

The future web client stays possible because the server, package versions,
game rules and player IDs remain authoritative on the FreeKill side. A future
browser UI should be added as a WebSocket gateway beside this server, not as a
replacement for the Lua game logic.

The cost-optimized profile uses exactly one free VM, SQLite, the native client
and the public game port. It does not require Firebase, a paid database, a
domain, a CDN or a web gateway during the first phase.

## What is included

- `versions.env`: pinned release, package commits and server port.
- `server/freekill.server.config.json`: small private-group configuration.
- `scripts/bootstrap-amd64.sh`: downloads and verifies the upstream static
  amd64 release, then installs the pinned `freekill-core` and `hegemony` Git
  packages plus the `utility` dependency required by Hegemony.
- `scripts/bootstrap-source.sh`: builds the pinned `freekill-asio` source on
  Linux, which is the path for Oracle A1/ARM64.
- `scripts/install-packages.sh`: idempotently checks out the exact package
  commits and records them in `packages/packages.db`.
- `scripts/verify-install.sh`: validates executable, JSON, package commits and
  package database.
- `scripts/run-server.sh`: starts the server with the interactive admin shell.
- `scripts/backup.sh`: archives server state, packages and configuration.
- `server/freekill-native.service`: keeps the server and game firewall rules
  available after a VM reboot.

## Current status and limitation

The repository can prepare a deterministic server installation, but it cannot
create a cloud VM or open a firewall without a target cloud account/server.
The current live deployment uses the amd64 path below; a fresh deployment still
needs a Debian/Ubuntu VM and the target cloud account.

Oracle Tokyo did not have capacity for the A1 shape at deployment time, so the
live instance uses the Always Free E2 Micro fallback. It is intentionally a
small proof-of-concept host. Two native clients have entered the same room and
started a game, but a complete game and reconnect still need testing before
inviting the whole group.

The pinned upstream static artifact is amd64. Oracle Cloud A1 is ARM64, so an
Oracle A1 deployment needs the source-build path rather than this static
bootstrap. The live server is the amd64 fallback because A1 capacity was not
available in the selected region.

## Live validation

As of 2026-09-23, the live endpoint is:

```text
168.110.36.224:9527
```

The official FreeKill v0.5.25 native client was built on macOS and tested
against that endpoint. The test logged in, downloaded and verified all three
enabled packages, reached the lobby, and created a temporary Hegemony room with
`new_heg_mode`. The server remains managed by `freekill-native.service` and is
enabled for reboot.

On 2026-09-23, a second headless test used two separate native client
processes and the two existing test accounts. Both entered the same
`new_heg_mode` room, the guest sent `Ready`, and the host sent `StartGame`.
Both clients received `StartGame`, and the server logged `[GameStart]` for the
room. The first attempt exposed a test-only configuration mistake: the
headless helper omitted `_game.generalNum`, so the Hegemony Lua code failed
when choosing generals. Adding the same `generalNum` setting supplied by the
normal room creation UI removed that error. The corrected test did not play
through a full game: the headless clients disconnected immediately after
receiving `StartGame`. The server treated the disconnects as abandoned play
and applied its configured temporary IP ban. With no other players or rooms
active, the service was restarted to clear that temporary ban; TCP and UDP
port 9527 were listening afterward. A normal interactive two-player game is
still required to validate play between two humans and reconnect.

On 2026-09-24, the server configuration was reloaded with bots enabled (the
previous config was backed up as `freekill.server.config.json.pre-bots-20260924`).
The macOS GUI client created a two-seat `new_heg_mode` room, added one bot,
started the match, and let the local seat use Trust. The match finished in
round 4 with the bot winning; the server logged `[GameOver] 2, new_heg_mode,
wei, in 93s`. The replay was bookmarked and copied to the user's Documents
folder. The server also logged one Lua AI `smart_ai.lua:341` nil-prompt error
during play, so bot skill handling may need investigation if it recurs.

During package synchronization, macOS AppleDouble `._*` metadata files were
found in the server package tree. They were removed from the active package
tree and retained in a timestamped backup/quarantine, so they can be restored
if needed. The client/server file-list hashes now match.

For macOS client instructions, see `client-macos/README.md`. The official
Windows and Android artifacts can be used by other group members; all clients
should stay on the same FreeKill release line until an upgrade is tested.

## Administrator access

The owner retains administration through the VM's local FreeKill CLI. Port
9000 is intentionally not public. Attach to the persistent console over SSH:

```sh
ssh -i /path/to/ssh-key ubuntu@168.110.36.224
sudo tmux attach -t freekill-native
```

Useful commands in that console include `lsplayer`, `lsroom`, `msg`, `kick`,
`tempban`, `tempmute`, `ban`, `unban`, `whitelist` and `stat`. The initial
configuration leaves the whitelist disabled so the group can enroll; after
the approved player names are known, enable and maintain it from this console.
Use `backup.sh` before package upgrades or configuration changes.

## ARM64/source installation

On a Debian/Ubuntu Linux VM, including Oracle A1:

```sh
cd /path/to/tqs/deploy/freekill-native
sudo ./scripts/bootstrap-source.sh
sudo ./scripts/verify-install.sh
```

This installs the build dependencies, checks out the pinned `freekill-asio`
source commit, builds it locally, and then installs the same pinned packages
as the amd64 path. The source path uses the system Lua 5.4 modules.

## AMD64 installation

On a Debian/Ubuntu amd64 VM:

```sh
cd /path/to/tqs/deploy/freekill-native
sudo ./scripts/bootstrap-amd64.sh
sudo ./scripts/verify-install.sh
```

The bootstrap installs the runtime under `/opt/freekill-hegemony`, downloads
the pinned `freekill-asio` artifact, verifies its SHA-256, and checks out the
  exact `freekill-core`, `utility` and `hegemony` commits.

Start the first server in a persistent SSH session such as `tmux` so the
interactive FreeKill admin shell remains available:

```sh
sudo -s
tmux new -s freekill-native
cd /opt/freekill-hegemony/current
/opt/freekill-hegemony/current/freekill-asio --port 9527
```

Detach with `Ctrl-b d` and reattach later with:

```sh
tmux attach -t freekill-native
```

Do not expose the upstream admin HTTP port `9000` to the public Internet. The
game client port is `9527` in the pinned configuration. Apply a firewall rule
that allows SSH only from your administration source and allows the game port
for players.

For a persistent VM install, copy `server/freekill-native.service` to
`/etc/systemd/system/`, place `scripts/run-server.sh` and `versions.env` under
`/opt/freekill-hegemony/deploy/`, then run:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now freekill-native.service
sudo systemctl status freekill-native.service
```

The service starts the interactive CLI in `tmux` session `freekill-native`:

```sh
sudo tmux attach -t freekill-native
```

## Private-group configuration

The supplied configuration has:

- capacity 10, while the first gameplay target is 4–8 people;
- bots enabled so a room owner can add computer players;
- maximum two client sessions per device;
- whitelist disabled during initial enrollment;
- English/neutral MOTD;
- no game-rule changes.

After the first administrator and test accounts are registered, enable the
whitelist and add the approved player names through the FreeKill admin shell.
Do not use the package `upgrade` command casually: the deployment intentionally
pins package commits so client/server compatibility can be tested before an
upgrade.

## Backup

Run before an upgrade and after important test sessions:

```sh
sudo ./scripts/backup.sh
```

Backups contain the package checkouts, package database, server database and
configuration. Keep at least one copy outside the VM.

## Acceptance checklist before inviting the group

1. `verify-install.sh` passes.
2. Two FreeKill clients connect with the expected client/server version.
3. `hegemony` appears and a complete test game can start and finish. The
   two-client start and one-human/one-bot complete game have passed. A complete
   two-human game remains open.
4. A client reconnects after a short network interruption.
5. The administrator can inspect, kick, mute or ban according to the server
   shell capabilities.
6. Port 9000 is not reachable from the public Internet.
7. A backup can be created and restored on a test directory.
8. The exact server and package version inputs in `versions.env` are recorded
   with the test result.

## Future web path

The later web slice should add:

```text
Browser HTTPS/WSS -> web gateway -> existing FreeKill TCP/CBOR server
```

The gateway should translate transport/session messages only. It should not
duplicate Hegemony rules or make client-side decisions authoritative. Native
clients can remain connected during the web experiment, and the native port
does not need to change.
