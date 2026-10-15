# CODEX_PLAN — đường đi đến Tam Quốc Sát mobile chơi được

> Cập nhật 15/10/2026 10:52 (giờ Việt Nam). Đây là bảng gate và backlog hiện hành, không phải nhật ký commit. Phân tích luật canonical nằm ở [`web-client/QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md); handoff ngắn nằm ở [`CODEX_STATE.md`](CODEX_STATE.md).

## Phạm vi và quy ước nghiệm thu

- FreeKill C++/Lua và package pin là nguồn sự thật của luật; React chỉ làm projection, interaction và transport.
- Scope hiện tại là `new_heg_mode` với 14 package đang có trong live manifest. Nếu thu hẹp scope, phải ghi rõ package/scenario được loại khỏi acceptance.
- `SOURCE` = code tồn tại; `LOCAL` = fixture/VM/browser test; `NATIVE-LOCAL` = browser → gateway → FreeKill C++ thật trong runtime cô lập; `LIVE` = cùng luồng trên candidate/hosted release; `BOUNDED` = chỉ scenario đã chạy.
- Không dùng số file, số skill, smoke test hoặc source contract để suy ra full rule parity.
- Physical iOS/Android và physical Wi-Fi/4G là `WAIVED_BY_USER/DEFERRED`, không phải PASS. `PLAYABLE_MOBILE` và official release vẫn cần các gate riêng.

## Gate hiện hành

| Gate | Trạng thái | Đã chứng minh | Còn thiếu |
| --- | --- | --- | --- |
| G0 build/runtime | **PASS bounded** | Build và local regression đã pass trên checkout hiện hành. | Rerun release verifier trước mỗi artifact mới. |
| G1 protocol/login | **PASS live** | Browser + Wasmoon + gateway + C++ thật đến lobby. | Không còn blocker P0 đã biết; giữ canary. |
| G2 bridge/Lua | **PASS bounded** | Lua lifecycle, request/reply, projection và launcher native fail-closed cho Lua 5.4 + module preflight. | Exhaustive native binding semantics chưa đóng; Oracle/hosted chưa verify launcher mới. |
| G3 lobby/room/bot | **PASS live** | Tạo phòng, chọn tướng, bot và start game trên candidate. | Không dùng để suy ra full rule coverage. |
| G4 card/target/skill | **PASS bounded** | Sát/target/OK, Vô Giải, reveal, Cường Tập trong live bot path. | T06–T08, response/view-as và native dialog matrix. |
| G5 bot game | **PASS bounded** | Có ván bot C++ thật đi tới GameOver và về sảnh. | Một ván không chứng minh mọi luật/tướng/card. |
| G6 multiplayer/reconnect | **PASS browser bounded** | Two-account và controlled reconnect đã có evidence. | Physical network waived; prompt-specific reconnect còn cần matrix; native hủy `AskForSkillInvoke` đang pending khi actor disconnect. |
| G7 release | **CANDIDATE LIVE + CP92 HOTFIX READY** | CP89 health/manifest/bundle identity và hosted smoke pass; CP92 UI/runtime artifact đã package/verify local, commit `f039e228` đã push. | Render đang bảo trì/login và auto-deploy off; deploy/probe CP92, full gameplay, official sign-off, cold-start/quota/rollback/SLA. |
| `PLAYABLE_MOBILE` | **FALSE** | — | Chỉ đóng sau khi P0 gameplay/native interaction và release criteria pass. |

## Backlog ưu tiên

- [ ] **GAME-03A — live native interaction matrix (P0):** CardChosen, Poxi, CardsAndChoice, ArrangeCards, AG, MoveCardInBoard, SkillInvoke và CustomDialog. Mỗi family cần success; cancel/expiry/cleanup/reconnect nếu request có semantics đó. Không gộp local fixture vào PASS live.
- [ ] **GAME-03B — state/privacy parity (P0):** Self hidden/reveal, public opponent projection, equipment, xích, úp mặt, negative HP, processing card và semantic marks; kiểm tra sau reconnect. Local đã có projection regular `AddSkill/LoseSkill` của self, phân loại fake trigger/fake active, host reconnect snapshot projection 520/520 trên toàn bộ hidden skill ID (trigger/active/dual/delay-fallback), probe actual `Client:addSkill(..., true)` 520/520 và `Client:loseSkill(..., true)` 520/520 sau khi sửa duplicate regular/stale lifecycle, source audit hidden-skill Add/Lose 520/520, route `revealBySkillName` 155.168/155.168 trên cặp hợp lệ, regression Quách Gia úp → prelight → damage → invoke → reveal và chặn activation nếu không có prelight; reducer `ChangeSelf`, delay-fallback loss và thứ tự `SelfGenerals` trước public roster đã được sửa, nhưng chưa thay thế live state matrix.
- [x] **GAME-03D — hidden-trigger reveal/prelight (P0; bounded acceptance):** NATIVE-LOCAL đã PASS **12/12 ca lõi trên cùng identity**: Di Kế chủ `negative/positive/skip`, Di Kế phó `positive`, Gian Hùng chủ/phó, `reveal_skill&` chủ/phó, Chế Hành chủ/phó và Long Đảm ViewAs chủ/phó. Thêm `hidden-dual` staged PASS để khóa trigger bắt buộc → chọn người → discard → ViewAs Duel khi tướng còn úp; không gộp nó vào identity 12/12 cũ. Source/LOCAL gate hiện PASS gồm source-law contract Quách Gia/reveal-before-effect, Add/Lose 520/520, route `revealBySkillName` 155.168/155.168 và Lua 5.4 launcher/module preflight. Ticket này đóng ở tầng bounded; chưa phải hosted/official và chưa là exhaustive live effect matrix. Chi tiết ở [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md).
- [ ] **GAME-03C — rescue and Hegemony edge rules (P0):** NATIVE-LOCAL bounded đã PASS `rescue-normal`, Battle Royal Peach→Analeptic/view-as và `founding` kingdom choice trên QA revision `5dcd…`; còn hosted/Oracle rerun, round events, reward/punishment, wild state transition và winner transition. Failure phải được phân loại server pin/bridge/renderer trước khi sửa.
- [ ] **UI-01 — live translation cleanup (P1):** xử lý residual runtime text (`由于`, `观看了`, `的手牌`, `定澜夜明珠`) và kiểm tra lại artifact live; static audit không đủ.
- [ ] **UI-02 — pack pool live acceptance (P1):** kiểm disabled GeneralPack/CardPack trên C++ thật với đúng manifest, không chỉ local room-pool fixture.
- [ ] **UI-03 — board presentation live acceptance (P1):** Đã hoàn tất cải tổ UI/UX toàn diện 5 Category theo chuẩn FreeKill/QSGS trên source và test local 100% pass (`test:e2e` 20/20, `test:e2e:lua` 63/63, build pass); CP92 hotfix đã đóng gói 1.739 web files, pending Render deploy/probe để người dùng smoketest.
- [ ] **G7 — official release/operations (P1):** release identity duy nhất giữa source/runtime/web/gateway; cold-start/quota, rollback rehearsal, monitoring và SLA decision. Candidate không tự chuyển thành official.

## Evidence đã đóng, không mở lại nếu không có thay đổi identity

- **G1/G3:** hosted login/lobby/room/bot với candidate.
- **G4/G5 bounded:** ván bot C++ thật đã đi qua reveal, Vô Giải, Sát/target/OK, Cường Tập và GameOver.
- **G6 bounded:** browser two-account/controlled reconnect, GameOver/result/lobby/disconnect.
- **Source/local contracts:** skill/card/equipment activation, native caller mapping, dialog/card/store/gameplay fixtures, fake-skill/prelight bridge, regular-skill activation gate, source-law contract cho hidden Yiji/reveal-before-effect, server prelight idempotency/ownership/stale-cleanup/reattach, reconnect duplicate suppression và actual add/lose lifecycle; QA contract **15/15** gồm launcher Lua 5.4 fail-closed/module preflight; matrix hidden chủ/phó đã có thêm NATIVE-LOCAL proof bounded.
- **Hidden-skill source projection/lifecycle/slot route:** build audit 301 tướng active/602 vị trí, 1.039 reference, 520 skill ID; native `AddSkill` và `LoseSkill` đều 520/520 PASS, replay event qua React 521/521, privacy Add/Lose 1.042/1.042, helper `reveal_skill&` 105/105 Add/Lose, 205/205 `canUse` theo slot, route `revealBySkillName` 155.168/155.168 trên cặp hợp lệ, 403/403 prelight sync, 520/520 reconnect snapshot projection trên toàn bộ hidden skill ID, 520/520 actual `Client:addSkill` state và 520/520 actual `Client:loseSkill` lifecycle (regular/trigger/dual), gồm 15 delay-fallback loss paths. Inventory runtime thêm 92 active, 31 ViewAs, 418 trigger effect, 92 status effect trên 57 event kinds để làm checklist native tiếp theo. Đây là projection/lifecycle/route coverage, không phải live effect coverage.
- **GAME-03D NATIVE-LOCAL:** evidence 12/12 hidden-trigger/prelight lõi trên cùng identity, cộng một `hidden-dual` staged identity; evidence được giữ duy nhất trong [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md), chưa đại diện hosted/official hoặc exhaustive effect matrix.
- **GAME-03C NATIVE-LOCAL bounded:** normal rescue, Battle Royal rescue/view-as và founding request đã PASS trên cùng runtime/package identity `5dcd…`; evidence chi tiết nằm ở audit, không coi là hosted/Oracle.
- **CP89 candidate:** Render health, 14-package manifest, bundle hash và asset probes.

Các evidence trên chỉ đóng đúng phạm vi ghi ở đây. Khi runtime MD5, package list, bundle hoặc server pin đổi, phải chạy lại acceptance tương ứng.

## Thứ tự thực hiện phiên kế tiếp

1. **Đã hoàn tất NATIVE-LOCAL bounded:** runtime native cô lập được dựng bằng đúng package pin, installer đã cài `tqs_qa` server-only và `verify-install.sh`/`verify-qa-package.sh` PASS; QA revision `5dcd…` đã PASS Di Kế chủ/phó, normal rescue, Battle Royal rescue/view-as và founding request; staged revision `ee715…` đã PASS thêm `hidden-dual` và launcher Lua 5.4/module preflight. Không coi đây là Oracle/LIVE. Với Oracle VM, hai rerun trước (`reconnect-failure-1792002124241.json`, `reconnect-failure-1792002605900.json`) fail trước QA gate vì package/config chưa xác định; service/port reachable không chứng minh parity.
   **Blocker Oracle còn nguyên:** SSH vẫn `Permission denied (publickey)`; Run Command chỉ chạy dưới `ocarun`, `sudo -n` yêu cầu mật khẩu; OCI không cho sửa `ssh_authorized_keys`; recovery/reboot có kiểm soát chưa vào được root shell. Cần guest admin credential hoặc recovery có kiểm soát để đọc manifest/hash trong `/opt/freekill-hegemony/current`, rồi mới install/verify package thực tế. Không dùng evidence NATIVE-LOCAL để suy ra hosted/official.
2. Hoàn tất P0 native interaction matrix và phần rescue/wild còn thiếu sau request (round events, state phe, reward/punishment, winner); hosted/Oracle rerun phải ghi request, renderer, reply và state sau reply vào [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md).
3. Deploy CP92 hotfix lên Render, đối chiếu deployment SHA/health/manifest và mở smoke test cho người dùng; không nâng mức gate chỉ từ việc push branch.
4. Cập nhật bảng gate và `CODEX_STATE.md`, rồi chạy `npm run codex:checkpoint`.

## Quy tắc cập nhật tài liệu

- Mỗi ticket chỉ có một dòng trạng thái hiện hành ở tài liệu này.
- Chi tiết test đặt ở audit/evidence path; không chép lại toàn bộ log vào plan.
- `PASS` phải có ngày, scenario, identity và tầng evidence. `PARTIAL`, `OPEN`, `DEFERRED` không được làm mờ bằng số liệu local.
- Không đánh dấu `PLAYABLE_MOBILE` hoặc official chỉ vì candidate đã deploy.
