# CODEX_STATE — bàn giao công việc TQS

> Cập nhật handoff: 15/10/2026 16:20 (giờ Việt Nam). Đây là trạng thái hiện hành, không phải nhật ký commit. Audit luật chi tiết nằm ở [`web-client/QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md); không lặp lại ma trận/evidence ở đây.

## Mục tiêu và phạm vi

Hoàn thiện client Tam Quốc Sát trên trình duyệt điện thoại bằng React + Wasmoon Lua + gateway, dùng FreeKill C++/Lua làm nguồn sự thật. Phạm vi hiện tại là Quốc Chiến với 14 package đang được bundle; không trộn TQSShop và không port lại luật server sang TypeScript.

## Trạng thái hiện hành

- Bản live hiện là Render candidate [`tqs-mobile-candidate`](https://tqs-mobile-candidate.onrender.com), effective identity **CP96 UI hotfix trên runtime CP92**: UI artifact `0cc0d346`, runtime MD5 `c4704cd70bfbce3375c4c123a2443a3f`, 14 package, 5.279 file trong bundle, bundle hash `0183516d94e2865f`. Latest redeploy `dep-db89kson74is73eakr6g` từ HEAD `74a7b30e` đã báo `Deploy succeeded | Live`; HEAD chỉ chứa QA/docs/harness, không đổi `game/web/src`, `dist`, `gateway` hoặc `runtime`. Public health và asset probe PASS; đây là candidate để test, chưa phải official release.
- **CP96 UI hotfix** đã được push và deploy thủ công từ `origin/codex/cp89-render-current`: build game web có 1.739 file, root `dist/` được đồng bộ sạch từ `game/web/dist`, gồm tooltip card qua portal, IdleHandCard đồng nhất 4 lớp, dịch prompt/log còn sót, chất `NoSuit`, điều chỉnh vị trí/kích thước seat và tăng khả năng đọc trên bàn mobile. HTML live dùng `index-B7bZuyxk.js` và `index-7DaeryPw.css`; HTML SHA-256 `4e7ab8fb6305ef969ec820d6fda7a1944c2d8b0b89169ff433200e48be1f5566`, JS `7d8ddd939fe409748aea0f1f51ce1f96a31c9131aceb639041f4c994e6c40638`, CSS `34aa37b8e49449193553c24de4b34392617e5e95e05556d112605407d63b6b75`. Latest redeploy `dep-db89kson74is73eakr6g` từ HEAD `74a7b30e` giữ nguyên byte identity; auto-deploy vẫn tắt.
- Commit UI `0cc0d346` đã push thành công; người dùng có thể tiếp tục smoketest trên URL candidate. Runtime/package identity không đổi so với CP92.
- Đã có browser → Wasmoon/Lua → gateway → FreeKill C++ live path: login/lobby/room/bot, một ván bot hoàn chỉnh, GameOver, về sảnh và disconnect sạch. Đây là bounded evidence, không phải full rule parity.
- CP90/CP91, các hotfix UI CP93/CP94/CP96 và các sửa bridge/runtime đã được đưa vào artifact candidate; identity hosted đã được đối chiếu. Smoke test gameplay nhiều bước và official sign-off vẫn mở.
- `PLAYABLE_MOBILE` vẫn `false`. Thiết bị vật lý và mất mạng vật lý được người dùng miễn trong scope hiện tại; trạng thái là `DEFERRED/WAIVED_BY_USER`, không phải PASS.
- Audit P0 hidden-general: Lua/C++ gốc cho phép trigger skill khi tướng úp nếu đã prelight. React đã triển khai fake-skill dock, privacy/lifecycle reducer, regular-skill gate và wire `PushRequest("prelight,...")`. Native QA **PASS NATIVE-LOCAL bounded** cho ma trận lõi 12/12, các staged add-on trước đó, Xiaoji `2/2`, Guanxing `2/2`, 英姿 `2/2`, Thiên Hương `2/2`, Đoạn Trường `2/2` và regression Di Kế re-hide `2/2` main/deputy. Regression mới đã khóa `SkillEffect` reveal đúng slot → Di Kế chuyển 2 lá → `hideGeneral()` → fake `hs__yiji` vẫn prelight, `hasSkill` đúng và không có regular duplicate; 英姿 khóa `DrawNCards` `2→3` và rút thật 3 lá. Catalog/source scenarios hiện **49/49**, `test:qa-server-contract` **30/30** subtests. Không gộp add-on vào identity lõi. Source projection/lifecycle/slot-route audit vẫn PASS theo số liệu canonical ở [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md). Hosted/official release matrix và exhaustive live effect matrix vẫn chưa đóng.
- Fake trigger và fake active đã tách đúng: `AddSkill/LoseSkill` chỉ nhận skill của Self; dock idle bị khóa; chỉ `SkillButton` do Lua gửi mới được kích hoạt. Native matrix đã chứng minh Di Kế, `reveal_skill&`, Chế Hành và Long Đảm ViewAs đều mở đúng slot chủ/phó trước effect.

## Evidence đã được xác nhận

| Tầng | Kết quả | Ý nghĩa |
| --- | --- | --- |
| Source/runtime | PASS | Runtime có 14 package; source contract skill/card/equipment và native caller audit không có invalid contract trong active pool. |
| Local browser/Lua | PASS | Native dialogs 7/7, cards-and-choice 3/3, card selection 4/4, store 38/38, connection 28/28, gameplay 16/16, browser E2E 20/20, Wasmoon/React E2E 63/63, catalog/source scenarios 49/49 và `test:qa-server-contract` 30/30 subtests; gồm Xiaoji, Guanxing, 英姿, Thiên Hương, Đoạn Trường, Di Kế re-hide, Jizhi, Mingshi, Qianxun, Kongcheng, Weimu, launcher Lua 5.4 fail-closed/module preflight và lifecycle/reconnect audits; fixture không thay thế live C++. |
| Native caller inventory | PASS ở contract | 17 request families trên 5.264 Lua files được ánh xạ; chưa đồng nghĩa mọi caller đã chạy live. |
| Live core gameplay | PASS bounded | Ván bot C++ thật đã qua reveal, Vô Giải, Sát/target/OK, Cường Tập và GameOver. |
| Live targeted gameplay | PARTIAL | Normal rescue và một số CardChosen/Poxi/CardsAndChoice đã có evidence; cancellation/expiry/reconnect và caller còn lại chưa exhaustive. |
| Live rule edge cases | OPEN | Native-local đã PASS normal rescue, Battle Royal Peach→Analeptic và founding kingdom choice trên QA revision `5dcd…`; hosted/Oracle, round events, reward/punishment và winner transition chưa đóng. |
| Hidden trigger/prelight + active reveal | **PASS NATIVE-LOCAL bounded** | Ma trận lõi 12/12 ca C++/Lua thật; staged add-on `hidden-fankui`, `hidden-dual`, `hidden-luoshen`, `hidden-jizhi`, `hidden-mingshi`, hai nhánh Qianxun, Kongcheng, Weimu, Xiaoji `2/2`, Guanxing `2/2`, Thiên Hương `2/2`, Đoạn Trường `2/2` và Di Kế re-hide `2/2` đã PASS với reveal đúng slot/effect native tương ứng. Chưa đại diện hosted/official release hoặc exhaustive effect matrix. |
| Hidden-skill source projection/lifecycle/slot route | **PASS SOURCE/LOCAL** | Build audit chạy 301 tướng active/602 vị trí, 1.039 reference, 520 skill ID; native `AddSkill`/`LoseSkill` 520/520, replay event qua React 521/521, privacy Add/Lose 1.042/1.042, helper `reveal_skill&` 105/105, `canUse` theo slot 205/205, route `revealBySkillName` 155.168/155.168 trên cặp hợp lệ, prelight sync 403/403, reconnect projection 520/520, actual `Client:addSkill` state 520/520 và `Client:loseSkill` 520/520 (đã bắt/sửa duplicate regular và stale lifecycle), gồm fake trigger, regular Active/ViewAs, dual projection và 15 delay-fallback loss paths. Chưa thay thế live effect matrix. |

Nguồn và ma trận đầy đủ: [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md). Evidence CP89 giữ lại để đối chiếu lịch sử; identity hiện hành là CP96 UI hotfix trên runtime CP92.

## Mốc vừa triển khai

- Đã chốt source-law và bridge hardening: `serverplayer.lua` prelight idempotent, fake-skill reattach phát lại prelight, `room.lua` kiểm tra ownership/stale cleanup; `hostLua.ts` loại duplicate regular khi khôi phục fake snapshot. Installer/verify native đã áp dụng và kiểm tra đủ các patch này.
- Đã hoàn tất gói hotfix UI/UX và bản địa hoá tiếng Việt cho web client (`game/web`) giải quyết 6 vấn đề người dùng phản hồi:
  1. *Nhật ký trận đấu:* giới hạn trần `.board-log-panel.sg-board-log-panel` (`max-height: min(85dvh, 850px); min-height: 0`) và `.board-logs` (`max-height: calc(...) - 38px; overflow-y: auto`), thêm custom scrollbar (WebKit & Firefox `scrollbar-width: thin`), ngăn tràn vô cực và hiển thị thanh cuộn rõ ràng.
  2. *Diễn biến mới nhất:* loại bỏ `white-space: nowrap` và `text-overflow: ellipsis`, cho phép xuống dòng tự nhiên (`overflow-wrap: break-word`) và container cuộn (`max-height: 85px`), không còn bị cắt `...`.
  3. *Màn hình dọc iOS:* media query portrait dời `.sg-board-table .board-moments` xuống `top: 48%` và `margin: 20px auto 0` tránh che khuất bài trung tâm và tướng đối thủ.
  4. *Số phiên bản:* thay `2.4.1` thành `BETA` tại `BootScreen.tsx`, `LoginScreen.tsx` và `LobbyScreen.tsx`.
  5. *Bản địa hoá trang bị/thông báo:* dịch đầy đủ từ điển vũ khí, giáp, thú cưỡi, bảo vật và prompt `#AskFor...`; strip tiền tố package (`m__`, `os__`, `role__`); thêm `resolveEquipName` và baseline descriptions triệt tiêu hoàn toàn hiện tượng lộ wire ID raw.
  6. *Font kỹ năng tiếng Việt:* tích hợp Google Font `Be Vietnam Pro` (weights 400-800) thay thế `Georgia` cho skill buttons và action buttons, hỗ trợ đầy đủ các ký tự tiếng Việt có dấu.
  7. *Kiểm thử:* `npm run build` PASS (1.739 assets, bundle 1.3MB), 111+ unit tests PASS 100%.
- Đã giải quyết triệt để 4 vấn đề UI/UX tiếp nối người dùng phản hồi:
  1. *Lộ tiếng Trung trong log:* Dịch log ngăn chặn sát thương (`由于...伤害被防止了`) và log xáo bài (`已重新洗牌，牌堆现有 %arg 张牌`) trong `localizedGameLog` và `vietnamese.ts` (`#PreventDamage`, `#PreventDamageWithNoFrom`, `$ShuffleDrawPile`).
  2. *Lộ key skill cẩm nang:* Thêm định nghĩa dịch cho các kỹ năng thẻ bài (`amazing_grace_skill`, `god_salvation_skill`, `dismantlement_skill`, `snatch_skill`, `iron_chain_skill`, `recast`, v.v.) và bổ sung cơ chế fallback tự động bóc tách hậu tố `_skill` trong `displayText.ts`.
  3. *Mất chất/số bài ngoài lượt:* Sửa `IdleHandCard` đồng bộ cấu trúc 4 layer chuẩn với `HandCardItem` (`sg-card-top-left` cho rank và suit, `sg-card-type-badge`, `CardArt`, `sg-card-banner`); mở rộng `publicCard` trong `boardState.ts` chấp nhận suit 0..5 (`NoSuit`).
  4. *Kích thước ghế chênh lệch & chữ quá nhỏ:* Điều chỉnh ellipse (`rY = 28`) và scale bàn 8 ghế (từ 0.65 lên 0.72 desktop), thu gọn nhẹ ghế local (124x166px), tăng cỡ chữ và icon nội bộ panel (tên tướng thư pháp 9.5px, tên người chơi 8.5px, số ghế 14px, máu 8.5px, trang bị 7.5px) giúp ghế đối thủ đọc rõ ràng, cân xứng, không bị co rúm hay đè lên nhau.
  5. *Kiểm thử:* `test:store` (40/40), `test:card-display` (12/12), `test:e2e` (20/20), `test:e2e:lua` (63/63), `npm run build` PASS 100%, artifact đã sync sạch sang `dist/`.
- Đã dựng runtime native local bằng đúng 14 package pin + `tqs_qa` server-only; cài Lua 5.4, `luasocket` và `luafilesystem` trong thư mục tạm, đọc manifest từ package thực tế. `verify-install.sh` PASS.
- Đã đóng lỗi lặp lại Lua 5.5/5.4 ở root launch path: `scripts/lua-runtime.sh` chỉ nhận binary `lua5.4`/`lua-5.4`, xác nhận `_VERSION == Lua 5.4`, prepend `rocks54` vào `LUA_PATH`/`LUA_CPATH` và preflight `socket` + `lfs` trước khi mở cổng. `run-server.sh` và `verify-install.sh` dùng chung helper; chạy thẳng binary không còn là launch path được hỗ trợ.
- Native C++/Lua local đã chạy lại trên QA revision `5dcd…` và browser artifact `d432…`: Di Kế chủ `negative/positive/skip`, Di Kế phó `positive`, Gian Hùng chủ/phó, reveal helper chủ/phó, Chế Hành chủ/phó, Long Đảm ViewAs chủ/phó, normal rescue, Battle Royal rescue/view-as và founding; tất cả PASS với hai browser client, GameOver/result/lobby/disconnect sạch. Audit/evidence chi tiết chỉ giữ trong [`QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md).
- Native C++/Lua local vừa chạy Qianxun Indulgence main/deputy trên identity mới: runtime MD5 `f8f93a0d04b0a98b2297a693ea41767b`, QA revision `ae3d56bd8b80911a6459f984ea8a62a5d0527a86`, package/catalog hash ở audit canonical. Cả hai PASS với hai browser client, GameOver/result/lobby/disconnect sạch; `BeforeCardsMove` mở đúng slot, không đưa Lạc Bất Tư Thục vào Judge và mirror lá sang DiscardPile. Đây là **NATIVE-LOCAL STAGED**, không phải Render/Oracle/production.
- Native C++/Lua local vừa chạy Kongcheng main/deputy trên identity mới: runtime MD5 `677b015d118bf7972a2a0c441b636d5f`, QA revision `6fd4d54cffb2df933ba91aff71ea47d7166970e8`, manifest/package/catalog hash ở audit canonical. Cả hai PASS với hai browser client, GameOver/result/lobby/disconnect sạch; `TargetConfirming` nhận Quyết Đấu thật khi actor hết bài, mở đúng chủ/phó và hủy mục tiêu. Evidence `1792044149912` và `1792044169217`; đây là **NATIVE-LOCAL STAGED**, không phải Render/Oracle/production.
- Native C++/Lua local vừa chạy Weimu main/deputy trên identity mới: runtime flist MD5 `a3744922e9acb23692b5559a80528afe`, QA revision `8af6e4ee0d9c14dbfcadcec12be70b864ce7c67b`, manifest/package/catalog hash ở audit canonical. Cả hai PASS với hai browser client, GameOver/result/lobby/disconnect sạch; `TargetConfirming` nhận Quyết Đấu đen thật, mở đúng chủ/phó, hủy mục tiêu và giữ damage `0`. Evidence `1792045540754` và `1792045551855`; đây là **NATIVE-LOCAL STAGED**, không phải Render/Oracle/production.
- Native C++/Lua local vừa chạy tiếp Weimu `BeforeCardsMove` main/deputy trên identity Weimu riêng: runtime flist MD5 `b20ed84249d3d27422a311066c327ed6`, QA revision `7333203d3ea4ac756fb22233a1485f9a734c185b`, manifest SHA-256 `8a75a038688e2e5248fb2d8f03119c13903698d150c513bd90e73f81ba56e640`, package SHA-256 `d6c144aafeff65407d9c4ff4a413052949becc4c1c2c4776d760eb514fa4931c`, catalog SHA-256 `c0395f5bd54ac54417611c55f88714da851c2d9a9d21a74166f9ff9adda49a79`. Cả hai PASS với hai browser client, GameOver/result/lobby/disconnect sạch; Lạc Bất Tư Thục đen không vào Judge, được mirror sang DiscardPile, mở đúng chủ/phó và chuyển fake→active. Evidence `1792046419435` và `1792046430676`; đây là **NATIVE-LOCAL STAGED**, không phải Render/Oracle/production.
- Native C++/Lua local vừa chạy Xiaoji `AfterCardsMove` main/deputy: runtime flist MD5 `0cc149d0fb6b8bd68ae640e9bd7c281e`, QA revision `ec6d35ae043a1e5ceda54e333e66661193feb5ec`, manifest SHA-256 `073b25f3f3e1331a1012c87f764c4f35fe19c7a0dbf1064352e91043c433c65d`, package SHA-256 `f95c1b9d0f69db951b8e529064cc9fea08fb8b9ab5dd4589ffd484717fa4fd66`, catalog SHA-256 `d11617ab98a54607aed71cf03546da2c0b1a01458caa9d4d6b4fc319b4c7e9f9`. Cả hai PASS với hai browser client, equipment rời `PlayerEquip`, native `SkillEffect` mở đúng chủ/phó, draw lần lượt 3/1 và GameOver/result/lobby/disconnect sạch. Evidence `1792047241418` và `1792047253985`; runtime không khớp `RELEASE.json`, vì vậy đây là **NATIVE-LOCAL local/unpinned**, không phải Render/Oracle/production.
- Native C++/Lua local vừa chạy Guanxing `EventPhaseStart` main/deputy: runtime/flist MD5 `ee6cc20fcb8ac9785939ec222efd8ea0`; evidence và identity chi tiết giữ duy nhất trong audit canonical. Cả hai PASS với hai browser client, gate prelight, `AskForSkillInvoke`, reveal đúng chủ/phó, `AskForArrangeCards` hai lá native, GameOver/result/lobby/disconnect sạch; đây là **NATIVE-LOCAL local/unpinned**, không phải Render/Oracle/production.
- Native C++/Lua local vừa chạy Thiên Hương main/deputy trên runtime cô lập `flist MD5 79ef20f9a8fff39dc92310500269add0`: [`1792050881499`](../scratch/evidence/cp93-hidden-tianxiang-multiplayer-live-1792050881499.json) và [`1792050897211`](../scratch/evidence/cp93-hidden-tianxiang-deputy-multiplayer-live-1792050897211.json) đều PASS với hai browser client, `AskForUseActiveSkill` chọn bài tim + mục tiêu, `AskForChoices` nhánh mất HP/trả bài, reveal đúng chủ/phó, damage bị chặn và cleanup sạch. Hosted probe [`1792050441784`](../scratch/evidence/reconnect-failure-1792050441784.json) fail trước QA gate vì target chưa chứng minh `tqs_qa`; không dùng làm evidence luật sai.
- Native C++/Lua local vừa chạy Đoạn Trường main/deputy trên runtime cô lập `flist MD5 cc9ffae8858f3fff68f4b4f4c3d1bc9b`, QA package revision `51bb9d2d…`: [`1792052232281`](../scratch/evidence/cp08-hidden-duanchang-multiplayer-live-1792052232281.json) và [`1792052245231`](../scratch/evidence/cp08-hidden-duanchang-deputy-multiplayer-live-1792052245231.json) đều PASS với hai browser client + hai native bot, fake skill khi actor còn úp, prelight gate, `fk.Death`, `AskForChoices` chọn Cao Cao ở chủ tướng killer, gỡ `Gian Hùng` nhưng giữ `Phản Quỹ`, reveal đúng chủ/phó và cleanup sạch. Đây là **NATIVE-LOCAL staged**, không phải Render/Oracle/production.
- Native C++/Lua local vừa chạy regression Di Kế re-hide main/deputy trên runtime cô lập `flist MD5 3966a400db61802cd94b8d87b4cc54d5`, QA revision `18969850eab0334778a284869de68de07f04a25f`: [`1792054011035`](../scratch/evidence/cp95-hidden-rehide-yiji-multiplayer-live-1792054011035.json) và [`1792054024731`](../scratch/evidence/cp95-hidden-rehide-yiji-deputy-multiplayer-live-1792054024731.json) đều PASS với hai browser client. Cả hai kiểm damage thật → `AskForSkillInvoke` → Di Kế chuyển 2 lá → reveal đúng slot → `hideGeneral()` → fake/prelight retention, không regular duplicate, GameOver/result/lobby/disconnect sạch. Đây là **NATIVE-LOCAL staged**, không phải Render/Oracle/production.
- Native C++/Lua local vừa chạy `ex__yingzi` main/deputy trên runtime cô lập `flist MD5 e3fa7be9a38d083d09c562dcf1d546d2`, QA revision `6ed7e3110fb57335d8805fbc70a7a307b099da88`: [`1792055572502`](../scratch/evidence/cp98-hidden-yingzi-multiplayer-live-1792055572502.json) và [`1792055583385`](../scratch/evidence/cp98-hidden-yingzi-deputy-multiplayer-live-1792055583385.json) đều PASS với hai browser client. Cả hai kiểm gate prelight → draw phase native → `DrawNCards` `2→3` → rút thật 3 lá → `AfterDrawNCards`, `SkillEffect` mở đúng chủ/phó, fake→active và GameOver/result/lobby/disconnect sạch. Đây là **NATIVE-LOCAL staged**, không phải Render/Oracle/production; hash package/catalog canonical nằm ở `QUOC_CHIEN_RULE_AUDIT.md`.
- Evidence Jizhi/Mingshi và các staged add-on trước vẫn giữ trong audit canonical; STATE chỉ giữ kết luận ngắn để tránh lẫn identity.
- Evidence staged cũ (`hidden-dual`, `hidden-fankui`, `hidden-luoshen`) được giữ ở audit canonical; STATE không lặp hash/log để tránh review nhầm identity.
- Re-validation native/local trước CP94 (15/10/2026 15:18) là mốc lịch sử: catalog/source scenarios 45/45, `test:qa-server-contract` 28/28 subtests, `test:e2e:lua` 63/63, `audit:hidden-skills` (520/520 lifecycle, 155.168 route, 0 hard failure), `audit:skill-activation` (0 hard failure), `typecheck`; ca Quách Gia đã xác nhận negative/positive/skip, Thiên Hương và Đoạn Trường native main/deputy. Mốc hiện hành sau regression re-hide và 英姿 là 49/49 và 30/30 ở audit canonical; tất cả vẫn bounded/local, không thay thế LIVE.
- Kiểm tra cài đặt lại từ máy phát triển: profile/key `tqs-native-qa` tồn tại đúng quyền local nhưng `ssh -o BatchMode=yes tqs-native-qa true` vẫn trả `Permission denied (publickey)` (exit 255). Chưa có quyền guest nên chưa cài/verify package QA hiện hành trên Oracle và không ghi nhận deploy.
- Đã thử reconnect native khi readiness `AskForSkillInvoke` của Di Kế còn pending: FreeKill hủy request khi actor disconnect rồi cho login lại, nên không coi đây là React regression; prompt-specific reconnect vẫn **OPEN** và phải kiểm riêng theo semantics request.
- Oracle VM chỉ mới được xác nhận ở mức process/port: service `freekill-native` active và 9527 reachable, nhưng chưa đọc được manifest/hash trong guest. SSH vẫn bị từ chối, Run Command chạy dưới `ocarun` không có root, OCI không cho sửa `ssh_authorized_keys`, recovery chưa vào được root shell. **Không có bằng chứng phiên này đã deploy package hiện hành lên VM.**
- Hai rerun Oracle/ngoài trước (`reconnect-failure-1792002124241.json`, `1792002605900.json`) fail trước QA gate do thiếu/chưa xác định `tqs_qa`; runner đã fail-fast đúng boundary package/config. Không dùng chúng để kết luận lỗi luật React.
- Hotfix CP96 đã package, deploy và probe PASS trên Render; latest redeploy không thay đổi UI/runtime identity; `PLAYABLE_MOBILE=false`, full parity/P0 live interaction/rescue/wild/founding và official release vẫn mở.
- Invariant quan trọng sau reveal: source gốc gỡ fake skill và chuyển sang regular trước `SkillEffect`, không tự xóa `prelighted_skills`; tài liệu canonical đã ghi để tránh review nhầm hide/transform/swap.

## Việc còn mở theo thứ tự

1. **P0 gameplay:** xác minh guest access, cài/verify đúng QA/package identity trên Oracle hoặc hosted target rồi rerun normal rescue, Battle Royal rescue/view-as và founding; native-local đã PASS nhưng không thay thế LIVE.
2. **P0 native interaction:** hoàn tất live matrix cho CardChosen, Poxi, CardsAndChoice, ArrangeCards, AG, MoveCardInBoard, SkillInvoke và CustomDialog; kiểm tra cancel/expiry/cleanup/reconnect theo semantics từng request.
3. **P1 presentation/release:** mở smoketest CP96 cho người dùng; sau đó xử lý residual translation, official release, cold-start/quota/rollback/SLA và `PLAYABLE_MOBILE`.

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
- Ghi lúc: 2026-10-15T09:21:29.920Z (UTC).
- Nhánh: `codex/cp89-render-current` · HEAD: `74a7b30efa14`.
- File thay đổi hiển thị: 8 (đã ẩn tên file có thể nhạy cảm và không tính chính tài liệu này).

```text
 M docs/CODEX_PLAN.md
 M docs/web-client/QUOC_CHIEN_RULE_AUDIT.md
 M game/web/scripts/card-display.test.ts
 M game/web/scripts/store.test.ts
?? docs/translations/ZH_CN_ORIGINAL_CATALOG.json
?? docs/translations/ZH_CN_ORIGINAL_CATALOG.md
?? docs/translations/ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv
?? game/web/scripts/export-all-zh.ts
```

Ba commit gần nhất:

```text
74a7b30e docs: align final QA handoff timestamps
926de6cb docs: checkpoint hidden yingzi verification
187d6147 qa: verify hidden yingzi across slots
```

> Ảnh chụp này chỉ phản ánh metadata Git lúc chạy lệnh. Để biết trạng thái **ngay bây giờ**, chạy `git status --short`; không suy diễn PASS từ danh sách file.
<!-- CODEX_SNAPSHOT_END -->
