# TQSVN — Sự cố nhiều tài khoản bị khóa IP tạm thời (23/10/2026)

Kế hoạch triển khai chi tiết, ticket, QA và cutover: [TQSVN_ACCOUNT_TEMPBAN_IMPLEMENTATION_PLAN_2026-10-23.md](TQSVN_ACCOUNT_TEMPBAN_IMPLEMENTATION_PLAN_2026-10-23.md). Tài liệu này là evidence sự cố, chưa phải chứng nhận đã sửa production.

## Kết luận chẩn đoán (kiểm tra trực tiếp 23/10/2026, giờ Việt Nam)

- `https://tqsvn.pages.dev/` và `/gateway/healthz`, `/gateway/manifest.json`, `/__/auth/handler` đều trả `HTTP 200` từ máy kiểm tra. Không có bằng chứng Cloudflare chặn toàn bộ HTTP tới Pages tại thời điểm thử; phép thử này không chứng minh mọi mạng/IP khác đều vào được.
- Oracle production: `freekill-native.service`, `tqs-gateway.service`, `tqs-quick-tunnel.service` đều `active`; cấu hình thực tế của native có `tempBanTime=5`, `tqsAuthRequired=true`, `maxPlayersPerDevice=2`. Native log có 4 sự kiện `Temp banned` ngày 23/10 UTC và 13 lần trả `temporarily banned` sau đó (từ 02:56:02 tới 03:42:29 UTC, tức khoảng 09:56–10:42 VN). Đây là số sự kiện, không phải 13 người khác nhau. Toàn file log (từ 18/10) có 117 sự kiện `Temp banned`; con số lịch sử không đại diện mức ảnh hưởng hiện tại.
- CSDL native có **14 bản ghi userinfo mang `lastLoginIp` loopback**, 4 bản ghi IP khác và `banip` (khóa vĩnh viễn) **0 bản ghi** ở thời điểm kiểm tra. Không ghi tên, ID người chơi hay IP công khai vào báo cáo.
- Đường đi `Pages Function → Quick Tunnel → Oracle gateway Node → TCP native 127.0.0.1:9527` khiến native nhận địa chỉ loopback cho nhiều tài khoản. Mã native (`server.cpp`: `temp_banlist` theo `peerAddress`; `user_manager.cpp` / bản vá reconnect-safe: kiểm tra ban theo địa chỉ) áp dụng hình phạt rời trận cho IP thay vì tài khoản; do đó **một tài khoản bị temp-ban có thể khiến tài khoản khác dùng chung cổng gateway bị từ chối**. Đây là nguyên nhân có bằng chứng trực tiếp cho hiện tượng khóa nhầm diện rộng ở tầng đăng nhập game.
- Gateway production đang đặt `MAX_WS_PER_IP=6`, `MAX_CONNECTIONS=32`, `TRUSTED_PROXIES=127.0.0.1`; Pages Function xóa `CF-Connecting-IP` và `X-Forwarded-For` trước khi gọi upstream. Cần đo `clientIp()` theo các kết nối thực tế để xác minh thêm nguy cơ nhiều người bị tính chung quota WebSocket. **Chưa có bằng chứng quan sát thực tế rằng quota 6 đã bị vượt.**

## Phạm vi và xử lý tiếp theo

1. **Ưu tiên P0:** thay khóa tạm theo IP bằng khóa theo account/session đã xác thực ở native; bảo toàn cơ chế chống bỏ trận và cho phép reconnect tài khoản còn trong phòng. Đường đi qua proxy không được lấy loopback làm danh tính người dùng. Không lấy header IP do client tự truyền làm định danh an toàn.
2. **Biện pháp khẩn cấp cần quyết định phát hành:** tạm giảm `tempBanTime` của riêng native production về `0` nếu người chơi đang bị khóa nhầm, sau đó triển khai chính sách theo account. Thay đổi config hiện hành yêu cầu restart native; restart có thể ngắt trận đang chơi và phải được sắp xếp có kiểm soát cùng rollback. Không áp dụng tùy tiện cho phần QA hoặc mở rộng quyền truy cập.
3. **Gateway:** xác định chính xác đầu vào `clientIp()` tại kết nối Cloudflare Quick Tunnel; nếu không có IP client đáng tin cậy, tính toán lại chính sách quota theo account sau xác thực hoặc sử dụng metadata được xác thực riêng. Giữ giới hạn tổng kết nối và giới hạn lưu lượng mỗi phiên.
4. **Nghiệm thu:** kiểm thử hai tài khoản thật khác nhau qua cùng gateway; người A bỏ ván trong khi B vẫn có thể login/reconnect; A chịu xử lý đúng chính sách; bao gồm 6+ WebSocket độc lập, client di động mất mạng, reconnect, GameOver, tài khoản hết hạn và thử giả mạo header chuyển tiếp. Ghi số sự kiện và trạng thái, không ghi token, ID account, nội dung bài/tướng kín.

## Tình trạng sau khảo sát

Chỉ kiểm tra HTTP, source, service và số liệu log/CSDL ở chế độ đọc. **Chưa thay production config, restart service, chỉnh Cloudflare, deploy, commit hoặc push.** Trạng thái `active` và HTTP `200` không chứng minh đã xử lý tình trạng từ chối đăng nhập.
