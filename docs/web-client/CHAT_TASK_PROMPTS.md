# Prompt cho các chat TQS Mobile độc lập

> Mỗi block dưới đây dùng cho một chat mới do người dùng mở. Không dùng subagent. C00 chuẩn bị baseline trước; C01–C12 tự làm đầu việc, C13 kiểm toán cuối độc lập và giao kết quả để C00 hoàn tất release. Lượt soạn tài liệu này chưa tạo các chat.

Repository gốc: `/Users/otada/Documents/GitHub/tqs`.

## 1. C00 — Điều phối, baseline, tích hợp và release

Copy toàn bộ block này vào chat đầu tiên:

```text
Bạn phụ trách C00 — điều phối/tích hợp TQS Mobile, gồm R00 và Q01.
Repository: /Users/otada/Documents/GitHub/tqs.

Mỗi đầu việc sẽ do tôi giao cho một CHAT RIÊNG. Không dùng subagent,
không tự tạo chat khác và không tự làm thay toàn bộ nhiệm vụ chuyên trách.
Bạn tự thực hiện phần baseline, ownership, review, ghép, kiểm và release.

Đọc AGENTS.md, docs/CODEX_STATE.md, docs/CODEX_PLAN.md và
docs/web-client/{PARALLEL_COMPLETION_PLAN,CHAT_TASK_PROMPTS}.md.
Chỉ đọc phần liên quan của master plan. Xác nhận Git root/status/HEAD.

Làm R00 trước:
- Bảo toàn modified/untracked; HEAD hiện có thể chưa chứa CP06 đầy đủ.
- Kiểm checksum archive scratch/releases/web-2026-10-11-cp06.tar.gz.
- Chuẩn bị baseline đầy đủ và workspace riêng cho C01–C13 ngoài checkout gốc,
  runtime pin và tài liệu hướng dẫn hiện hành. Không copy credentials.
- Không tự commit thay đổi cũ, reset/clean hoặc giải nén đè checkout gốc.
- Có bản nền nguyên vẹn để so delta. Kiểm build baseline và ghi hashes.
- Tạo scratch/coordination/CP06/BASELINE.json trong repository gốc:
  source baseline/hash, runtime/version/MD5, integration workspace,
  workspace/reportDir của từng task, ownership và trạng thái chuẩn bị.
  Manifest không chứa secret. Workspace/reportDir phải là đường dẫn tuyệt đối.
- Tạo bảng task: ID/chat, scope, file sở hữu, phụ thuộc, điều kiện nhận,
  trạng thái, artifact, lịch live và lỗi còn mở.

Sau R00, bàn giao manifest và danh sách chat tôi nên mở trước.
Khi tôi cung cấp artifacts hoặc link/ID chat, nhận bàn giao theo task ID.
Không mặc định các chat tự đồng bộ lịch sử. Đọc/gửi chỉ dẫn sang chat khác
chỉ khi tôi trực tiếp cho phép; có thể điều phối qua artifacts trên filesystem.

Bạn sở hữu tích hợp shared bridge/store, App.tsx, dependency/lockfiles,
runner tổng hợp và CODEX_STATE/PLAN. Worker gửi patch cục bộ với API/event
rõ; review độc lập, yêu cầu sửa khi cần, rồi ghép từng gói vào integration
workspace. Ghi patch đã nhận để không áp hai lần; kiểm base hash trước ghép.
Nếu worker dùng nền cũ, yêu cầu delta/rebase lên candidate phù hợp.

Quản lịch live: một account/một phiên, hai clients cần hai account;
tách test gián đoạn khỏi smoke vì temp-ban có thể ảnh hưởng cùng IP.
Giữ deployment CP06 đóng băng, candidate dùng process/port riêng.
Không reload/HMR/restart giữa ván; không đổi IP/account để vượt ban.
Không sửa FreeKill rules/server hoặc TQSShop. Không lộ secret/bài kín.

Local PASS của chat chuyên trách chưa phải ACCEPTED của release.
Chạy kiểm tra phù hợp trên candidate đã ghép, nghiệm thu M1/M2/M3/M4
theo kế hoạch; chỉ đánh dấu live/device/hosting PASS khi thực tế quan sát.
Thiếu hardware/account/quyền host thì ghi PENDING và tiếp tục phần độc lập.

Trước release: có build/tests/evidence, source/runtime/dist hashes,
archive khôi phục và rollback đã kiểm. Chỉ triển khai trên đích/phạm vi
đã được người dùng chỉ định và có quyền truy cập. Không tự nâng upstream.
PLAYABLE_MOBILE chỉ true khi đúng master plan.
Sau các gói đã ghép, cấp candidate/hash cụ thể cho C13 kiểm toán cuối độc lập.
Xử lý mọi finding chặn release rồi kiểm lại; không đóng hoàn tất chỉ theo
số chat báo xong. V1 đóng theo danh sách hữu hạn đã chốt, mọi mục chưa đủ
coverage hoặc tài nguyên phải giữ PENDING và nêu cụ thể.

Sau mốc đáng kể, cập nhật CODEX_STATE/PLAN và chạy codex:checkpoint.
Báo cáo task đã nhận/ghép, kiểm thử, lỗi/owner, blocker và bước tiếp theo.
Bắt đầu ngay bằng R00; sau khi xong hãy đưa BASELINE.json, ownership,
lệnh kiểm tra, kết quả và các prompt/chat cần mở tiếp.
```

## 2. Quy tắc bàn giao của mọi chat chuyên trách

Các prompt bên dưới dẫn chiếu mục này để tránh lặp nội dung. Mỗi chat:

1. Đọc AGENTS.md, kế hoạch phân công và phần trạng thái liên quan; tự thực hiện task, không dùng subagent hoặc tự tạo chat khác.
2. Đọc `/Users/otada/Documents/GitHub/tqs/scratch/coordination/CP06/BASELINE.json`; chỉ sửa workspace được cấp cho task. Chưa có manifest/workspace thì làm audit độc lập, báo phần thiếu, không sửa checkout gốc.
3. Giữ baseline/runtime revision; không sửa TQSShop, luật upstream/server hoặc deployment CP06. Bảo toàn thay đổi khác, không tự commit/reset/clean thay đổi nền cũ.
4. File dùng chung: patch nhỏ + event/schema/API; C00 review/ghép. Không tự cập nhật CODEX_STATE/PLAN chung. Dependency/lockfile change phải được C00 tích hợp và kiểm tương thích.
5. Chỉ chạy live trong account/session/slot được cấp, tránh trùng phiên; không lộ secret/bài kín hoặc vượt temp-ban. Live/device/hosting thiếu tài nguyên giữ PENDING; không giả kết quả.
6. Bàn giao tại `reportDir` của task: `HANDOFF.md`, patch/delta **so với baseline**, changed-file hashes, lệnh/PASS/FAIL/log sạch/evidence, shared-file dependencies, phần chưa xong và rủi ro. `HANDOFF.md` ghi task ID, baseline hash và đường dẫn workspace.
7. Local hoàn tất ghi `READY_FOR_INTEGRATION`, kèm `LOCAL_PASS` và `LIVE_PENDING` nếu phù hợp. C00 mới đóng trạng thái `ACCEPTED` sau review và nghiệm thu bản ghép. Không mặc định chat khác nhận được kết quả; trả link artifacts trong final để người dùng chuyển cho C00.

## 3. C01 — L01: Việt hóa

```text
Thực hiện riêng C01/L01 — Việt hóa TQS Mobile.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ toàn bộ quy tắc bàn giao.
Không dùng subagent. Làm trong workspace C01 do BASELINE.json cấp.

Bắt đầu từ 祸水 của Trâu Thị và 礼下 của Sĩ Nhiếp đã gặp live ở CP06.
Đối chiếu đúng Lua/package pin, sửa tên/mô tả/prompt/log đúng variant;
rà chuỗi chưa dịch trong phạm vi gói L01. Phụ trách vietnamese.ts và
displayText.ts; giữ wire IDs và quyền xem thông tin.
Kiểm store/Lua/React DOM liên quan; audit mới riêng, không sửa evidence gốc.
Coverage inventory toàn dự án thuộc C02; gửi danh sách key/case cho C00.
Giao patch, HANDOFF và bằng chứng local/live đúng mức quan sát.
```

## 4. C02 — L02: Inventory và coverage

```text
Thực hiện riêng C02/L02 — inventory và coverage theo package pin.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C02 trong BASELINE.json.

Lập bảng enabled packs, kỹ năng/dialog/chuỗi bắt buộc và các case luật
Kỳ Trân/lập quốc/Quyết chiến; ghi mapping source → task owner → test/evidence
→ local/live/thiếu. Dùng evidence thật, không coi regex là review ngữ nghĩa.
Đầu ra là tài liệu/matrix kiểm chứng, không sửa code dịch/dialog của chat khác.
Nhận artifacts qua C00/người dùng để cập nhật coverage. Chỉ nêu task mới
khi có source/case cụ thể; không tự mở chat hoặc phát triển ngoài scope.
Giao coverage matrix, source references và HANDOFF cho C00.
```

## 5. C03 — D01: Chọn/xem bài

```text
Thực hiện riêng C03/D01 — hoàn tất GAME-03A chọn/xem bài.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; chỉ sửa workspace C03 trong BASELINE.json.

Kiểm/sửa AskForCardChosen, CardsChosen/Poxi và CardsAndChoice:
bài úp/công khai, min/max/filter/cancel, xem bài, lấy/bỏ bài, multi-selection.
Lua quyết định validation/reply. Phụ trách selection engine/panels của D01;
shared bridge/store/runner giao patch cục bộ cho C00.
Stale/expiry/replacement/duplicate/privacy phải PASS; cần server nhận
lựa chọn thật và ván tiếp tục để nghiệm thu live. Live chỉ theo lịch C00.
Giao API/schema rõ để C04 xây dialog bổ sung mà không làm lại phần D01.
```

## 6. C04 — D02: Dialog bổ sung

```text
Thực hiện riêng C04/D02 — dialog còn thiếu trong phạm vi package công bố.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C04 trong BASELINE.json.

Inventory AG/Guanxing/Exchange/Yiji/LuckCard/CustomDialog thực sự được
Lua pin sử dụng. Ưu tiên request bắt buộc làm kẹt trận; lập mapping command,
snapshot, UI, native validation và reply. Không reply tùy ý để vượt dialog.
Audit có thể làm ngay; code dùng interface D01 sau khi C00 cấp contract.
Viết module/test riêng, phối hợp C03 qua C00, không sửa chồng selection core.
Giao patch/case/evidence và danh mục dialog còn thiếu theo mức P0/P1/P2.
```

## 7. C05 — R01: Cứu Đào và luật

```text
Thực hiện riêng C05/R01 — hoàn tất GAME-03C và coverage T06/T07 liên quan.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; chỉ sửa workspace C05 trong BASELINE.json.

Đối chiếu Lua pin và PEACH_RESCUE_VERIFICATION.md: Thiểm/Đào, target cứu,
HP âm/cứu nhiều lần, hủy không mất bài, view-as/Đào ảo, Quyết chiến cũ/mới,
ignore mark và lập quốc. Không viết lại/chỉnh luật server.
HP/hand/state theo event server; Lua sinh reply. Shared bridge/store chỉ
patch cục bộ gửi C00; gửi key/meaning cần dịch cho C01 qua artifacts.
Kiểm fixture và ca live được cấp lịch; giao evidence phân biệt rõ hai loại.
```

## 8. C06 — R02: Trạng thái bàn và privacy

```text
Thực hiện riêng C06/R02 — state bàn/visibility và coverage GAME-03B.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C06 trong BASELINE.json.

Kiểm Self hidden pair, opponent reveal/ẩn lại, HP 0/âm, xích/úp mặt,
trang bị/delayed zones/marks và thay đổi trạng thái. Không lộ thông tin kín
ở snapshot/store/DOM/log. Rà kỹ năng/state thuộc gói R02 theo inventory.
Logic board do bạn sửa; layout/CSS thuộc C09, gameplay cứu Đào thuộc C05.
Patch shared store/bridge gửi C00; không tự ghi đè contract của chat khác.
Giao privacy/state tests, patch, bằng chứng live được cấp và HANDOFF.
```

## 9. C07 — N01: Reconnect

```text
Thực hiện riêng C07/N01 — reconnect và session lifecycle TQS Mobile.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C07 trong BASELINE.json.

Đối chiếu protocol/session thật trước khi thiết kế reconnect. Kiểm backoff,
socket/callback/timer cũ, background/foreground, room close/owner quit,
pending request sau reconnect và state recovery. Nếu server không giữ phiên,
báo kết thúc rõ; không dựng lại game state bằng phỏng đoán hoặc false online.
Phụ trách connection/connectionMessages/gameAdapter lifecycle; shared store
giao patch C00. Giao API và test cho C08/C09 qua artifacts.
Test gián đoạn trên môi trường/lịch được cấp, tránh drop ván production.
```

## 10. C08 — N02: Hai clients và multiplayer

```text
Thực hiện riêng C08/N02 — harness và nghiệm thu hai clients/tài khoản.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C08 trong BASELINE.json.

Chuẩn bị E2E riêng: create/join/ready/seats/turn, privacy chéo hai clients,
full game/GameOver/về sảnh. Hai clients dùng hai account riêng được cấp.
Harness có thể làm ngay; live/reconnect nghiệm thu trên candidate C00
đã ghép C03–C07 và các gói liên quan, không trên tập hợp branch rời.
Không sửa chồng core connection của C07; báo bug/contract cần sửa cho C00.
Khi thiếu account/device, bàn giao harness local và ghi live/device PENDING.
Giao patch, trace sạch/evidence và HANDOFF cho C00.
```

## 11. C09 — M01: Mobile/PWA/hiệu năng

```text
Thực hiện riêng C09/M01 — mobile UX, PWA nền, QA và hiệu năng.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C09 trong BASELINE.json.

Phụ trách styles/index/public, dọc/ngang/safe-area, touch targets,
scroll/keyboard/dialog/logs, PWA shell và đo tải/bộ nhớ/renderer.
Board JSX/state cần patch phối hợp C06/C00; không đổi luật, timeout hoặc
request/reply để che lỗi hiệu năng. Cache không trộn revision/runtime.
QA iOS Safari và Android Chrome vật lý trên candidate tích hợp; viewport
desktop không là device PASS. Thiếu hardware ghi rõ và làm phần độc lập.
Giao patch, device/OS/browser/video/ảnh, số đo thực và HANDOFF.
```

## 12. C10 — S01: Gateway/security

```text
Thực hiện riêng C10/S01 — gateway hardening, privacy và dependency audit.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C10 trong BASELINE.json.

Kiểm Origin/bind/proxy trust, traversal/symlink, frame/queue limits,
backpressure/rate, invalid input, bundle URL/version/immutable semantics.
Giữ raw CBOR/protocol tương thích. Phụ trách game/gateway; dependency và
lockfiles sửa qua patch C00. Assess node-forge theo advisory/đường code thực,
không tự đổi crypto sang thuật toán server không nhận.
Kiểm T14/T15 và gateway tests trên server test; privacy logs không secret.
Giao config contract cho C11, patch/tests/audit và HANDOFF cho C00.
```

## 13. C11 — O01: Hosting và vận hành

```text
Thực hiện riêng C11/O01 — hosting web/gateway độc lập Mac và vận hành.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C11 trong BASELINE.json.

Chuẩn bị deployment/service/config riêng, HTTPS/WSS, monitoring/quota,
restart/reboot và rollback. Giữ nguyên FreeKill server/data/upstream và
TQSShop. Quick Tunnel hiện tại không đủ điều kiện hosting 24/7.
Đối chiếu đích/quyền truy cập đã có; thiếu host/key/domain thì báo cụ thể,
hoàn tất artifact/config/runbook độc lập. Không tìm/đọc secret không liên quan.
Nhận config contract C10 và candidate/artifact đã được C00 kiểm trước deploy.
Giao URL/hash/version, bằng chứng restart/rollback/4G thực tế hoặc PENDING,
deployment files/runbook và HANDOFF cho C00.
```

## 14. C12 — V01: V1 mở rộng

```text
Thực hiện riêng C12/V01 — checklist V1 mở rộng đã chốt của TQS Mobile.
Repo gốc /Users/otada/Documents/GitHub/tqs. Đọc AGENTS.md và
docs/web-client/CHAT_TASK_PROMPTS.md mục 2; tuân thủ quy tắc bàn giao.
Không dùng subagent; dùng workspace C12 trong BASELINE.json.

Đầu tiên đối chiếu capability Lua/server và lập danh sách hữu hạn về assets,
UX/animation, chat/spectator/replay, performance/canary. Chỉ triển khai
features được chốt và có upstream support; feature ngoài scope ghi backlog.
Inventory/design làm sớm; code dùng module/feature flag riêng, không làm
chậm hoặc đổi protocol đường M1–M3. Baseline candidate nhận qua C00.
Giao patch từng feature, regression/evidence, giới hạn supported và HANDOFF.
Nếu danh sách cần tách thêm task, đề xuất cho người dùng/C00, không tự mở chat.
```

## 15. Prompt gửi kết quả về C00

Sau mỗi chat chuyên trách, người dùng copy câu này vào C00 và thay đường dẫn:

```text
Nhận bàn giao [TASK_ID] từ chat [CHAT_ID/tên chat nếu có].
HANDOFF: [đường dẫn tuyệt đối]
Patch/artifacts: [đường dẫn tuyệt đối]

Đọc báo cáo và patch, đối chiếu baseline hash và phạm vi ownership.
Review độc lập; nếu đạt, ghép vào integration workspace, chạy checks liên quan
và cập nhật trạng thái. Nếu chưa đạt, ghi yêu cầu sửa cụ thể để tôi chuyển
cho chat chuyên trách. Không coi local PASS là live/release PASS.
```

Nếu người dùng muốn C00 nhắn trực tiếp, phải cho phép trong chat C00 và cung cấp ID/tên để xác định đúng chat. Nếu không, cách chuyển link artifacts bằng prompt trên vẫn đủ để tích hợp.

## 16. C13 — F01: Kiểm toán nghiệm thu cuối độc lập

```text
Thực hiện riêng C13/F01 — kiểm toán nghiệm thu cuối TQS Mobile.
Repository gốc: /Users/otada/Documents/GitHub/tqs.
Đọc AGENTS.md, CHAT_TASK_PROMPTS.md mục 2, kế hoạch phân công và
master plan. Không dùng subagent hoặc tự tạo chat khác.

Nhận candidate source/runtime/dist hashes và workspace kiểm thử từ C00
qua BASELINE.json/artifacts; kiểm đúng bản đã ghép, không kiểm baseline cũ.
Không tự sửa code/deploy; tái hiện bug, xác định mức độ, owner và case sửa.
Kiểm trong bản copy candidate được cấp; lưu artifacts ở reportDir C13.

Đối chiếu coverage C02 và checklist M1–M4 với bằng chứng hiện hành:
manual bot game; hai clients; dialog/luật; privacy/state; reconnect;
iOS/Android thật; HTTPS/WSS qua mạng di động; security/dependencies;
restart/rollback; archive restore; features V1 đã chốt. Chạy lại checks
cần thiết theo phạm vi thay đổi hoặc thiếu evidence, không giả live PASS.
Kiểm evidence gắn cùng candidate; fixture không thay live/device/hosting.
Nếu thiếu thiết bị/account/host hoặc case chưa phủ, ghi PENDING cụ thể.

Giao FINAL_ACCEPTANCE.md, bảng từng tiêu chí PASS/FAIL/PENDING/N_A
(N_A có lý do/phạm vi), lệnh/evidence sạch và findings P0/P1/P2 có owner.
Chỉ kết luận COMPLETE cho phạm vi đã chốt khi đủ bằng chứng và không còn
finding chặn release; còn thiếu phải kết luận INCOMPLETE kèm việc cần làm.
Trả link artifacts cho người dùng chuyển C00 để quyết định release cuối.
```

## 17. Prompt yêu cầu sửa ở chat chuyên trách

```text
Tiếp tục task [TASK_ID] trong chat này, tự làm, không dùng subagent.
C00/C13 đã ghi finding: [mã finding và mô tả].
Evidence/reproduction: [đường dẫn tuyệt đối].
Candidate/baseline cần dùng: [manifest/hash/workspace do C00 cấp].

Đối chiếu và sửa trong phạm vi task. Giữ thay đổi khác, không sửa checkout
gốc/deployment hoặc tự đóng finding chung. Chạy kiểm tra liên quan.
Giao patch delta từ đúng nền, HANDOFF cập nhật, bằng chứng và giới hạn.
Nếu cần thay contract hoặc task khác, nêu cụ thể cho C00 phối hợp.
```

## 18. Prompt chốt release ở C00

```text
Nhận kết quả kiểm toán cuối C13:
FINAL_ACCEPTANCE: [đường dẫn tuyệt đối].
Candidate/release manifest: [đường dẫn tuyệt đối].

Review độc lập từng finding và sự đồng nhất source/runtime/dist.
Nếu còn FAIL/PENDING chặn phạm vi hoàn tất, lập yêu cầu sửa gửi đúng chat
qua artifacts để tôi chuyển, tiếp tục các việc độc lập và giữ trạng thái mở.
Nếu đủ tiêu chí, hoàn tất release trên đích đã có quyền, kiểm public health/
HTTPS/WSS và smoke phù hợp, kiểm archive/rollback, cập nhật bàn giao/plan,
chạy codex:checkpoint và lập FINAL_RELEASE_REPORT.md với URL, hashes,
test/device/hosting evidence, coverage và giới hạn. Không tự commit thay đổi
nền cũ hoặc gắn hoàn tất cho hạng mục chưa thực tế nghiệm thu.
```
