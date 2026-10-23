# Kế hoạch tổng kết và prompt nâng upstream TQSVN

Chốt ngày **19/10/2026** theo phạm vi người dùng đã xác nhận. Đây là kế hoạch giao việc, **chưa triển khai nâng pin hoặc phát hành**. Mã U0–U8 giữ nguyên để tiếp nối kế hoạch chi tiết.

## Mục tiêu và nguyên tắc chọn phiên bản

**Quốc Chiến từ Hegemony, mode `new_heg_mode`, phải vận hành đúng từ đầu đến cuối trên web/điện thoại.** Nghiệm thu gồm đăng nhập, tạo/vào phòng, chọn chủ/phó, ẩn/lộ tướng, dùng bài/kỹ năng và trả lời request, GameOver/kết quả, reconnect và giữ thông tin kín. Core và các repo luật/phụ thuộc là thành phần bắt buộc phải đánh giá trong phạm vi phục vụ Quốc Chiến.

- Hegemony là nguồn luật/nội dung chính. `freekill-asio`, `freekill-core`, `utility` và các repo skill/card/helper được xem xét theo phụ thuộc trực tiếp, gián tiếp, lỗi luật và hành vi chung có tác động tới Quốc Chiến.
- **Đánh giá đầy đủ để chọn giữ/nâng từng repo.** Giữ pin là quyết định cần có căn cứ tương thích, không phải giả định rằng repo phụ không quan trọng. Một bản sửa luật/privacy liên quan có thể cần lấy dù bản cũ vẫn khởi động được.
- Không mặc định nâng tất cả HEAD; không bỏ dependency đang dùng chỉ để giảm số repo. Nội dung/mode không liên quan nằm ngoài nghiệm thu trừ khi làm hỏng boot/registry hoặc phần dùng chung của Quốc Chiến.
- Target Hegemony đã khảo sát: `d069cd1f5c6df8d93af0ea101b82a5bed2781f01`. Đây là mốc khảo sát, U1/U2 sẽ chốt bộ SHA phát hành cụ thể; không tự theo moving master.
- Báo cáo trước: Hegemony mới + dependency cũ START PASS/0 reference active thiếu, chưa chứng minh tương thích effect/native E2E. Pool active/visible 301→233, overseas 76→5 và card count Cửu Biến/lord thay đổi phải được U5 nghiệm thu. Lỗi duplicate Mưu Công chỉ phát sinh với tổ hợp Mobile mới + mougong được thử, không phải blocker mặc định khi giữ Mobile cũ.

## Các giai đoạn

| Bước | Công việc | Bàn giao và điều kiện hoàn thành |
| --- | --- | --- |
| **U0 — Baseline và cách ly** | Lưu source đang dùng, các thay đổi dirty cần giữ, pin/native binary/web/manifest/MD5 và trạng thái test. Tạo worktree/runtime thử nghiệm riêng; không dùng writable DB/port live. | Baseline tái tạo được, biết source nào đang thử, có bản cũ và cách phục hồi. |
| **U1 — Diff và phụ thuộc Quốc Chiến** | Chốt Hegemony target bằng full SHA; lập graph skill/card/helper/API. Đánh giá diff liên quan trong core/utility/nhóm repo luật, kể cả bản sửa lỗi ảnh hưởng Quốc Chiến. | Bảng `repo/file/skill → tác động → test`; tách thay đổi cần xét và phần ngoài scope, không suy ra luật từ số commit. |
| **U2 — Chốt bộ phiên bản tương thích** | Chạy spike trên runtime cô lập; kiểm API, event lifecycle, hidden skill/private state, patch TQS và native worker. Đánh giá đủ các repo ở U1; chọn giữ/nâng có lý do, không chỉ dựa vào START PASS. | Ma trận `repo → SHA cũ/đích → giữ/nâng → lý do/bằng chứng`; xử lý blocker boot/owner/patch nếu có. Chốt snapshot để U3 thực hiện. |
| **U3 — Áp dụng pin và bản vá** | Áp dụng snapshot U2 trong nhánh thử; đồng bộ pin native/browser, source, declaration repair, installer/verifier và QA. Chỉ đổi tập repo nếu U2 chứng minh cần. | Các thành phần cùng SHA và nội dung sau vá; không thiếu/trùng skill/tướng, không mất hardening. |
| **U4 — Build và đồng bộ artifact** | Cài/build native runtime phù hợp, web/Wasmoon, Lua bundle, media, flist, DB registry, manifest/RELEASE và service worker. Nếu không đổi native source, xác minh binary pin phù hợp và ghi rõ việc tái sử dụng. | Installer/verifier/build đạt, identity/hash native–web–gateway khớp; asset phục vụ Quốc Chiến đầy đủ. Output đúng thư mục riêng. |
| **U5 — Luật, pool và thông tin kín** | Kiểm delta tướng/bài/skill của Quốc Chiến đang bật; pool theo capacity × generalNum (5/7/10 lá mỗi người), policy khóa gói, tương tác/lifecycle và privacy; nghiệm thu danh mục bị giảm/thay đổi. | Kịch bản cho delta luật/privacy P0 PASS; giữ đúng luật snapshot, không tự bỏ skill hay sửa luật để vượt test. Ghi rõ coverage còn thiếu. |
| **U6 — Regression và native E2E** | Chạy audits/test cần cho Quốc Chiến và E2E browser → gateway → C++ thật. Kiểm trọn ván bot/hai người, hidden/reveal, card/skill/request, GameOver, reconnect; observer/privacy khi được bật. | Kết quả gắn đúng snapshot; không lỗi chặn Quốc Chiến, sai luật hoặc rò dữ liệu. START PASS/typecheck không thay thế gameplay. |
| **U7 — Candidate và nghiệm thu điện thoại** | Sau U0–U6, triển khai native + web lên candidate riêng; kiểm identity public, chơi bot/hai người, reconnect và thao tác trên điện thoại thật. | Biên bản PASS/FAIL theo build/scenario/device; candidate được nghiệm thu cho Quốc Chiến. Không thay production alias/dịch vụ. |
| **U8 — Sẵn sàng phát hành và rollback** | Backup và restore thử, diễn tập rollback native+web cùng identity, kiểm điều kiện vận hành/giám sát/quota cần cho Quốc Chiến; chuẩn bị cutover. | Release/rollback checklist và bằng chứng restore hoàn chỉnh. Chỉ cutover production khi có chỉ thị phát hành riêng; không tự nâng hoặc restart. |

Các bước có phụ thuộc phải làm lần lượt. Nếu phát hiện vấn đề cần đổi snapshot, cập nhật U1/U2, chạy lại phần nghiệm thu bị ảnh hưởng và ghi evidence; không tự mở rộng sang feature/mode khác.

## Quy ước giao việc chung

Mỗi prompt dưới đây giao **một giai đoạn**. Đọc `AGENTS.md`, `docs/CODEX_STATE.md`, `docs/CODEX_PLAN.md` và kế hoạch này; xác minh đầu vào bước trước. Hoàn thành trong phạm vi được giao, chạy kiểm phù hợp, báo cáo file thay đổi/PASS–FAIL/giới hạn/blocker và bước kế tiếp. Bảo toàn thay đổi chưa commit, cập nhật state/plan và chạy `npm run codex:checkpoint` sau mốc thực hiện. Không tự commit/push hoặc phát hành production. U7 chỉ cho phép candidate cô lập; U8 mặc định chuẩn bị phát hành/rollback. Nếu thiếu đầu vào bắt buộc, xác minh/ghi rõ blocker và tiếp tục phần độc lập, không tự đánh dấu hoàn thành.

## Prompt từng giai đoạn

### U0

> Triển khai U0 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md`: lưu baseline source/pin/native/web/manifest và tạo môi trường thử nghiệm cô lập, bảo toàn mọi thay đổi đang dở. Kiểm khả năng tái tạo/phục hồi baseline, lưu evidence và checkpoint; chưa nâng pin hoặc deploy.

### U1

> Triển khai U1 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md`: phân tích diff Hegemony và graph phụ thuộc Quốc Chiến, gồm core/utility/các repo luật cần thiết. Bàn giao ma trận tác động và test cần chạy, dùng full SHA, cập nhật evidence/checkpoint; chưa áp dụng pin hoặc deploy.

### U2

> Triển khai U2 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md`: spike tương thích trong sandbox và chốt bộ SHA Hegemony/core/các repo luật phục vụ Quốc Chiến, ghi rõ giữ/nâng từng repo cùng bằng chứng. Kiểm behavior, API và patch TQS thay vì chỉ khởi động, cập nhật evidence/checkpoint; chưa deploy.

### U3

> Triển khai U3 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md`: áp dụng bộ SHA đã chốt ở U2 trong nhánh thử, đồng bộ native/browser/runtime source/repair/installer/verifier và kiểm thiếu-trùng skill/tướng. Bảo toàn hardening và thay đổi ngoài scope, lưu evidence/checkpoint; chưa deploy.

### U4

> Triển khai U4 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md`: cài/build và kiểm bộ artifact native–web–gateway từ snapshot U3, đồng bộ Lua/media/manifest/flist/registry và hash. Giữ output cách ly, bàn giao artifact cùng evidence/checkpoint; chưa deploy.

### U5

> Triển khai U5 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md`: audit/test thay đổi luật, tướng, bài, skill, pool và thông tin kín của Quốc Chiến đang bật. Nghiệm thu delta so baseline, giữ đúng luật nguồn, bổ sung test cần thiết và báo coverage còn thiếu; lưu evidence/checkpoint, chưa deploy.

### U6

> Triển khai U6 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md`: chạy regression và E2E Quốc Chiến qua native C++ thật trên snapshot đã chốt, kiểm bot/hai người, request/skill, GameOver và reconnect/privacy. Xử lý lỗi trong scope, báo PASS/FAIL đúng tầng và identity, lưu evidence/checkpoint; chưa deploy.

### U7

> Triển khai U7 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md` khi U0–U6 đạt: đưa native và web lên candidate cô lập, kiểm public identity và nghiệm thu Quốc Chiến bot/hai người/reconnect/điện thoại thật. Ghi rõ phần chưa kiểm trên thiết bị, lưu evidence/checkpoint; không thay production.

### U8

> Triển khai phần chuẩn bị U8 theo `docs/web-client/UPSTREAM_IMPLEMENTATION_SUMMARY.md`: kiểm backup/restore, diễn tập rollback native+web và chốt checklist phát hành/vận hành Quốc Chiến. Bàn giao bằng chứng cùng quyết định sẵn sàng hoặc blocker, cập nhật checkpoint; chưa cutover production nếu chưa có chỉ thị riêng.

## Tài liệu liên quan và trạng thái

- Chi tiết kỹ thuật: [UPSTREAM_RELEASE_2026-10-17_PLAN.md](UPSTREAM_RELEASE_2026-10-17_PLAN.md).
- Dữ liệu khảo sát: [UPSTREAM_SURVEY_2026-10-19.md](UPSTREAM_SURVEY_2026-10-19.md). Báo cáo START/contract trước đó không đóng gate effect/native/device của snapshot mới.
- Bản tổng kết này là điểm bắt đầu giao U0–U8 sau khi chốt phạm vi. Những diễn giải rộng hơn trong lịch sử không mở rộng mục tiêu Quốc Chiến.
- Trạng thái khi viết: **chưa triển khai U0–U8**, chưa đổi pin hoặc phát hành trong nhiệm vụ tổng kết kế hoạch.
