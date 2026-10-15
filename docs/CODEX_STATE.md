# CODEX_STATE — bàn giao công việc TQS

> Cập nhật handoff: 15/10/2026 11:29 (giờ Việt Nam). Đây là trạng thái hiện hành, không phải nhật ký commit. Audit luật chi tiết nằm ở [`web-client/QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md); không lặp lại ma trận/evidence ở đây.

## Mục tiêu và phạm vi

Hoàn thiện client Tam Quốc Sát trên trình duyệt điện thoại bằng React + Wasmoon Lua + gateway, dùng FreeKill C++/Lua làm nguồn sự thật. Phạm vi hiện tại là Quốc Chiến với 14 package đang được bundle; không trộn TQSShop và không port lại luật server sang TypeScript.

## Trạng thái hiện hành

- Bản live hiện là Render candidate [`tqs-mobile-candidate`](https://tqs-mobile-candidate.onrender.com), identity **CP92**: source `c40e36a7`, runtime MD5 `c4704cd70bfbce3375c4c123a2443a3f`, 14 package, 5.279 file trong bundle, bundle hash `0183516d94e2865f`. Deployment `dep-db84u7avcj2c7387q6dg` đã báo `Deploy succeeded | Live`; public health/manifest/HTML asset probe đều PASS. Đây là candidate để test, chưa phải official release.
- **CP92 UI/runtime hotfix** đã được deploy từ nhánh Render hiện hành: build game web có 1.739 file, `RELEASE.json` v2 verify PASS với runtime MD5 `c4704cd70bfbce3375c4c123a2443a3f`, root `dist/` đã dọn và đồng bộ từ `game/web/dist`, gồm UI CP90/CP91 cùng bridge hidden-skill/Lua 5.4 hardening. Auto-deploy vẫn tắt; deployment được kích hoạt thủ công từ commit cụ thể để tránh lấy nhầm branch tip.
- Commit hotfix `f039e228` và checkpoint deploy `c40e36a7` đã push thành công lên `origin/codex/cp89-render-current`. HTML live dùng `index-DUN9EqW6.js` và `index-B2V66FPQ.css`; người dùng có thể tiếp tục smoketest trên URL candidate.
- Đã có browser → Wasmoon/Lua → gateway → FreeKill C++ live path: login/lobby/room/bot, một ván bot hoàn chỉnh, GameOver, về sảnh và disconnect sạch. Đây là bounded evidence, không phải full rule parity.
- CP90/CP91 và các sửa bridge/runtime đã được đưa vào artifact hotfix CP92; identity hosted đã được đối chiếu. Smoke test gameplay nhiều bước và official sign-off vẫn mở.
- `PLAYABLE_MOBILE` vẫn `false`. Thiết bị vật lý và mất mạng vật lý được người dùng miễn trong scope hiện tại; trạng thái là `DEFERRED/WAIVED_BY_USER`, không phải PASS.
- Audit P0 hidden-general: Lua/C++ gốc cho phép trigger skill khi tướng úp nếu đã prelight. React đã triển khai fake-skill dock, privacy/lifecycle reducer, regular-skill gate và wire `PushRequest("prelight,...")`. Native QA **PASS NATIVE-LOCAL bounded** cho ma trận lõi 12/12: Di Kế chủ/phó với negative/positive/skip, Gian Hùng chủ/phó, reveal helper chủ/phó, Chế Hành chủ/phó và Long Đảm ViewAs chủ/phó. Có thêm `hidden-fankui` chủ/phó, `hidden-dual` và `hidden-luoshen` chủ/phó PASS ở các identity staged riêng; Luoshen khóa `EventPhaseStart` → reveal đúng slot → phán xét đen/đỏ → lấy lá đen. Không gộp add-on vào identity lõi. Source projection/lifecycle/slot-route audit vẫn PASS theo số liệu canonical ở [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md). Hosted/official release matrix và exhaustive live effect matrix vẫn chưa đóng.
- Fake trigger và fake active đã tách đúng: `AddSkill/LoseSkill` chỉ nhận skill của Self; dock idle bị khóa; chỉ `SkillButton` do Lua gửi mới được kích hoạt. Native matrix đã chứng minh Di Kế, `reveal_skill&`, Chế Hành và Long Đảm ViewAs đều mở đúng slot chủ/phó trước effect.

## Evidence đã được xác nhận

| Tầng | Kết quả | Ý nghĩa |
| --- | --- | --- |
| Source/runtime | PASS | Runtime có 14 package; source contract skill/card/equipment và native caller audit không có invalid contract trong active pool. |
| Local browser/Lua | PASS | Native dialogs 7/7, cards-and-choice 3/3, card selection 4/4, store 38/38, connection 28/28, gameplay 16/16, browser E2E 20/20, Wasmoon/React E2E 63/63, QA contract 17/17; có regression Quách Gia không prelight và prelight → damage → invoke → reveal, Luoshen EventPhaseStart → judge → obtain, launcher Lua 5.4 fail-closed/module preflight, server prelight idempotency/ownership/stale-cleanup/reattach, cùng reconnect từ state thật `Client:addSkill`/`Client:loseSkill` 520/520; fixture không thay thế live C++. |
| Native caller inventory | PASS ở contract | 17 request families trên 5.264 Lua files được ánh xạ; chưa đồng nghĩa mọi caller đã chạy live. |
| Live core gameplay | PASS bounded | Ván bot C++ thật đã qua reveal, Vô Giải, Sát/target/OK, Cường Tập và GameOver. |
| Live targeted gameplay | PARTIAL | Normal rescue và một số CardChosen/Poxi/CardsAndChoice đã có evidence; cancellation/expiry/reconnect và caller còn lại chưa exhaustive. |
| Live rule edge cases | OPEN | Native-local đã PASS normal rescue, Battle Royal Peach→Analeptic và founding kingdom choice trên QA revision `5dcd…`; hosted/Oracle, round events, reward/punishment và winner transition chưa đóng. |
| Hidden trigger/prelight + active reveal | **PASS NATIVE-LOCAL bounded** | Ma trận lõi 12/12 ca C++/Lua thật; thêm `hidden-fankui` main/deputy, `hidden-dual` và `hidden-luoshen` main/deputy staged PASS với trigger bắt buộc, reveal đúng slot, card obtain/auto-discard, phán xét và ViewAs Duel. Chưa đại diện hosted/official release. |
| Hidden-skill source projection/lifecycle/slot route | **PASS SOURCE/LOCAL** | Build audit chạy 301 tướng active/602 vị trí, 1.039 reference, 520 skill ID; native `AddSkill`/`LoseSkill` 520/520, replay event qua React 521/521, privacy Add/Lose 1.042/1.042, helper `reveal_skill&` 105/105, `canUse` theo slot 205/205, route `revealBySkillName` 155.168/155.168 trên cặp hợp lệ, prelight sync 403/403, reconnect projection 520/520, actual `Client:addSkill` state 520/520 và `Client:loseSkill` 520/520 (đã bắt/sửa duplicate regular và stale lifecycle), gồm fake trigger, regular Active/ViewAs, dual projection và 15 delay-fallback loss paths. Chưa thay thế live effect matrix. |

Nguồn và ma trận đầy đủ: [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md). Evidence CP89 giữ lại để đối chiếu lịch sử; identity hiện hành là CP92.

## Mốc vừa triển khai

- Đã chốt source-law và bridge hardening: `serverplayer.lua` prelight idempotent, fake-skill reattach phát lại prelight, `room.lua` kiểm tra ownership/stale cleanup; `hostLua.ts` loại duplicate regular khi khôi phục fake snapshot. Installer/verify native đã áp dụng và kiểm tra đủ các patch này.
- Đã dựng runtime native local bằng đúng 14 package pin + `tqs_qa` server-only; cài Lua 5.4, `luasocket` và `luafilesystem` trong thư mục tạm, đọc manifest từ package thực tế. `verify-install.sh` PASS.
- Đã đóng lỗi lặp lại Lua 5.5/5.4 ở root launch path: `scripts/lua-runtime.sh` chỉ nhận binary `lua5.4`/`lua-5.4`, xác nhận `_VERSION == Lua 5.4`, prepend `rocks54` vào `LUA_PATH`/`LUA_CPATH` và preflight `socket` + `lfs` trước khi mở cổng. `run-server.sh` và `verify-install.sh` dùng chung helper; chạy thẳng binary không còn là launch path được hỗ trợ.
- Native C++/Lua local đã chạy lại trên QA revision `5dcd…` và browser artifact `d432…`: Di Kế chủ `negative/positive/skip`, Di Kế phó `positive`, Gian Hùng chủ/phó, reveal helper chủ/phó, Chế Hành chủ/phó, Long Đảm ViewAs chủ/phó, normal rescue, Battle Royal rescue/view-as và founding; tất cả PASS với hai browser client, GameOver/result/lobby/disconnect sạch. Audit/evidence chi tiết chỉ giữ trong [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md).
- Native C++/Lua local đã chạy thêm `hidden-dual` trên runtime staged: `runtimeMD5=cf6e10887c7513df25c07d0bd5c20744`, QA revision `ee71594d4826b6126f4609ccfd283976cc0c0235`, package SHA-256 `1c7ba7b22a4608e1f2ef26ce33e03a378d46c03d817ec1cdf335ff72cab469d1`, browser artifact `d432f717a938665fab8ae81a6a903aa11f1cfeaa84d5cc0fd62f07572e436893`. Server chọn đúng Lua 5.4, nạp 18 extension, log `trigger=true view_as_duel=true`; hai client PASS GameOver/result/lobby/disconnect sạch. Đây là **NATIVE-LOCAL STAGED**, không thay thế identity 12/12 cũ và không phải Oracle/production. Evidence: [`cp08-hidden-dual-multiplayer-live-1792035658085.json`](../scratch/evidence/cp08-hidden-dual-multiplayer-live-1792035658085.json).
- Native C++/Lua local đã chạy `hidden-fankui` và `hidden-fankui-deputy` trên runtime staged: `runtimeMD5=34b2aac837d7a5729c2e68030cd26b54`, QA revision `2b26c784a48ede633f886a9e60ffec723c5a9864`, package SHA-256 `a982ec72359a48bbf679b0e39bd5f5a87d2a95fd2fc0aa3ee5583c3379571d8f`, catalog SHA-256 `ae33090c050a0e8c158be3d2c7b7510a56ff2c2657220a368cf832ccb172b4b7`, browser artifact `d432f717a938665fab8ae81a6a903aa11f1cfeaa84d5cc0fd62f07572e436893`. Server chọn đúng Lua 5.4, nạp 18 extension; cả hai slot PASS GameOver/result/lobby/disconnect sạch. Evidence: [`cp93-hidden-fankui-multiplayer-live-1792037298419.json`](../scratch/evidence/cp93-hidden-fankui-multiplayer-live-1792037298419.json) và [`cp93-hidden-fankui-deputy-multiplayer-live-1792037309640.json`](../scratch/evidence/cp93-hidden-fankui-deputy-multiplayer-live-1792037309640.json). Đây là **NATIVE-LOCAL STAGED**, không phải Render/Oracle/production.
- Native C++/Lua local đã chạy `hidden-luoshen` và `hidden-luoshen-deputy` trên identity staged: `runtimeMD5=db4aada0feeaf58b26a194d60ea706d1`, QA revision `9edb6f5ea823e7b2187a8323a50cfcc7cbc413f8`, package SHA-256 `61fa33b70e859dba9a74c75defb91b550da932b04aec169dca7628c29abf9483`, catalog SHA-256 `424e143a331b46b4ce68ad0bd22656aeb604c196a16702fbc4107d4ce7f4d963`, browser artifact `d432f717a938665fab8ae81a6a903aa11f1cfeaa84d5cc0fd62f07572e436893`. Cả hai slot PASS `EventPhaseStart` → `SkillEffect` → reveal đúng slot → phán xét → lấy một lá đen → GameOver/result/lobby/disconnect sạch. Evidence nằm trong audit canonical; đây là **NATIVE-LOCAL STAGED**, không phải Render/Oracle/production.
- Local regression đã quan sát PASS: `test:qa-server-contract` 17/17, `test:store` 38/38, `test:e2e:lua` 63/63, `audit:hidden-skills`, `audit:skill-activation` 22.761 probes/0 hard failure, `typecheck`, `build`; native server dừng graceful sau test. Đây vẫn là bounded/local, không thay thế LIVE.
- Kiểm tra cài đặt lại từ máy phát triển: profile/key `tqs-native-qa` tồn tại đúng quyền local nhưng `ssh -o BatchMode=yes tqs-native-qa true` vẫn trả `Permission denied (publickey)` (exit 255). Chưa có quyền guest nên chưa cài/verify package QA hiện hành trên Oracle và không ghi nhận deploy.
- Đã thử reconnect native khi readiness `AskForSkillInvoke` của Di Kế còn pending: FreeKill hủy request khi actor disconnect rồi cho login lại, nên không coi đây là React regression; prompt-specific reconnect vẫn **OPEN** và phải kiểm riêng theo semantics request.
- Oracle VM chỉ mới được xác nhận ở mức process/port: service `freekill-native` active và 9527 reachable, nhưng chưa đọc được manifest/hash trong guest. SSH vẫn bị từ chối, Run Command chạy dưới `ocarun` không có root, OCI không cho sửa `ssh_authorized_keys`, recovery chưa vào được root shell. **Không có bằng chứng phiên này đã deploy package hiện hành lên VM.**
- Hai rerun Oracle/ngoài trước (`reconnect-failure-1792002124241.json`, `1792002605900.json`) fail trước QA gate do thiếu/chưa xác định `tqs_qa`; runner đã fail-fast đúng boundary package/config. Không dùng chúng để kết luận lỗi luật React.
- Hotfix CP92 đã package, deploy và probe PASS trên Render; `PLAYABLE_MOBILE=false`, full parity/P0 live interaction/rescue/wild/founding và official release vẫn mở.
- Invariant quan trọng sau reveal: source gốc gỡ fake skill và chuyển sang regular trước `SkillEffect`, không tự xóa `prelighted_skills`; tài liệu canonical đã ghi để tránh review nhầm hide/transform/swap.

## Việc còn mở theo thứ tự

1. **P0 gameplay:** xác minh guest access, cài/verify đúng QA/package identity trên Oracle hoặc hosted target rồi rerun normal rescue, Battle Royal rescue/view-as và founding; native-local đã PASS nhưng không thay thế LIVE.
2. **P0 native interaction:** hoàn tất live matrix cho CardChosen, Poxi, CardsAndChoice, ArrangeCards, AG, MoveCardInBoard, SkillInvoke và CustomDialog; kiểm tra cancel/expiry/cleanup/reconnect theo semantics từng request.
3. **P1 presentation/release:** mở smoketest CP92 cho người dùng; sau đó xử lý residual translation, official release, cold-start/quota/rollback/SLA và `PLAYABLE_MOBILE`.

## Nguyên tắc cho phiên sau

- `SOURCE` chỉ chứng minh code tồn tại; `LOCAL` chỉ chứng minh fixture/VM; `NATIVE-LOCAL` chứng minh browser kết nối C++ thật trong runtime cô lập; `LIVE` mới là candidate/hosted release. Luôn ghi rõ tầng evidence.
- Không port luật gốc sang React và không “auto-select” để vượt qua request chưa hỗ trợ.
- Không đánh dấu PASS theo số file, số skill hoặc số smoke test. Mỗi ticket phải có scenario và acceptance riêng.
- Bảo toàn toàn bộ thay đổi dirty hiện có; không reset/clean/checkout ghi đè hoặc commit thay người dùng.
- Sau mốc đáng kể: cập nhật ticket trong [`CODEX_PLAN.md`](CODEX_PLAN.md), cập nhật phần handoff này, rồi chạy `npm run codex:checkpoint`.

## Bước tiếp theo có thể chạy ngay

Dùng [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md) và hướng dẫn [`tqs_qa/README.md`](../deploy/freekill-native/qa/tqs_qa/README.md) làm checklist bounded P0. Bước external tiếp theo là hoàn tất guest admin/recovery path để xác nhận `ssh tqs-native-qa`, sau đó install/verify `tqs_qa` trên chính Oracle VM và lấy manifest từ package thực tế. Không dùng manifest tái dựng làm bằng chứng cài đặt; không deploy CP90/CP91 hoặc chuyển `PLAYABLE_MOBILE` nếu chưa có evidence tương ứng.

## Ảnh chụp Git (tự động)

<!-- CODEX_SNAPSHOT_START -->
- Ghi lúc: 2026-10-15T04:30:49.772Z (UTC).
- Nhánh: `codex/cp89-render-current` · HEAD: `9edb6f5ea823`.
- File thay đổi hiển thị: 3 (đã ẩn tên file có thể nhạy cảm và không tính chính tài liệu này).

```text
 M deploy/freekill-native/qa/tqs_qa/README.md
 M docs/CODEX_PLAN.md
 M docs/web-client/QUOC_CHIEN_RULE_AUDIT.md
```

Ba commit gần nhất:

```text
9edb6f5e fix: distinguish luoshen gate from trigger invoke
547674eb fix: close hidden luoshen scenario predicate
624aed37 test: cover hidden luoshen phase trigger
```

> Ảnh chụp này chỉ phản ánh metadata Git lúc chạy lệnh. Để biết trạng thái **ngay bây giờ**, chạy `git status --short`; không suy diễn PASS từ danh sách file.
<!-- CODEX_SNAPSHOT_END -->
