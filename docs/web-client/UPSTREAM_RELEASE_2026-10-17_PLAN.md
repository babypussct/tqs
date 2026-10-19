# Kế hoạch đánh giá và nâng cấp upstream Quốc Chiến (mốc 17/10/2026)

Trạng thái: **ĐỀ XUẤT / CHƯA TRIỂN KHAI** · Lập ngày 19/10/2026.

## 1. Quyết định và phạm vi

Đây là đợt nâng cấp **major về rủi ro game-rule/tích hợp** đối với `new_heg_mode`, dù upstream không nhất thiết gắn nhãn phiên bản major. Không cập nhật trực tiếp candidate/live, không đổi `versions.env` trên `main`, không tự động theo `master`, không restart dịch vụ, và không chạm TQSShop (`src/`, `api/`), trừ khi một thay đổi hợp đồng được phân tích và mở ticket riêng.

Bảng độ lệch dưới đây là **ảnh chụp báo cáo ngày 17/10/2026, chưa tái xác minh HEAD ngày 19/10/2026**. Các SHA đích rút gọn chỉ để nhận diện; trước khi tạo bản build phải lấy và đóng băng SHA 40 ký tự, kiểm tra ancestry, diff và tính sẵn có của object.

| Nhóm | Pin hiện tại → đích trong báo cáo | Commit lệch | Rủi ro chính | Ưu tiên kiểm tra |
| --- | --- | ---: | --- | --- |
| `hegemony` | `d616978` → `849f321` | 5 | Gói/tướng/skill Quốc Chiến 27, quân chủ, Cửu Biến, YiGui, formation | P0 luật |
| `freekill-core` | `ade837d` → `6f86d5d` | 47 | Shape patch hardening, room/serverplayer, reconnect, private state | P0 tích hợp |
| `tenyear`, `OL` | `91a769c` → `dd84862`; `ceee01b` → `853c8f8` | 37 + 34 | Skill owner, lifecycle, tướng mới, private mark | P0/P1 luật |
| `mobile`, `SP`, `utility` | `dcd523c` → `6aac75a`; `ab42a3f` → `8101643`; `f86d3d0` → `c190c6f` | 17 + 4 + 8 | Visibility/private mark, xử lý lá bài và tương tác | P0 riêng tư |
| `yj`, `overseas`, `shzl` | `10edd0f` → `4954989`; `6780626` → `47f854e`; `a6743be` → `20e0628` | 2 + 4 + 1 | Sửa luật skill cục bộ | P1 |
| `gamemode` | `cf16826` → `ba1053e` | 4 | Chủ yếu 2v2; phụ thuộc virtual card của runtime | P2/tương thích |
| `freekill-asio` | `b8a2ad4` → `f766e74` | 1 | Source metadata/CMake; static release đang là `0.1.17` | P2, xét riêng |
| `standard_ex`, `mougong`, `jsrg` | Không lệch tại mốc báo cáo | 0 | Giữ pin nếu diff dependency không buộc đổi | Giữ nguyên |

Tổng `164` là tổng khoảng cách commit của báo cáo, **không phải** số thay đổi luật độc lập. Mọi kết luận về các commit sau 17/10 cần thu thập bằng chứng mới.

## 2. Những ràng buộc đã xác nhận ở checkout ngày 19/10

- Nhánh `main`, HEAD `c2375a8a`; worktree có rất nhiều thay đổi chưa commit (phần lớn `dist/`) và `docs/CODEX_PLAN.md` / `docs/CODEX_STATE.md` đang dirty. Phải giữ nguyên toàn bộ thay đổi đó. Tạo worktree/checkout thử nghiệm độc lập; lưu ý worktree tại HEAD sẽ **không tự mang** các chỉnh sửa dirty đang ảnh hưởng sản phẩm. Xác định và áp dụng có chủ đích phần thay đổi cần cho baseline trước khi đo.
- Pin native ở `deploy/freekill-native/versions.env`, trong khi pin browser/Wasmoon/QA/fixture nằm hardcode tại `game/web/scripts/upstream-packages.ts` (`UPSTREAM_PACKAGES`). Cả hai phải trỏ **cùng 14 package với SHA đầy đủ** trong mọi bản thử nghiệm.
- `DECLARATION_REPAIRS` trong `upstream-packages.ts` buộc `ownerCommit` của `tenyear` là `91a769c...` và sửa `langmie` → `ty__langmie` bằng chuỗi khớp chính xác. `deploy/freekill-native/scripts/install-packages.sh` có sửa khai báo tương ứng; khi nâng gói cần đánh giá lại hai phía, tránh sửa hai lần hoặc mất fix.
- Native installer còn có các patch fail-closed cho prelight duplicate/retained fake skill, `Room:handlePrelight` ownership/stale cleanup, `FK_TQS_LOCKED_PACKS` và `packages.db`. Thành công của clone/build **chưa đủ** để chứng minh patch hoặc boundary còn đúng.
- Native QA `tqs_qa`, candidate/web, manifest và MD5 hiện có bằng chứng **cho identity cũ** trong `docs/CODEX_STATE.md`, `docs/CODEX_PLAN.md` và `docs/web-client/QUOC_CHIEN_RULE_AUDIT.md`; không kế thừa PASS của identity cũ cho snapshot upstream mới. G7 official còn OPEN; `PLAYABLE_MOBILE=FALSE`.

## 3. Kế hoạch thực hiện theo gate, không theo ngày ước lượng

### Bước 0 — Đóng băng baseline và cô lập (U0)

**Thực hiện:** ghi branch/HEAD, `git status`, pin 14/14, SHA của native binary, browser bundle, runtime MD5, `RELEASE.json`/manifest, phiên bản Lua và cấu hình candidate đang dùng; lập bảng các blocker hiện tại (native interaction/reconnect/iOS device/G7). Tạo worktree riêng từ HEAD và bổ sung có chọn lọc các thay đổi dirty cần thiết để tái tạo baseline; không sửa checkout live hay nhánh `main`.

**Bàn giao:** `baseline.json`/bảng nhận dạng release, danh sách thay đổi được đưa vào test worktree, cách phục hồi và so sánh baseline PASS/FAIL.

**Đạt khi:** tái tạo được baseline bằng cùng pin; biết rõ khác biệt giữa worktree thử và sản phẩm đang chạy. Nếu baseline chưa tái tạo được, dừng nâng cấp để sửa quy trình đo.

### Bước 1 — Xác thực diff và ma trận phụ thuộc (U1)

**Thực hiện:** lấy upstream vào clone/cache **chỉ đọc**, xác nhận full SHA, commit tồn tại và `merge-base`; lấy danh sách commit/file theo `old..target` ở tất cả repo, phân loại `server/core`, `Lua rule`, `client/QML`, `general/skill`, `private state`, `asset/audio` và `test`. So từng package với whitelist của `new_heg_mode`; phân biệt package có ảnh hưởng thực tế đến pool, virtual card và helper. Ghi rõ các commit cần lấy cùng nhau để không tạo tổ hợp skill owner thiếu đồng bộ.

**Bàn giao:** `diff-inventory.csv` (repo, SHA nguồn/đích, file, tác động, mức rủi ro), bảng package dependency/whitelist, danh sách kịch bản cần kiểm.

**Đạt khi:** không còn pin đích rút gọn/moving branch; mỗi thay đổi P0 có hành vi trước/sau và bài kiểm thử dự kiến. Nếu SHA đã tiến xa hơn snapshot 17/10, lập delta mới và duyệt phạm vi trước khi cố định target.

### Bước 2 — Spike tương thích core và bản vá native (U2)

**Thực hiện:** trong sandbox disposable, thử nâng **riêng `freekill-core` để phát hiện breakage** của installer/Lua/server; đây là bước chẩn đoán, tuyệt đối không dùng một tập pin lệch này để release. Kiểm tra từng patch fail-closed và liệu upstream đã sửa chính thức các lỗi prelight, fake-skill ownership, locked packs hay chưa. Giữ các assertion hành vi kể cả khi bỏ patch vì upstream đã tự sửa. Chạy Lua 5.4/module preflight và contract tests liên quan.

**Bàn giao:** bảng `patch hiện tại → upstream shape → quyết định giữ/đổi/bỏ → test bắt buộc`, diff patch tối thiểu, log lệnh PASS/FAIL.

**Đạt khi:** cài/bật core mới trong môi trường riêng không fail do patch shape; không mất hardening; có test cho hidden/main/deputy, prelight idempotence, stale cleanup và owner check. Nếu installer fail, **dừng** để sửa có chứng cứ; không tắt fail-closed cho qua.

### Bước 3 — Tạo snapshot 14 package nhất quán (U3)

**Thực hiện:** đóng băng `hegemony` cùng nhóm phụ thuộc `tenyear`, `OL`, `mobile`, `SP`, `utility`, `yj`, `overseas`, `shzl`; đánh giá `gamemode` theo virtual card và giữ 3 repo không đổi nếu tương thích. `freekill-asio` xét riêng vì bản static đã `0.1.17`. Chỉnh đồng bộ `versions.env`, `UPSTREAM_PACKAGES`, `DECLARATION_REPAIRS` và installer **chỉ trong nhánh thử**. Kiểm toàn bộ 14 package không thiếu, không lệch owner/skill/commit; so hash sau repair ở native với byte tương ứng của browser.

**Bàn giao:** manifest pin SHA đầy đủ 14/14, diff source/repair, các quyết định hoãn/giữ pin và lý do.

**Đạt khi:** native/browser/QA cùng snapshot và cùng semantics; không phát sinh skill trùng/thiếu, no floating refs. Nếu buộc trì hoãn một repo, nêu ma trận tương thích cụ thể của snapshot rút gọn đó.

### Bước 4 — Build native và browser từ snapshot cùng nguồn (U4)

**Thực hiện:** chạy native installer và `scripts/verify-install.sh` trên cây runtime trống riêng, build native và smoke khởi động Lua 5.4; rebuild Wasmoon/browser, `flist`, audio/image/CSS, service worker, `RELEASE.json`, verify manifest/file hashes. So số gói, SHA đã pin, `packages.db`, runtime MD5 và ID/đường dẫn asset giữa native–browser–gateway. Không ghi đè `/opt/freekill-hegemony` đang phục vụ live.

**Bàn giao:** native binary, web candidate bundle, manifest, digest SHA-256/MD5 và bảng đối chiếu file parity, log build/verifier.

**Đạt khi:** toàn bộ hash/manifest trùng snapshot đã duyệt; các package được công bố tồn tại thực, asset không 404, cache/SW không tái sử dụng bundle cũ.

### Bước 5 — Audit luật Quốc Chiến, pool và privacy (U5)

**Thực hiện:** chạy inventory trước/sau cho tướng, cặp chủ/phó, tên skill/owner, unique IDs, danh sách gói được phép/bị khoá, pool phòng 5/7/10 người, bài/tướng và bản dịch. Kiểm trực tiếp các ca `hegemony`: Quốc Chiến 27, Tào Phi/Lưu Thiện/Tôn Sách/Đổng Trác, Cửu Biến/Tả Từ, YiGui, formation/strategic advantage, `lord_ex`, `mobile_heg`, `overseas_heg`. Kiểm những skill mới/sửa trong `tenyear`/`OL`/`mobile`/`SP` và các gói nhỏ; bổ sung fixture từ chính diff.

**Kiểm riêng tư bắt buộc:** thông tin của bản thân/đối thủ/quan sát viên, main/deputy đang úp, private marks và牌堆, trình tự Add/Lose/Prelight/reveal, death/GameOver, reconnect/replay/double-notify; không rò tay bài, mark hay tướng ẩn. Kiểm kết quả trong native và projection browser.

**Bàn giao:** ma trận `scenario × server Lua × browser UI × reconnect/spectator`, bằng chứng fixture/log/screenshot đã khử thông tin nhạy cảm, danh sách skill chưa phủ.

**Đạt khi:** **100% các delta luật/privacy P0 được kiểm bằng ca thích hợp**, regression baseline không phát sinh; skill mới nhưng chưa có bài thử phù hợp là **blocker**, không đánh dấu `PASS` chỉ vì typecheck/build.

### Bước 6 — Regression gate tự động và native E2E (U6)

Từ `game/web/` trên snapshot mới, chạy theo nhóm để xác định nguồn lỗi:

```bash
npm run build
npm run audit:hidden-effects
npm run test:qa-server-contract
npm run test:room-pools
npm run test:gameplay
npm run test:choices
npm run test:store
npm run test:card-display
npm run test:native-dialogs
npm run test:connection
npm run test:lua-lifecycle
npm run test:protocol
npm run test:e2e:lua
npm run test:release
```

Tùy phạm vi diff bổ sung `test:card-effects`, `test:e2e:multiplayer` và các ca Lua/native C++ tương tác hai người. `test:e2e:live` chỉ chạy trên endpoint QA/candidate được xác định rõ, không vô tình trỏ production. Log rõ số ca PASS/FAIL/SKIP, environment, revision và baseline so sánh.

**Đạt khi:** các bài bắt buộc PASS với snapshot mới; regression cũ còn thất bại phải phân loại/giải quyết có chứng cứ; P0 chưa phủ không thể bỏ qua vì test tổng quát xanh.

### Bước 7 — Candidate cô lập và kiểm thử người dùng (U7)

**Thực hiện:** sau U0–U6 mới triển khai lên service + DB + port + bundle candidate riêng, giữ native/web đồng bộ release identity, không chia sẻ writable state với live. Smoke xác thực/session, create/join room, bot và hai người thật, reveal/ẩn tướng, full GameOver, disconnect/reconnect, observer, thay đổi mạng, màn hình nhỏ/cảm ứng/PWA, cache reload. Đối chiếu runtime MD5/manifest/hash public thực nhận với dự kiến.

**Bàn giao:** địa chỉ candidate, release identity chính xác, biên bản ca smoke, known issues và quyết định `ACCEPT` hoặc `REJECT` cho candidate.

**Đạt khi:** không rò private state, không sai kết toán, không crash/treo room, không mất kết nối không khôi phục; ca device bị thiếu được ghi rõ là **chưa nghiệm thu**.

### Bước 8 — Sẵn sàng phát hành và rollback rehearsal (U8)

**Thực hiện:** theo dõi ổn định, lỗi, bộ nhớ/CPU, cold-start, giới hạn tài nguyên và quota; xác minh full backup binary/pin/assets/config/DB, chạy restore thử trong môi trường độc lập và kiểm sự tương thích khi quay về bundle/server cũ. Chỉ khi candidate nghiệm thu, G7 official chung của dự án đáp ứng, rollback có chứng cứ và người vận hành **phê duyệt đợt production riêng** mới xem xét publish/cutover có kiểm soát.

**Bàn giao:** release note, bản đồ package SHA, checklist cutover, kết quả restore, thời điểm/điều kiện rollback, người thực hiện và quan sát sau release.

**Đạt khi:** rollback native + web theo **cùng** identity đã thử; dịch vụ cũ còn sẵn để chuyển lại. Không tự restart/deploy vì upstream đổi commit.

## 4. Các điểm dừng bắt buộc

1. SHA đích không xác thực, pin native/browser khác nhau, package/asset thiếu hoặc manifest/MD5 lệch.
2. Installer patch không khớp shape, fail-closed bị vô hiệu, behavior prelight/private mark/ownership thay đổi chưa có contract test.
3. Pool/tướng/skill/cơ chế Quốc Chiến đổi mà chưa có kịch bản test trước/sau, hoặc sai kết toán/reconnect/spectator/GameOver.
4. Bản candidate cần dùng lại prod database/port/session, hoặc phát hiện hồi quy bảo mật, lộ thông tin lá/tướng ẩn.
5. Chưa có bằng chứng rollback trên cả native và browser, hay chưa đạt gate G7 official của dự án.

Ở mỗi điểm dừng: giữ candidate cũ, ghi log/chứng cứ, sửa trong nhánh thử và chạy lại gate liên quan; không chỉnh thẳng runtime production.

## 5. Tài liệu và cập nhật trạng thái

- Nguồn snapshot: báo cáo đối chiếu commit ngày **17/10/2026** do người dùng cung cấp; độ lệch chưa được tái đo trong lần lập kế hoạch này.
- Các hợp đồng liên quan: `deploy/freekill-native/versions.env`, `deploy/freekill-native/scripts/install-packages.sh`, `deploy/freekill-native/scripts/verify-install.sh`, `game/web/scripts/upstream-packages.ts`, `game/web/vite.config.ts`, `deploy/mobile/verify-release.mjs`, `docs/web-client/QUOC_CHIEN_RULE_AUDIT.md`.
- Theo dõi chính thức: `docs/CODEX_PLAN.md` và `docs/CODEX_STATE.md`. Hai file đang có thay đổi chưa commit, nên **chưa chỉnh** trong lần chỉ lập kế hoạch này. Chỉ đánh dấu bước hoàn tất khi có kết quả chạy thật; sau mỗi mốc triển khai đáng kể cập nhật hai tài liệu và chạy `npm run codex:checkpoint` theo AGENTS.md.
- **Tình trạng tại ngày lập kế hoạch:** U0–U8 ở tài liệu này đều `CHƯA CHẠY`; chưa đổi pin, chưa tạo artifact nâng cấp, chưa chạy test trên upstream mới và chưa tác động live/candidate.
