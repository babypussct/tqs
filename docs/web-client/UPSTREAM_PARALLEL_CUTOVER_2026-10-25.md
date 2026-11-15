# Nâng Hegemony song song production và chuyển bản mới — 25/10/2026

> **Thay thế quyết định điều phối 28/10/2026:** [UPSTREAM_FIRST_MASTER_PLAN_2026-10-28.md](UPSTREAM_FIRST_MASTER_PLAN_2026-10-28.md) sử dụng một candidate upstream; không duy trì hai tuyến production song song. Tài liệu này chỉ giữ các lưu ý kỹ thuật về DB, drain, identity và rollback.

> **Đã được thay bằng quyết định tiếp theo của người dùng:** [UPSTREAM_INCREMENTAL_PLAN_2026-10-25.md](UPSTREAM_INCREMENTAL_PLAN_2026-10-25.md). Giữ live hiện tại, nâng/test dần ở local/môi trường riêng; không dựng native thường trực thứ hai trên VM production. Tài liệu dưới đây giữ khảo sát kỹ thuật lịch sử và nguyên tắc drain/identity/DB/rollback, không còn là chỉ thị dựng hai tuyến thường trực.

**Yêu cầu người dùng:** giữ production hiện tại tiếp tục chạy trong lúc nâng Hegemony đến upstream mới nhất; chỉ bỏ bản production cũ sau khi bản mới hoàn tất và vận hành được.

**Kết luận kiểm tra:** có thể thực hiện bằng hai tuyến native–gateway–web độc lập. Checkout/launcher/Pages hiện tại **chưa cấu hình sẵn hai tuyến**; không chỉ tạo nhánh Git rồi chạy bootstrap trên máy production. Thứ tự là **giữ cũ → dựng mới song song → nghiệm thu → chuyển traffic → xác minh ổn định → dừng/dọn cũ**. Không xóa bản cũ trước khi bản mới nhận traffic thành công. Tài liệu này chốt phương án, chưa dựng candidate hoặc thực hiện cutover/xóa.

> **Capacity đã xác minh tiếp trong ngày:** [PRODUCTION_CAPACITY_2026-10-25.md](PRODUCTION_CAPACITY_2026-10-25.md). Alias production đúng là `tqs-native-qa-replacement`, SSH PASS; alias đã thử trước đó thuộc VM cũ. Máy E2.1.Micro có 2 logical vCPU, RAM 954 MiB/khả dụng khoảng 398 MiB, swap dùng 272 MiB, disk available 18,48 GiB; CPU mẫu 10 giây 99,85% idle. RAM là ràng buộc: ưu tiên build/candidate ở môi trường riêng, chưa chấp nhận hai production instance trên cùng host từ snapshot này.

## 1. Những gì đã kiểm tra trực tiếp

| Nội dung | Kết quả ngày 25/10 |
| --- | --- |
| Git local | Chỉ có nhánh `main@936f3f8c`; không có nhánh tên `production`. Không có managed worktree gắn với chat; các worktree tạm cũ đều prunable, không sử dụng hoặc dọn trong phiên |
| Production public | `GET /gateway/healthz` **200**, body `ok`; `/gateway/manifest.json` **200**; `/version.json` **200** qua curl |
| Web đang phục vụ | Version `0.5.25`, build ID `9778d65e6d92a29b8fcdb3f3b6d28b4de9dbe4a96085ff703a1fb1a3b5cd4797`, builtAt `2026-10-24T19:03:55.237Z` |
| Runtime public manifest | MD5 `845498010a0c9f790254ec86e3dfc999`, bundleHash `5beabc83feac2d67`, fileCount `5281` |
| Bootstrap source/static | Đều có lệnh thay `$ROOT/current` trước khi cài package. Chạy mặc định sẽ chạm tuyến live |
| Native listener | Source pin `src/server/server.cpp` cố định admin HTTP `tcp::v4(), 9000`; cổng game khác không giải quyết xung đột admin trên cùng network namespace |
| Launcher | `run-server.sh` source `versions.env` rồi dùng `FREEKILL_PORT`; file pin gán `9527`, nên chỉ truyền biến môi trường cổng khác trước lệnh chưa đủ. Service mẫu cố định tmux `freekill-native` và working directory `current` |
| Gateway | Có cấu hình `FK_ROOT`, `FK_HOST`, `FK_PORT`, `PORT`, `ALLOW_ORIGIN`; có thể dựng instance độc lập nhưng phải trỏ root bất biến của chính release |
| Pages proxy | Một target được lấy từ `TQS_NAMED_TUNNEL_HOSTNAME` hoặc KV `TQS_GATEWAY_CONFIG/quick-tunnel-url`. Preview dùng lại binding/target live có thể đưa client mới vào native cũ |
| CI | Workflow hiện chạy PR, push `main`, hoặc `workflow_dispatch`; push riêng nhánh mới không tự chứng minh đã chạy đủ CI |
| Host capacity/live service | Lượt đầu dùng alias VM cũ bị publickey; lượt tiếp dùng `tqs-native-qa-replacement` **SSH PASS**, manifest local/public khớp và live service/process xác nhận. Số liệu tại báo cáo capacity; chưa chứng nhận đủ RAM để chạy hai production instance |

HTTP 200 chỉ chứng minh các endpoint public trả lời và metadata đang phục vụ; chưa phải authenticated gameplay/reconnect PASS. urllib/web reader có lỗi truy cập, curl trên đúng đường dẫn đã PASS. Evidence metadata: `scratch/upstream-parallel-review-20261025/inspection.json`, `production-version.json`, `production-manifest.json`. Không đọc secret hoặc thay cấu hình remote.

## 2. Tách nhánh source và tách dịch vụ đang chạy

Nhánh Git giữ mã nguồn; production đang chạy artifact và process đã triển khai. Xóa nhánh không chuyển được traffic hay dừng process. `main` còn chứa TQSShop, vì vậy không xóa `main` để thay riêng Quốc Chiến.

- **Source cũ:** sau khi đối chiếu source thực với web/native đang phục vụ, lưu release manifest, commit, toàn bộ patch sau pin, artifact và một tag hoặc ref giữ lịch sử. Không coi HEAD tài liệu hiện tại là đủ để tái tạo binary/runtime live.
- **Source mới:** worktree riêng, nhánh dự kiến `codex/upstream-hegemony-20261025`; target Hegemony mới nhất đã xác minh trong phiên là `d069cd1f5c6df8d93af0ea101b82a5bed2781f01`. Kiểm lại remote khi đóng băng target. Dependency giữ pin trừ phần U1/U2 chứng minh cần đổi. Không tự mang hoặc commit 5 tệp dirty của checkout chính vào candidate.
- **Promotion source:** sau nghiệm thu, tích hợp thay đổi game đã review về nhánh phát hành/main theo mapping CI, bảo toàn Shop. Deploy theo artifact đã verify; Pages vẫn Direct Upload, không bật auto-deploy hoặc nối Git như hệ quả của việc tạo nhánh.
- **Dọn nhánh cũ:** chỉ áp dụng cho ref chuyên dụng của đợt cũ nếu sau này có tạo; chỉ dọn sau promotion, kiểm merge/lịch sử và giữ tag/backup. Hiện không có ref `production` để xóa.

## 3. Hai tuyến phải độc lập trước khi chạy song song

| Thành phần | Production cũ | Candidate nâng upstream |
| --- | --- | --- |
| Web | Giữ alias `tqsvn.pages.dev` và deployment cũ | Hostname riêng; ưu tiên Pages Direct Upload project riêng để tách target/binding. Nếu dùng preview cùng project phải chứng minh config preview độc lập |
| Proxy/tunnel | Giữ nguyên KV target, tunnel và DNS live | Tunnel/target riêng; không chạy registrar QA ghi vào key production |
| Gateway | Giữ root/backend hiện tại | Process/service riêng, root release mới bất biến; backend native candidate; origin chỉ cho web candidate |
| Native | Giữ service/process/cwd/config hiện tại | Runtime, config, package DB, server DB, log, service/tmux độc lập |
| Network | Giữ game/admin/gateway live | VM riêng hoặc container/network namespace riêng. Nếu cùng host phải cô lập cả admin `9000`; không chỉ đổi game port |
| Resource | Giữ đủ RAM/CPU/disk cho live | Giới hạn CPU/RAM/PID/room quota, build ít worker. Chỉ khởi động sau capacity preflight; không build/chạy không giới hạn cạnh live |
| Auth | Giữ endpoint/session flow live | Kiểm OAuth authorized origin/redirect và ticket native trên host candidate. Dùng cơ chế secret được quản lý, không hardcode/ghi log; không nới quota/authorization của production |
| Dữ liệu | Tiếp tục ghi vào DB live | DB QA riêng; bản snapshot phải nhất quán và quyền truy cập phù hợp. Không để hai native cùng ghi một server DB/packages DB |
| Build/cache | Giữ web/runtime identity cũ | Build ID, manifest, flist, SW cache khớp release mới; không ghép web mới với native cũ |

Không chạy bootstrap mặc định vào `/opt/freekill-hegemony/current`. Phải dùng deploy tree/root thử riêng đã kiểm các giá trị pin/config, hoặc sửa cơ chế staging để chỉ tạo candidate mà không promote. Giữ binary native release bất biến; bootstrap source hiện symlink binary tới source build, nên phải pin/đóng gói cả đích binary, tránh rebuild source tree làm đổi bản cũ.

## 4. Trình tự nghiệm thu và cutover

1. **U0–U3:** đóng băng baseline cũ, source/patch/binary/web/runtime identity và sơ đồ hai tuyến; dựng candidate độc lập, chốt snapshot Hegemony mới; port từng hunk và không thay live.
2. **U4–U6:** build/verifier/hash parity, kiểm pool 301→233 và mọi delta P0 luật/privacy, native bot/hai người, skill/request/GameOver/reconnect. Rerun AI/request/hardening/Tử Gián và key bản dịch đổi. CI trên đúng revision candidate qua PR hoặc dispatch, không suy ra từ CI pin cũ.
3. **U7:** web candidate chỉ gọi manifest/bundle/ws của native candidate; OAuth → tạo/vào phòng → chủ/phó → bài/kỹ năng → GameOver → reconnect PASS. Kiểm cache/update guard và client cũ. Physical iOS/Android/network giữ `WAIVED_BY_USER`; ghi rõ coverage.
4. **U8 preflight:** kiểm backup/restore native+web, tài nguyên, endpoint, quản lý service và rollback. `backup.sh` hiện tar config/packages/server, `verify-backup.sh` chỉ kiểm cấu trúc/quyền; **chưa bảo đảm snapshot SQLite đang ghi nhất quán, chưa gồm native binary/build target hoặc web artifact**. Cần SQLite backup API hoặc snapshot lúc quiescent, backup binary/target source/artifact riêng và restore rehearsal.
5. **Drain:** không nhận phòng mới ở tuyến cũ bằng cơ chế đã kiểm chứng hoặc một cửa sổ bảo trì có thông báo; để ván cũ kết thúc và reconnect về đúng process cũ. Trước khi chuyển tuyến mặc định, xác minh số ván/kết nối còn lại bằng telemetry quản trị thực. Không giả định đã có lệnh drain trong runner hiện tại.
6. **Final data:** sau drain/quiesce, chốt snapshot DB cuối, kiểm schema và chính sách mang account/history sang bản mới. Không ghi đè DB candidate bằng dữ liệu đang thay đổi; không kéo DB test chứa account/room QA vào production. Cập nhật/khởi động bản mới với dữ liệu chính thức rồi kiểm readiness.
7. **Promote:** chuyển đồng bộ web production, proxy/backend target và native release identity sang tuyến mới đã sẵn sàng. Endpoint cũ phải còn sẵn để rollback; kiểm lại HTTP/hash và authenticated gameplay/reconnect sau switch. Nếu thao tác không atomic, dùng cửa sổ bảo trì để tránh client mới/manifest cũ trong khoảng chuyển.
8. **Ổn định và dọn cũ:** theo dõi khoảng canary đã chốt trước cutover, kiểm room/AI/error/privacy/reconnect và DB. Chỉ khi tất cả tiêu chí đạt, không còn session cần tuyến cũ và restore/rollback vẫn khả dụng mới dừng service/tunnel cũ; sau đó mới dọn ref/thư mục được chỉ rõ. Giữ source tag/backup và artifact cũ trong thời hạn rollback được chốt; không tự `rm -rf` hoặc xóa backup.

**Không chuyển nóng room đang chơi giữa hai native:** state nằm trong process, WebSocket cũ không tự di chuyển và reconnect có thể về sai room nếu đổi một KV toàn cục. Phương án mặc định là drain rồi switch, có thể cần khoảng bảo trì ngắn. Nếu muốn không ngắt tiếp nhận người chơi trong lúc drain, phải triển khai/test routing giữ affinity theo release cho login/manifest/bundle/ws/reconnect trước; proxy hiện tại chưa cung cấp điều đó. Không hứa zero-downtime chỉ từ blue/green.

Rollback sau khi tuyến mới đã ghi dữ liệu phải có chính sách tương thích schema và giữ dữ liệu mới; không restore đè DB cũ mù quáng. Nếu bản mới đã có phòng đang chạy, rollback còn phải xử lý drain/ảnh hưởng phiên, không chỉ đổi symlink.

## 5. Gate cụ thể trước khi bỏ bản cũ

- Target mới nhất đã được đóng băng bằng full SHA; U0–U8 đạt trong phạm vi Quốc Chiến, phần waived ghi riêng.
- Authenticated candidate và production sau switch đều đạt; native/web/gateway/manifest đúng cùng release.
- Ván/kết nối cũ đã hết; không còn reconnect cần process cũ; dữ liệu cuối đã xử lý nhất quán.
- Canary đạt các tiêu chí/thời lượng được chốt trước; rollback/restore đã diễn tập và backup đọc được.
- Đối tượng dọn có danh sách rõ: service/process/tunnel/root/ref nào; không xóa `main`, Shop, dữ liệu mới, source lịch sử hoặc backup rollback.

**Bước tiếp:** thực hiện U0 có thêm ma trận hai tuyến và lựa chọn môi trường candidate dựa trên capacity đã đo. SSH production đã hoạt động qua alias đúng; giữ live trên VM hiện tại, ưu tiên build/candidate riêng vì RAM thấp. Không có service, branch, DB, KV, DNS hoặc deployment nào bị thay/xóa trong các lượt kiểm tra này.
