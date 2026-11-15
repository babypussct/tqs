# Kế hoạch chi tiết nâng Hegemony từng bước, giữ production ổn định

> **Thay đổi chiến lược 28/10/2026:** kế hoạch điều phối hiện hành là [UPSTREAM_FIRST_MASTER_PLAN_2026-10-28.md](UPSTREAM_FIRST_MASTER_PLAN_2026-10-28.md) — một candidate upstream chính, không tiếp tục phát triển hai luồng production cũ và upstream song song. Giữ tài liệu này làm runbook kỹ thuật U0–U8 và lịch sử quyết định; những chỉ thị về hướng nâng dần/giữ tương thích legacy được thay bằng master plan mới. Các gate luật/native/privacy/rollback vẫn có hiệu lực.

**Ngày chốt:** 25/10/2026. **Trạng thái:** kế hoạch đã lập, chưa triển khai nâng pin hoặc phát hành.

**Phương án hiện hành theo người dùng:** production hiện tại tiếp tục chạy; chuẩn bị và kiểm thử từng phần tại local/môi trường riêng; không dựng thêm native thường trực trên VM production. Sau khi nghiệm thu toàn bộ snapshot, phát hành một bộ native–Lua–web đồng bộ trong cửa sổ chuyển đổi có kiểm soát. Tài liệu này thay phương án hai tuyến chạy thường trực ở `UPSTREAM_PARALLEL_CUTOVER_2026-10-25.md`; giữ các lưu ý về identity, drain, DB và rollback của tài liệu đó. Mã U0–U8 giữ nguyên.

## 1. Mục tiêu, baseline và giới hạn

- **Mục tiêu:** Quốc Chiến `new_heg_mode` từ đăng nhập → tạo/vào phòng → chủ/phó → ẩn/lộ → bài/kỹ năng → GameOver → reconnect; giữ đúng luật snapshot, bí mật bài/tướng và các bản vá TQS còn cần thiết.
- **Upstream đã xác minh trong phiên trước cùng ngày:** pin hiện tại `d616978ad2a53055f5815f3ae19f2d2b239862e0`; target khảo sát mới nhất `d069cd1f5c6df8d93af0ea101b82a5bed2781f01`; lệch 7 commit, 194 tệp. U1 xác minh lại remote khi đóng băng; không tự chạy theo master hoặc đổi target giữa nghiệm thu.
- **Live đã đo trước khi lập kế hoạch:** VM E2.1.Micro, RAM 954 MiB/khả dụng ~398 MiB, swap dùng ~272 MiB, disk available ~18,48 GiB. Không full native build, benchmark hoặc đặt server candidate thường trực cạnh live.
- **Live identity đã đo:** web build `9778d65e…`, runtime MD5 `845498010a0c9f790254ec86e3dfc999`, current `ai-prompt4-20261022-prod-clean`; SSH đúng alias `tqs-native-qa-replacement`. U0 ghi lại đầy đủ hash và đối chiếu source/binary, không suy mọi patch trong checkout đã có trên live.
- **Scope:** Hegemony và core/utility/skill/card/helper trực tiếp hoặc gián tiếp phục vụ Quốc Chiến. Dependency khác giữ pin nếu không có bằng chứng cần đổi. Không nâng toàn hệ sinh thái, không mở mode khác hoặc việc Shop.
- **Thiết bị:** physical iOS/Android/network giữ `WAIVED_BY_USER`; ghi coverage, không gọi PASS. Browser/mobile viewport, reconnect và privacy vẫn bắt buộc.

Số liệu và PASS cũ là baseline tham khảo, không nghiệm thu target mới. Việc lập tài liệu không tạo branch/worktree/candidate hoặc thay pin, runtime hay production.

## 2. Cách chia công việc và quyền thay đổi

1. Từng giai đoạn bàn giao source diff, evidence, trạng thái PASS/FAIL/WAIVED/NOT_RUN, issue còn lại và lệnh tiếp theo. Cập nhật `CODEX_STATE.md`, ticket trong `CODEX_PLAN.md`, rồi `npm run codex:checkpoint`.
2. Khi bắt đầu thực thi, dùng worktree/checkout riêng và nhánh dự kiến `codex/upstream-hegemony-20261025`. Giữ checkout chính và mọi dirty change; chỉ đưa thay đổi đang dở vào baseline nếu đã xác định cần và ghi provenance. `main` còn chứa Shop, không xóa hoặc đổi vai trò toàn repo để thay riêng game.
3. Chia source thành lô nhỏ để review/test: baseline/tooling → snapshot/repair → core AI/request/hardening → Hegemony skill/helper → media/translation/UI → regression/release packaging. Mỗi lô kiểm phần bị tác động, chốt lại cả bộ trước phát hành. Mốc thử chưa đạt phải ghi rõ experimental.
4. **Mặc định chỉ một đợt phát hành cho snapshot upstream này.** “Làm dần” là tiến dần trong source và kiểm thử; không chép lẻ file Lua vào live, không phát hành một nửa pin native/browser hoặc trộn manifest mới/cũ. Chỉ tách release độc lập nếu chứng minh không phụ thuộc và có artifact/rollback riêng.
5. U0–U7 chuẩn bị và kiểm trên môi trường riêng; U8 chuẩn bị lịch phát hành. Yêu cầu lập kế hoạch này không tự thực hiện push/deploy, cấp tài nguyên trả phí hoặc cutover. Các quyền đã có được áp dụng đúng phạm vi; khi cần quyết định phát hành, phải có artifact/evidence/checklist cụ thể sẵn để review.

## 3. U0 — Đóng băng và tái tạo bản đang chạy

**Đầu việc**

- Ghi branch/commit/dirty inventory, 14 package SHA, declaration repairs, toàn bộ runtime overlay của package thực dùng, config không nhạy cảm, native binary hash/build provenance, Lua/module version, flist, web build/RELEASE và gateway manifest.
- Lập diff runtime so pin, bao gồm file thêm/sửa/xóa; số kiểm kê trước là 24 core + 11 Hegemony khác/thêm và utility 0, chưa phải toàn bộ inventory 14 repo.
- Lưu artifact/binary thực, kể cả đích symlink source-build; không chỉ giữ đường dẫn symlink. Backup config/DB nhạy cảm bằng cơ chế bảo vệ hiện hành, evidence chỉ chứa hash/metadata.
- Tái tạo baseline trong thư mục riêng; chạy prep, room-pools, QA contract và các test liên quan để phân biệt lỗi có sẵn với hồi quy mới. Nhãn rõ source baseline, live baseline và các patch chưa phát hành.
- Chọn môi trường Linux x86_64 thử native ngoài VM live: máy/runner đã có hoặc môi trường tạm phù hợp. Nếu chưa có, tiếp tục phần local độc lập; gate C++ vẫn NOT_RUN, không thay bằng build Wasmoon hoặc tự mua VM.

**Đầu ra:** `baseline.json`, `runtime-overlay-inventory.json`, bảng source/live parity, baseline test log và bản đồ artifact/backup được bảo vệ.

**Đạt khi:** tái tạo được baseline có patch, xác định đủ khác biệt với live và giữ được bản cũ để phục hồi. **Dừng nâng:** không biết nguồn binary, mất patch, thiếu artifact/backup hoặc baseline không tái tạo được.

## 4. U1 — Chốt target và ma trận thay đổi

**Đầu việc**

- Kiểm remote Hegemony, fetch vào cache riêng, đóng băng full SHA, ancestry và diff pin→target. Khi target khác mốc khảo sát, bổ sung delta/scenario trước khi nhận snapshot, không mặc định lấy mọi dependency HEAD.
- Phân loại 194 tệp của mốc hiện tại: 98 Lua, 5 QML, 48 MP3, 16 PNG, 27 JPG. Dùng diff cuối thay vì đếm cả commit audio và revert thành tính năng riêng.
- Lập graph general/skill/card/helper/API và whitelist `new_heg_mode`; trong repo phụ chỉ xét nội dung thực dùng, lifecycle/privacy chung và registry có thể làm boot hỏng.
- Lập diff ba phía `upstream pin → runtime TQS → upstream target`; ưu tiên `hegemony/util.lua`, `pkg/overseas_heg/init.lua` vì cùng bị TQS và incoming target sửa.
- Mỗi delta có owner, hành vi cũ/mới, mức P0/P1, scenario, tầng kiểm (Lua/native/browser) và quyết định cần giữ/nâng/backport.

**Đầu ra:** `diff-inventory.csv`, `dependency-decisions.md`, `scenario-matrix.csv`, danh sách tệp giao nhau và patch cần port.

**Đạt khi:** target không còn floating, mọi delta P0 có bài kiểm dự kiến, phần ngoài scope được ghi lý do. START PASS không đủ để quyết định giữ pin.

## 5. U2 — Kiểm tương thích và quyết định phiên bản

**Đầu việc**

- Bắt đầu với Hegemony mới + 13 package giữ pin; so registry/pool baseline và target, duplicate/missing IDs, API/event/lifecycle/helper, module Lua 5.4 và shape patch.
- Chốt từng dependency bằng bằng chứng. Duplicate Mobile/Mưu Công chỉ mở nếu thực sự cần nâng Mobile; không đưa migration đó vào đường bắt buộc mặc định.
- Phân tích GameOver khi đổi identity từ khảo sát core (`1fd47a16`), rồi test để chọn giữ/nâng/backport phần cần cho Quốc Chiến. Nâng Hegemony không tự mang fix core.
- **Ưu tiên giữ đúng native binary có patch đang vận hành** nếu target tương thích. Native/core/Lua là các đầu vào khác nhau: giữ C++ source SHA không đồng nghĩa giữ mọi Lua core. Chỉ rebuild native khi có lý do tương thích hoặc bản vá C++ được chọn; không thay bằng static release chưa mang patch hiện hành.
- Kiểm account-tempban/TQS ticket/reconnect hiện có ở source nhưng chưa chứng minh đầy đủ trên live; quyết định rõ phần nào nằm trong snapshot nâng, phần nào giữ nguyên baseline. Không biến code-only PASS thành live acceptance hoặc tự đưa mitigation `tempBanTime` về giá trị khác.

**Đầu ra:** manifest snapshot dự kiến, bảng giữ/nâng/backport/bỏ patch có lý do, native reuse/rebuild decision và kiểm tương thích.

**Đạt khi:** bộ phiên bản chọn được, mọi hunk hardening có test; không vô hiệu fail-closed để lấy PASS.

## 6. U3 — Áp dụng source theo lô và giữ các bản vá TQS

| Lô | Nội dung | Kiểm ngay sau lô |
| --- | --- | --- |
| U3-A | Đồng bộ `versions.env`, `UPSTREAM_PACKAGES`, declaration repair, installer/verifier và registry DB cho snapshot đã chọn | Pin native/browser 14/14 hoặc tập repo được giải thích; prep fixture, boot/registry/owner |
| U3-B | Core SmartAI/dispatcher, faction inference, chọn cặp, request adapters và auxiliary skill | SmartAI/prompt4/replay liên quan, contract request, malformed/feasible; không đổi luật skill để qua test |
| U3-C | Fake-skill/prelight/hidden ownership/stale cleanup, room lifecycle và pack lock | Hidden-rule/lifecycle/QA contract; main/deputy/observer/reconnect và private marks |
| U3-D | Hegemony helper/skill AI và fix luật TQS còn cần, gồm Tử Gián; hợp nhất `util.lua`/overseas init | Ca đúng/sai điều kiện skill, owner và direct/related reference; trước/sau effect |

Port theo hunk và ngữ cảnh, ghi upstream đã sửa hunk nào để không áp hai lần. Repair match chuỗi trong đoạn comment không chứng minh general active. Giữ public runtime và QA-only driver/telemetry riêng. `flist`/manifest chỉ sinh lại từ source hợp lệ, không sửa thủ công để né mismatch.

**Đầu ra:** diff từng lô, patch-decision ledger và test log gắn SHA. **Đạt khi:** không mất patch bắt buộc, không thiếu/trùng registry, native/browser/QA cùng semantics. Khi lỗi xuất hiện, sửa và chạy lại phần bị tác động trước lô kế tiếp.

## 7. U4 — Media, Việt hóa và artifact đồng bộ

**Đầu việc**

- Đối chiếu ID/đường dẫn ảnh, tướng, lá bài, audio, QML dialog/mark với khả năng render của web. File QML mới không tự mở scope tính năng QML ngoài Quốc Chiến.
- Cập nhật key mới/sửa của skill/card/prompt/choice/log, semantic review phần tác động; giữ placeholder/rich-text. Queue Việt hóa cũ còn semantic review không được tự đổi thành đã duyệt toàn bộ.
- Giữ các cải tiến UI/chọn chủ-phó/OAuth/PWA/update guard hiện hành, chỉ sửa khi delta làm chúng sai. Kiểm asset không 404 và cache không trộn Lua/artifact khác release.
- Đóng gói native/runtime hoặc xác nhận reuse binary; build web ở `game/web/dist/`, native ngoài máy live. Manifest chứa Git commit, package SHA, patch digest, binary hash, flist MD5, runtime bundle hash, web build ID, file count và Lua/module version.
- Cài/verifier trên root trống riêng: không chạy bootstrap mặc định thay `current`, không rebuild source mà binary cũ còn symlink vào đó. Không build Shop nếu không có thay đổi phạm vi yêu cầu; root `dist/` giữ nguyên.

**Đầu ra:** release candidate có digest và bảng native–web–gateway parity, inventory asset/translation delta. **Đạt khi:** artifact tái tạo được, đúng source, đủ media và không tái dùng cache sai build.

## 8. U5 — Nghiệm thu nội dung, luật và bí mật thông tin

**Ma trận bắt buộc cho snapshot mới**

- Danh mục active/visible **301→233**, overseas **76→5**, mobile **21→23**, transformation **7→8**; Cửu Biến **54→52**, lord cards **5→9** theo API. Phân biệt registry với general pile server sau filter; không tự uncomment upstream để giữ 301.
- Test `capacity × generalNum(5/7/10) × pack policy` trên các cấu hình thực sự được UI/native hỗ trợ. Cấu hình thiếu pool/cặp phải bị từ chối rõ, không crash/hang; không mặc định coi 5/7/10 là số ghế.
- Đủ ca cho các delta Quốc Chiến 27, quân chủ Tào Phi/Lưu Thiện/Tôn Sách/Đổng Trác, Từ Thứ/Bành Dạng, bốn trang bị, Cửu Biến/Tả Từ, formation/YiGui/lord/helper bị tác động. Mỗi ca có precondition, request, expected state/effect và kết quả cuối.
- Tử Gián: mất hand và tay rỗng sau event; trạng thái đã rỗng hoặc chỉ mất equip không kích hoạt sai. Kỳ Sách/Dũng Tiến: lựa chọn/target/effect và request lifecycle không crash.
- Hidden main/deputy, prelight/reveal, add/lose skill, private marks/hand, death/GameOver/reconnect; observer kiểm khi được bật. Log/evidence sanitize, không lưu prompt/card/target/private identity hay raw exception.

**Đầu ra:** ma trận scenario có evidence ID. **Đạt khi:** 100% delta P0 rule/privacy có ca thích hợp PASS, không skill mới cần thiết nhưng chưa phủ. Native effect phải được chứng minh ở native, không chỉ source regex/typecheck.

## 9. U6 — Regression trên đúng candidate

Danh sách dưới đây là **lệnh dự kiến**, không phải bằng chứng đã chạy trong lượt lập kế hoạch. Chạy tuần tự nhóm có build/output hoặc server; các unit độc lập có thể gom hợp lý.

| Nhóm | Lệnh chính |
| --- | --- |
| Pin/registry | `npm --prefix game/web run prepare:upstream -- --check`, `test:upstream-preparation`, `audit:skills`, `audit:skill-activation`, `audit:hidden-skills`, `audit:hidden-effects`, `audit:native-callers` |
| Rule/request | Các script game `test:hidden-rule-contract`, `test:qa-server-contract`, `test:room-pools`, `test:initial-general`, `test:gameplay`, `test:choices`, `test:native-dialogs`, `test:lua-lifecycle`, `test:protocol` |
| AI | `test:smart-ai`, `test:prompt4`, các replay/provenance/chooser/request-safety test liên quan patch thực tế; rerun bounded native matrix bị tác động |
| Projection/UI | `test:store`, `test:card-display`, `test:card-effects`, `test:connection`, `test:recovery`, `test:hegemony-translation`, `test:vietnamese` |
| Build/browser | Root `npm run typecheck:all`; game `build`, `test:bundle`, `test:e2e`, `test:e2e:lua`, `test:e2e:pwa`, `test:system-updates`, `test:auth-routing`, `test:release` |
| Native E2E | Game `test:e2e:multiplayer` cùng QA scenario/reconnect phù hợp trên native endpoint thử được pin đúng, không mặc định lấy endpoint production |
| Phạm vi CI/output | Root `changes:plan`, `test:pipelines` khi đổi CI/mapping; `test:build-safety`, `check:build`, `git diff --check`, protected `git diff --exit-code -- dist`; CI cùng candidate SHA qua PR/dispatch theo quyền thực thi |

Trong bảng, các script không kèm prefix thuộc `game/web/package.json` và chạy bằng `npm --prefix game/web run <script>`. Kiểm test contract/pin/output trước runner; runner native legacy cần auth test-only đúng scope, không đưa bridge/bypass vào production. Nếu thật sự sửa build/output/Vercel thì chạy đầy đủ build→clean→rebuild Shop và đối chiếu hash theo AGENTS, không vì upstream game mà mở Shop vô cớ.

**Đạt khi:** các ca bắt buộc PASS trên đúng snapshot; baseline failure được phân loại có chứng cứ, không skip P0 hoặc đổi pin để xanh. Mọi thay đổi source sau test cuối phải rerun phần bị ảnh hưởng.

## 10. U7 — Kiểm candidate tạm thời, không chiếm RAM live

- Chạy native/runtime/gateway/web candidate trên Linux test hoặc môi trường riêng đã xác định ở U0; có thể dựng theo đợt rồi dừng, không cần server thứ hai thường trực. Build Linux x86_64 ngoài live nếu cần native mới; Mac build lỗi API upstream không được coi native Linux PASS.
- Cô lập server DB/packages DB/root/log/network, config và endpoint auth. Nếu dùng host web riêng, kiểm OAuth authorized origin/redirect và ticket flow; không nới authorization production hoặc đổi key live vì test.
- Kiểm end-to-end: login thực/fixture auth đúng tầng → create/join → chủ/phó → ẩn/lộ → bài/skill/request → GameOver; bot và hai client. Reconnect lúc đang chơi, đang chờ reply, socket drop, refresh; kết quả/phòng/ghế/private state đúng.
- Kiểm mobile portrait/landscape/desktop và SW/update guard: đang chơi không trộn runtime mới, ra sảnh tải bản đúng, reload/offline shell theo thiết kế. Giữ nguyên waiver thiết bị thật.
- So public hoặc endpoint test nhận được với artifact đã khóa; kiểm CPU/RAM/latency/error của **candidate** theo phòng thực tế. Nếu máy test khác live, không dùng capacity của máy mạnh làm chứng cứ cho VM 1 GiB; đánh giá memory fit riêng và chốt ngưỡng dừng trước rollout.
- Xong lượt QA: lưu evidence, dừng process/tunnel test, xác nhận production giữ identity/health; không dọn source/backup cần tái tạo.

**Đầu ra:** biên bản ACCEPT/REJECT có build/scenario/environment/coverage và issue. **Đạt khi:** không crash/hang/rò dữ liệu/sai effect/mất reconnect; không còn P0. Thiếu môi trường native test là gate mở, không dùng live làm nơi thử lần đầu.

## 11. U8 — Phát hành một instance, rollback và giữ bản cũ

**U8-A — Chuẩn bị trước cửa sổ chuyển đổi**

- Candidate đã ACCEPT, CI/test đúng SHA, manifest/installer/verifier đã khóa. Staging file vào thư mục release mới trên VM bằng artifact đã build sẵn; chỉ copy/verify, chưa đổi `current` hoặc restart.
- Đo lại RAM/disk; tính đủ release, backup và restore cần giữ. Không tự xóa bản cũ để lấy chỗ. Đóng gói binary thật, Lua/packages, config và web artifact; native backup script hiện chưa đủ bảo đảm binary/web và snapshot SQLite đang ghi.
- Diễn tập restore/rollback ở môi trường test; ghi schema compatibility, dữ liệu nào cần giữ và cách xử lý khi release mới đã ghi. Chốt cách chặn phòng mới, số room/session cần drain, ngưỡng health/latency/RAM/PSI/OOM và điều kiện rollback. Không suy server hiện có sẵn lệnh drain.
- Chuẩn bị checklist và release note thay đổi tướng/bài/pool, giờ bảo trì và thời lượng dự kiến sau khi đã diễn tập. Chỉ gửi thông báo cho người khác nếu được chỉ thị riêng.

**U8-B — Cửa sổ chuyển đổi**

1. Ngừng nhận phòng mới theo cơ chế đã kiểm, chờ room/session đang chơi kết thúc, chốt trạng thái reconnect. Không chuyển nóng room giữa hai native.
2. Tạo final DB snapshot nhất quán khi quiescent; kiểm backup đọc được và hash. Giữ account/history theo migration đã duyệt, không đưa DB QA lên live.
3. Dừng native cũ có kiểm soát, bảo toàn thư mục/binary/config/DB cũ. VM chỉ chạy một native phục vụ tại một thời điểm trong đợt chuyển.
4. Chuyển root/native/runtime và gateway manifest/bundle cùng identity; cập nhật web production theo artifact đã verify. Giữ maintenance trong khoảng các thành phần chưa đồng bộ; không giả định publish native/Pages là atomic.
5. Kiểm readiness/service/listener/local-public hash, OAuth, tạo-vào phòng, cặp tướng, skill, GameOver, reconnect và update/cache. Chỉ mở tiếp nhận đầy đủ sau smoke đạt.

**U8-C — Sau chuyển đổi và rollback**

- Quan sát giai đoạn đầu có người kiểm, rồi ghi evidence ở các mốc sau đã chốt; khoảng canary/thời hạn giữ backup xác định trước rollout, không tự coi một lần HTTP 200 là nghiệm thu ổn định. Kế hoạch không tạo automation theo dõi hoặc tự hứa theo dõi nền.
- Dừng rollout/không mở phòng mới khi có privacy/rule P0, crash/hang, sai hash, reconnect regression, OOM hoặc vượt ngưỡng vận hành đã chốt. Revert native/runtime/web cùng identity; nếu có dữ liệu mới phải dùng chính sách rollback tương thích, không restore đè mất ghi mới.
- Giữ old release/tag/backup sau phát hành. Chỉ dọn thư mục/ref được chỉ rõ khi canary đạt, backup/restore còn dùng được và không còn phụ thuộc. Không xóa `main`, lịch sử source, Shop hoặc backup cuối. Không duy trì process native cũ chỉ để giữ khả năng rollback.

**Đạt khi:** production mới gameplay/reconnect PASS, identity thống nhất, vận hành trong budget VM và rollback thực hiện được. Nếu fail, bản cũ tiếp tục là production được hỗ trợ; không coi đã hoàn thành nâng chỉ vì build mới tồn tại.

## 12. Tiến độ hiện tại và lệnh giao bước đầu

| Bước | Trạng thái khi lập kế hoạch |
| --- | --- |
| U0 | OPEN; đã có khảo sát identity/capacity, chưa tái tạo đầy đủ baseline/backup/patch |
| U1 | PARTIAL; có remote/diff Hegemony, còn inventory ba phía/graph/scenario đầy đủ |
| U2 | PARTIAL; source Wasmoon START/registry PASS, còn behavior/native/patch decisions |
| U3–U4 | Chưa áp dụng snapshot/build candidate mới |
| U5–U7 | OPEN; chưa nghiệm thu target mới ở luật/native/full-game/reconnect |
| U8 | Chưa sẵn sàng; chưa stage/promote hoặc diễn tập rollback target mới |

Không đặt ngày hoàn tất giả định trước khi U1/U2 làm rõ khối lượng tương thích. U0→U1 có thể tiến hành trước; U2 quyết định snapshot, rồi U3/U4 chuẩn bị để U5/U6/U7 kiểm. Việc dịch/media độc lập có thể làm sau khi khóa inventory, nhưng artifact/test cuối phải cùng revision.

**Prompt giao việc đầu tiên:** “Triển khai U0 theo `docs/web-client/UPSTREAM_INCREMENTAL_PLAN_2026-10-25.md`: đóng băng/tái tạo baseline production có patch, ghi parity source–live và artifact/backup metadata, chuẩn bị workspace riêng và xác định môi trường native QA ngoài VM live. Bảo toàn mọi dirty change, kiểm baseline, cập nhật state/plan/checkpoint; chưa nâng pin hoặc thay production.”

Tài liệu bằng chứng: [rà soát upstream](UPSTREAM_REVIEW_2026-10-25.md), [tài nguyên production](PRODUCTION_CAPACITY_2026-10-25.md), [gate kỹ thuật gốc](UPSTREAM_RELEASE_2026-10-17_PLAN.md). Những PASS trong đó thuộc các lượt đã quan sát; không phải bộ test mới của lượt chỉ lập kế hoạch này.
