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
  commits, applies the three hidden-skill prelight hardenings, and records them
  in `packages/packages.db`.
- `scripts/verify-install.sh`: validates executable, JSON, all 14 pinned
  package commits, enabled flags, package database hashes and the hidden-skill
  prelight source contract.
- `scripts/run-server.sh`: starts the server with the interactive admin shell.
- `scripts/backup.sh`: archives server state, packages and configuration.
- `scripts/verify-backup.sh`: checks backup permissions, archive paths and the
  required configuration/package/server roots before any restore rehearsal.
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

## Historical validation — old VM

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

## Render candidate vs Oracle VM

These are two separate layers and must be verified independently:

| Layer | Current target | Responsibility | What it proves |
| --- | --- | --- | --- |
| Render | `tqs-mobile-candidate.onrender.com` | React web bundle, browser transport and hosted candidate release | Published artifact, health, login/lobby and bounded gameplay route are reachable |
| Oracle VM | `161.33.209.212:9527` (`freekill-hegemony-qa`) | FreeKill C++/Lua process, pinned packages, server state and native rules | Replacement package/process are installed, responding and match the hosted runtime identity |

The intended production path remains **browser → Render web/gateway →
FreeKill native on the VM**. The current deployment is pinned to
`FK_HOST=161.33.209.212` in `render.yaml` and the Render service; CP09 health,
manifest, login and hidden Fuyin main/deputy have verified the route on the
current release identity. This is bounded parity, not exhaustive rule coverage
or an official release.

## Administrator access

The owner retains administration through the VM's local FreeKill CLI. Port
9000 is intentionally not public. Attach to the persistent console over SSH:

### Oracle target record

This is the operational record for the existing Oracle host. It is kept here
so a later session does not confuse the Render web candidate with the native
VM:

```text
Instance:       freekill-hegemony
OCID:           ocid1.instance.oc1.ap-tokyo-1.anxhiljrqlk7czacaimrirsrg6zgnlrvhokggofuknqzjpgggyuszeybuqsa
Region:         ap-tokyo-1 (Japan East/Tokyo)
Public IPv4:    168.110.36.224
Private IPv4:   10.0.0.35
Shape:          VM.Standard.E2.1.Micro
Image:          Canonical Ubuntu 24.04
Guest user:     ubuntu
Native port:    9527
```

The VM and boot volume have not been deleted or reinstalled. Controlled
graceful reboots have returned to a normal Ubuntu boot and the
`freekill-native.service` unit has started again. As of the latest recovery
attempt, no guest file has been changed and the extra Ed25519 key has not yet
been installed in `ubuntu`'s `authorized_keys`; therefore SSH guest access is
still **PENDING**, not PASS. Do not label the VM `LIVE` until the package
manifest and the installed `tqs_qa` identity have been read on the VM itself.

```sh
ssh -i /path/to/ssh-key ubuntu@168.110.36.224
sudo tmux attach -t freekill-native
```

Trên máy phát triển hiện tại đã lưu một SSH profile cục bộ tên `tqs-native-qa`
(`~/.ssh/config`, dùng key `~/.ssh/tqs-native-qa`). Hồ sơ truy cập này được
lưu ở máy cục bộ, không ghi private key vào repository:

```text
Host alias:       tqs-native-qa
Host:             168.110.36.224
User:             ubuntu
IdentityFile:     ~/.ssh/tqs-native-qa
Key fingerprint:  SHA256:eDNynrUrAW0NqI74OOT3Lyj37QMH/6kP8eiqZfdRCgw
Public key file:  ~/.ssh/tqs-native-qa.pub
```

Có thể dùng lệnh ngắn sau sau khi public key tương ứng đã được thêm vào
`ubuntu:~/.ssh/authorized_keys`:

```sh
ssh tqs-native-qa
sudo tmux attach -t freekill-native
```

Việc tạo profile/key cục bộ không tự cấp quyền trên VM. Oracle Cloud đã được
cấu hình dynamic group `tqs-freekill-run-command` (chỉ khớp instance
`freekill-hegemony`) và policy `tqs-freekill-run-command-execution` cho
`instance-agent-command-execution-family`. VM báo Ubuntu; Run Command cũ đã
`EXPIRED`, nhưng health command mới đã `ACKED`/`SUCCEEDED`, exit code 0, và
trả về user agent `ocarun` cùng hostname VM. Kiểm tra `sudo -n` cho thấy agent
không có quyền root (`sudo: a password is required`), nên agent path không thể
tự ghi `ubuntu:~/.ssh/authorized_keys`; guest admin credential hoặc recovery
root shell vẫn cần thiết trước khi `ssh tqs-native-qa` có thể PASS. Instance
Console Connection của OCI yêu cầu RSA public key riêng; không dùng key
Ed25519 của alias SSH trực tiếp cho serial console. Connection mới dùng
fingerprint đúng và đã vào login prompt Ubuntu; guest credential thử nghiệm bị
từ chối. Key RSA dành riêng cho serial console được lưu cục bộ tại
`~/.ssh/tqs-native-qa-console-rsa` (public fingerprint
`SHA256:nwh9RXfbFO1qtZd77dts6VRsyEu2SwDN2+V8B4mDc/s`). Không dùng private key
này cho SSH thường và không sao chép private key vào tài liệu.

### Replacement VM record

The existing VM is intentionally preserved. A replacement was created on
2026-10-15 with the SSH key present at creation time, so recovery access is no
longer required for the next install attempt:

```text
Instance:        freekill-hegemony-qa
OCID:            ocid1.instance.oc1.ap-tokyo-1.anxhiljrqlk7czac5lxmhmk7cshy63b6td3qb6kuaig3hblz2dqsxmisbx7q
Region:          ap-tokyo-1 (Japan East/Tokyo)
Public IPv4:     161.33.209.212
Private IPv4:    10.0.0.78
Shape:           VM.Standard.E2.1.Micro
Image:           Canonical Ubuntu 24.04 (2026.09.18-0)
Guest user:      ubuntu
Native port:     9527
SSH alias:       tqs-native-qa-replacement
SSH key:         ~/.ssh/tqs-native-qa
SSH fingerprint: SHA256:eDNynrUrAW0NqI74OOT3Lyj37QMH/6kP8eiqZfdRCgw
Status:          RUNNING; SSH PASS; native verify PASS; tqs_qa verify PASS;
                 Jueqing/Jianxiong and 30-variant native-QA + hosted
                 main/deputy PASS; Fuyin current CP09 main/deputy PASS;
                 full parity OPEN
```

Observed SSH verification on the replacement: `id`, hostname and the
presence of `tqs-native-qa@tqs` in `/home/ubuntu/.ssh/authorized_keys` all
passed. The replacement now has Lua 5.4.8, the pinned 14-package registry,
the verified server-only `tqs_qa` package and an enabled `freekill-native`
service listening on port 9527. The old VM remains untouched and is the
rollback/reference host. It is a **QA-verified native target**, not an
official/public release.

The verified replacement identity is recorded here so a later session can
recreate the exact runner without guessing:

```text
Runtime:          /opt/freekill-hegemony/current
Static release:   freekill-asio v0.1.17 amd64
Runtime flist MD5: 43b6cdade072b75f93b9d49b3384f08f
Package registry: 14/14 pinned commits and enabled flags verified
Lua runtime:      Lua 5.4.8; LuaSocket + LuaFileSystem loaded
QA revision:      cbd2e685b7ea9a91b8685c3563083803968afdd5
QA package SHA:   2d829d02414c326a119ac3cb214df9214092f0153b5f484c04297b4e79621f6b
QA catalog SHA:   704f5bd388dc03f3a8a0776d2517f993c677bf6562629d843793aaa22d3e8a7c
QA config:        enabled; room prefix TQSQA/; two private allowlisted accounts
QA path:          /opt/freekill-hegemony/current/qa_packages/tqs_qa
Public QA path:   packages/tqs_qa absent; no packages.db row
Service:          freekill-native.service enabled/active; TCP 9527 reachable
```

`qa_packages/tqs_qa` is deliberately outside the public `packages/` namespace.
`run-server.sh` creates a broken runtime-only symlink while the native process
calculates the public `flist.txt` MD5, then activates the symlink after port
9527 is listening. This lets the QA director load on Oracle without changing
the public Render/Oracle release identity. The current CP09 Fuyin main/deputy
proof passes with this arrangement; the earlier 51-run corpus remains
historical and does not close the exhaustive 607-pair rule matrix.

```sh
ssh tqs-native-qa-replacement 'id; hostname'
```

The recovery notes below apply only to the preserved old VM. OCI cũng từ chối thay đổi `ssh_authorized_keys` sau khi instance đã tạo, kể cả
khi giữ lại key RSA hiện hữu và nối thêm key Ed25519. Nếu OCI báo đã có một
console connection active, chỉ xoá **console connection tạm thời** ở bảng
`OS Management → Console connection`, rồi tạo lại bằng public key RSA nói trên;
thao tác này không xoá VM, boot volume hay dữ liệu. Sau khi connection mới
active, dùng đúng lệnh `Copy serial console connection for Linux/Mac` mà OCI cung cấp, rồi
đăng nhập console bằng key `~/.ssh/tqs-native-qa-console-rsa`.

Recovery reboot gần nhất không bắt được GRUB nhưng đã trở lại normal boot; chưa
có guest file nào bị sửa và chưa xác nhận được `ssh tqs-native-qa`. Khi vào được
root shell, thêm đúng public key trong `~/.ssh/tqs-native-qa.pub` vào
`/home/ubuntu/.ssh/authorized_keys`, đặt owner `ubuntu:ubuntu`, mode thư mục
`700` và mode file `600`, reboot bình thường, rồi kiểm tra:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=8 tqs-native-qa true
ssh tqs-native-qa 'id; hostname; systemctl is-active freekill-native; ss -lntp | grep 9527 || true'
```

Các lệnh trên vẫn là checklist cho old VM `tqs-native-qa`; không áp dụng cho
replacement alias `tqs-native-qa-replacement`, vì alias mới đã được xác minh
trực tiếp. Không dùng kết quả NATIVE-LOCAL để suy ra package identity của VM.

> Ghi chú lịch sử của old VM: các lần kiểm tra trước chỉ thấy service/listener
> và chưa đọc được package identity. Không áp dụng kết luận đó cho
> `freekill-hegemony-qa`; replacement đã chạy `verify-install.sh`,
> `verify-qa-package.sh` và Oracle QA bounded thành công.

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
as the amd64 path. The source path installs and verifies the system Lua 5.4
interpreter plus LuaSocket and LuaFileSystem modules.

## AMD64 installation

On a Debian/Ubuntu amd64 VM:

```sh
cd /path/to/tqs/deploy/freekill-native
sudo ./scripts/bootstrap-amd64.sh
sudo ./scripts/verify-install.sh
```

The bootstrap installs the runtime under `/opt/freekill-hegemony`, downloads
the pinned `freekill-asio` artifact, verifies its SHA-256, and checks out the
exact package commits plus the Lua 5.4, LuaSocket and LuaFileSystem system
packages required by the room worker.

Start the first server in a persistent SSH session such as `tmux` so the
interactive FreeKill admin shell remains available:

```sh
sudo -s
tmux new -s freekill-native
cd /opt/freekill-hegemony/deploy
./scripts/run-server.sh
```

Always start through `scripts/run-server.sh`. The upstream native binary
launches its room worker with the literal `lua5.4` command; the wrapper
selects a verified Lua 5.4 executable, prepends the runtime-local module
paths, and checks that LuaSocket and LuaFileSystem load before opening the game
port. A generic `lua` command (including Lua 5.5) is intentionally rejected,
so a version mismatch fails immediately instead of accepting logins and then
crashing when the first room starts. `scripts/verify-install.sh` runs the same
preflight.

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

Before any restore rehearsal, verify the archive without extracting it:

```sh
sudo ./scripts/verify-backup.sh /path/to/freekill-hegemony-<timestamp>.tar.gz
```

The verifier requires an owner-only `0600` archive, rejects absolute and
parent-directory paths, and requires the configuration, package and server
roots. It is a safety check, not a restore operation. Extract only into a
new, isolated test directory first; never overwrite the live runtime as the
first restore step.

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
7. A backup can be created, passes `verify-backup.sh`, and can be restored on
   a new test directory without overwriting the live runtime.
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
