# Hướng dẫn phiên Codex trong repository TQS

## Tiếp tục công việc sau khi hết context

1. Xác nhận thư mục Git đang làm việc; chạy `git status --short` và `git log -1 --oneline`.
2. Đọc `docs/CODEX_STATE.md` (bàn giao gần nhất), `docs/CODEX_PLAN.md` (việc và điều kiện nghiệm thu). Có thể chạy `npm run codex:resume` để xem cả hai kèm trạng thái Git mới nhất.
3. Đối chiếu tài liệu với source và các test liên quan trước khi tiếp tục. Mục "Ảnh chụp Git" được sinh tại thời điểm checkpoint, có thể cũ; trạng thái checkout hiện tại và kết quả test mới nhất có ưu tiên cao hơn.
4. Tiếp tục **bước kế tiếp chưa hoàn thành** ở `CODEX_STATE.md`; chỉ đọc phần liên quan của `docs/web-client/MOBILE_PLAYABLE_MASTER_PLAN.md` khi cần. Không tải/đọc lại toàn bộ dự án chỉ để khởi động phiên.

## Lưu checkpoint khi thực hiện nhiệm vụ

- Sau mỗi mốc triển khai đáng kể, trước khi chuyển phiên hoặc khi ngữ cảnh sắp đầy: cập nhật thủ công phần bàn giao trong `docs/CODEX_STATE.md` và trạng thái ticket ở `docs/CODEX_PLAN.md`, sau đó chạy `npm run codex:checkpoint`.
- Ghi mục tiêu, những gì **đã làm**, đường dẫn file quan trọng, bằng chứng kiểm thử thật (lệnh, PASS/FAIL và giới hạn), blocker và **bước tiếp theo có thể chạy ngay**. Chỉ ghi "đã xác minh" nếu phiên đã quan sát kết quả; thông tin từ báo cáo cũ phải có nhãn "báo cáo trước".
- Công cụ checkpoint chỉ tự chụp tên file thay đổi, nhánh, commit và thời điểm; nó không tự biết mã chạy đúng hay ticket đã xong. Đừng sửa phần nằm giữa marker sinh tự động.
- Bảo toàn toàn bộ thay đổi chưa commit do người dùng hay phiên trước tạo; tuyệt đối không tự ý `reset`, `clean`, `checkout` ghi đè hoặc commit các file đó. Không ghi token, mật khẩu, nội dung `.env`, hoặc dữ liệu nhạy cảm vào tài liệu.
- TQSShop (`src/`, `api/`) và FreeKill web game (`game/`) là hai phạm vi riêng; không đụng tới production/deploy khi nhiệm vụ chỉ liên quan client hoặc checkpoint.

## Lệnh nhanh

```bash
npm run codex:resume       # Đọc bàn giao + kế hoạch + trạng thái Git trực tiếp
npm run codex:checkpoint   # Cập nhật ảnh chụp Git trong CODEX_STATE.md
```

Các bài test web game nằm trong `game/web/package.json`; chạy bộ test liên quan trước khi đánh dấu hoàn thành. Tài liệu kế hoạch tổng thể cho game ở `docs/web-client/MOBILE_PLAYABLE_MASTER_PLAN.md`.
