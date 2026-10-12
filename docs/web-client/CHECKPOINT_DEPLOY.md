# Bản web chơi thử và checkpoint

Bản chơi thử chạy build Vite đã đóng băng, proxy `/gateway` tới gateway local đang kết nối FreeKill thật `168.110.36.224:9527`. Cloudflare Quick Tunnel cấp URL HTTPS/WSS để mở trên điện thoại. Đây là deployment thử phụ thuộc máy Mac, gateway và tunnel đang chạy; chưa phải hosting 24/7 hoặc nghiệm thu G7. URL đổi khi tạo tunnel mới.

## Tạo bản có thể khôi phục

Chạy build và các test phù hợp trong `game/web/`, cập nhật `CODEX_STATE.md`/`CODEX_PLAN.md`, chạy `npm run codex:checkpoint` tại Git root. Sau đó:

```sh
node scripts/game-checkpoint.mjs /absolute/path/to/pinned-snapshot web-2026-10-11-cp01
```

Script ghi `scratch/releases/<id>/` và `<id>.tar.gz`, SHA-256 bên cạnh archive. Archive gồm source web/gateway/tài liệu hiện tại (kể cả file mới chưa commit), dist đã build và snapshot Lua/flist; không commit thay đổi vào Git, không kèm node_modules hoặc credentials. `checkpoint.json` ghi commit nền, hash source, MD5 runtime. Source TQSShop không thuộc bản này.

## Chạy bản đóng băng

Tại `game/web/` của checkout đã cài dependency:

```sh
node scripts/serve-checkpoint.mjs /absolute/path/to/checkpoint/dist
cloudflared tunnel --url http://127.0.0.1:5180 --no-autoupdate
```

Server chỉ bind `127.0.0.1:5180`, phục vụ dist từ checkpoint và proxy HTTP/WebSocket tới gateway `127.0.0.1:8080`; không phục vụ repository/source. Giữ gateway và snapshot đang dùng ổn định trong ván. Sửa/rebuild source trong `game/web/` không thay đổi checkpoint này. Không restart tunnel/gateway hoặc đổi checkpoint giữa ván.

## Khôi phục và rollback

Kiểm tra `shasum -a 256 -c <archive>.sha256` trong thư mục archive trước khi giải nén sang thư mục riêng. Source nằm trong `source/`, build trong `dist/`, packages/flist trong `runtime/`. Không giải nén đè checkout hiện tại.

Nếu cần dựng lại từ source, chạy `npm ci` riêng tại `source/game/web/` và `source/game/gateway/`, sau đó build/test. Gateway có thể chạy với `FK_ROOT=/absolute/checkpoint/runtime FK_HOST=168.110.36.224 FK_PORT=9527 PORT=8080 npm start` tại `source/game/gateway/`; snapshot phải còn khớp package revision của server. Credentials nhập tại browser hoặc dùng cấu hình test private ngoài archive.

Rollback sau khi kết thúc toàn bộ ván: dừng riêng preview checkpoint, chạy lại `serve-checkpoint.mjs` với `dist` của checkpoint trước tại cùng port 5180. Giữ gateway/tunnel nếu không cần đổi. Nếu Mac/tunnel dừng, URL không còn truy cập được. Hosting 24/7 cần SSH hợp lệ vào VM hoặc một host hỗ trợ gateway TCP lâu dài; không reset/restart FreeKill để deploy web.

## Deployment CP06 · 11/10/2026

URL hiện hành: **https://pvc-gotta-soundtrack-buses.trycloudflare.com/**. Phục vụ build mới tại `scratch/deployments/web-2026-10-11-cp06/release-dist`; thông tin process và logs ở `processes.json` trong cùng thư mục. Origin 5180 proxy gateway 8080, runtime pin cp05 giữ MD5 được server nhận. URL cũ của CP01 không còn được process phiên này phục vụ.

Đã kiểm chính bản HTTPS/WSS bằng `TQS_LIVE_URL`, hoàn tất ván FreeKill C++/GameOver/panel thắng/Về sảnh/ngắt sạch; 5 dist files tải HTTPS khớp SHA-256. Báo cáo kết quả và giới hạn tại `CHECKPOINT_CP06_REPORT.md`; UI-01 vẫn có ba log tên kỹ năng chưa dịch trong ván cuối. Mac/preview/gateway/tunnel phải tiếp tục chạy, chưa đạt hosting 24/7/G7.

Archive bàn giao dùng ID `web-2026-10-11-cp06`. Rollback sau khi hết ván bằng dist của cp05 hoặc cp01 tại port 5180; giữ gateway/tunnel nếu runtime không cần đổi. Không dừng gateway hoặc đổi origin trong ván.
