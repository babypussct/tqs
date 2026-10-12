# Báo cáo checkpoint CP06 · 11/10/2026

Checkpoint mới đã hoàn tất kiểm chứng build và deployment thử qua HTTPS/WSS. Bản đang phục vụ gồm các thay đổi web client tích lũy từ các checkpoint trước: cấu hình bể tướng/bài, Self và trạng thái bàn, dialog chọn bài, hỗ trợ cứu Đào theo Lua, nhật ký/diễn biến và Việt hóa. Deploy chung không tự nâng mức nghiệm thu của từng ticket.

URL: **https://pvc-gotta-soundtrack-buses.trycloudflare.com/**.

## Bằng chứng mới

- Audit bốn JSON gốc: **468 mẫu/0 chuỗi bị bộ dò đánh dấu sau xử lý lại**, kiểm riêng hai câu hủy mục tiêu. Input giữ nguyên và có SHA-256; đây là audit text lịch sử.
- Sửa tên/mô tả **Cự Cổ**, **Tư Viện** của Mi Trúc bản offline theo Lua pin. Regression kiểm tên dịch trong Lua và dòng log tại DOM. Chỉ thay hiển thị.
- Bổ sung favicon SVG sau khi Chrome báo `/favicon.ico` 404. Giữ assertion console errors để kiểm bản deploy thật.
- Thêm `TQS_LIVE_URL` cho runner: mở build công khai và `/gateway` trên cùng deployment, không khởi tạo Vite/gateway riêng. Thêm kiểm nhật ký/diễn biến và tràn ngang.
- **Ván cuối: PASS exit 0.** Chrome 390×844 → HTTPS/WSS → Wasmoon/Lua → Gateway → FreeKill C++ thật; server Setup/EnterLobby/GameOver, panel **Bạn đã thắng!**, về sảnh và ngắt sạch. Không lỗi JS/Lua/console. BOT chơi hộ dùng native Trust.
- Nhật ký/diễn biến live: **63 log entries**, **3 diễn biến**, nhật ký hiển thị và không tràn ngang 390px. Toàn bộ **5 dist files** tải HTTPS có SHA-256 khớp frozen build; health `ok`; **808 Lua/JSON files**, MD5 `a2a4b0af428f971c2642f11bd4aef162` được server nhận.

## Kết quả kiểm thử

| Nhóm | Kết quả đã quan sát |
| --- | --- |
| Chrome + Lua thật, socket fixture | 38/38 PASS; chạy lại sau sửa Mi Trúc |
| Chrome mock | 17/17 PASS |
| Store / connection / gameplay | 26/26, 20/20, 14/14 PASS |
| Protocol / bundle | 4/4, 4/4 PASS |
| Choices / card-selection / cards-and-choice / live-config | Mỗi bộ 2/2 PASS |
| Room pools / gateway | 4 nhóm PASS / 1/1 PASS |
| Smoke / build / strict harness/audit TypeScript | PASS; build/typecheck chạy lại sau favicon |
| HTTPS/WSS → FreeKill C++ thật | Ván cuối PASS exit 0, GameOver/về sảnh/ngắt sạch |

Ván sau sửa Mi Trúc trước favicon có 82 mẫu/0 nghi vấn, nhưng runner **FAIL exit 1** do 404; không dùng lượt này làm PASS toàn bộ deployment. Ván cuối có **77 mẫu/3 log còn tên kỹ năng chưa dịch**: `祸水` của Trâu Thị và `礼下` của Sĩ Nhiếp. Bộ dò dịch không phải điều kiện PASS của bài kết nối/game lifecycle; UI-01 tiếp tục mở.

## Trạng thái nghiệm thu

| Phạm vi | Trạng thái |
| --- | --- |
| Build, login, Lua bridge, phòng/bot | Có bằng chứng local và FreeKill live |
| Card/target/skill, một ván bot hoàn chỉnh | Có bằng chứng live; chưa đủ mọi dialog/luật |
| UI-02 cấu hình bể | Live PASS ở phiên trước; tích hợp trong build deploy mới |
| UI-03 nhật ký/diễn biến | Fixture PASS; bổ sung live 390px ở CP06 |
| UI-01 Việt hóa | Còn hai tên kỹ năng mới và coverage ngữ nghĩa chưa đủ |
| GAME-03A/03C | Còn nghiệm thu live dialog/cứu Đào/Quyết chiến |
| GAME-04 / G6 | Hai người, reconnect, iOS/Android vật lý chưa nghiệm thu |
| G7 | Chưa đạt hosting 24/7, smoke 4G và đầy đủ security/rollback vận hành |

`PLAYABLE_MOBILE=false`. Không đưa ra phần trăm hoàn thành vì các gate còn thiếu cần kiểm chứng thực tế.

## Deployment và khôi phục

Origin loopback 5180 phục vụ `scratch/deployments/web-2026-10-11-cp06/release-dist`; gateway 8080 dùng runtime pin cp05 và kết nối `168.110.36.224:9527`. PID/logs trong `scratch/deployments/web-2026-10-11-cp06/processes.json`. URL Quick Tunnel tạm và phụ thuộc máy Mac/processes đang chạy.

Archive bàn giao: `scratch/releases/web-2026-10-11-cp06.tar.gz`, checksum `.sha256` cạnh archive. **Khôi phục đã PASS:** giải nén tạm riêng, 77 source hashes, 1.025 runtime files/MD5 và 5 dist files khớp; không credentials/node_modules/links/AppleDouble. Báo cáo `scratch/evidence/web-cp06-release/archive-verification.json`. Archive chụp source trước ghi chú xác minh cuối này; ứng dụng/build/runtime đúng bản đang phục vụ. Theo `CHECKPOINT_DEPLOY.md` để kiểm checksum, giải nén riêng và rollback; không giải nén đè checkout hiện hành hoặc thay build giữa ván.

SSH bằng identity mặc định tới VM thực tế vẫn trả `Permission denied(publickey)`. `npm audit --omit=dev` báo **1 high node-forge**, chưa có bản sửa tự động trong kết quả audit. JS bundle **775.36 kB/gzip 231.50 kB** và cảnh báo Wasmoon/module/chunk lớn còn. G7 vẫn mở.

Bằng chứng: `scratch/evidence/web-cp06-release/{ui-01-live-cpp-2026-10-11.json,deployment-assets.json,lobby-after-game.png}`, log `scratch/deployments/web-2026-10-11-cp06/release-verification.log`; ảnh kết quả/sảnh đã inspect. Evidence JSON không lưu auth, frames hoặc bài kín. Tài khoản test đã ngắt sạch.

Bước tiếp theo: đối chiếu Lua pin của `祸水`/`礼下`, bổ sung nhãn/mô tả đúng variant và log, thêm regression, audit JSON live cuối rồi thử ván live mới. Deployment cp06 giữ đóng băng trong lúc phát triển tiếp.
