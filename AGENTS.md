# Hướng dẫn phiên Codex trong repository TQS

## Mục tiêu chính TQSVN — chốt với người dùng 19/10/2026

- Mục tiêu bắt buộc duy nhất của **TQSVN/game** là Quốc Chiến từ `https://gitee.com/qsgs-fans/hegemony`, mode `new_heg_mode`, vận hành được từ đăng nhập/tạo-vào phòng/chọn chủ-phó đến đánh bài, dùng kỹ năng, GameOver và khôi phục kết nối trên web/điện thoại. Luật C++/Lua của snapshot đã chọn là nguồn sự thật; giữ đúng luật và bí mật bài/tướng.
- Chỉ làm core, utility, package phụ, auth/gateway, asset, hạ tầng và kiểm thử khi phục vụ trực tiếp hoặc gián tiếp cho Quốc Chiến vận hành. Giữ pin dependency đang tương thích; chỉ nâng khi có lý do liên quan Quốc Chiến đã được chứng minh. Không mặc định theo HEAD của mọi repo hoặc chứng nhận toàn bộ FreeKill.
- Mode khác, tướng/skill không dùng trong Quốc Chiến, tính năng nền tảng/QML, chat/replay/VFX nâng cao và cập nhật hệ sinh thái không phải mục tiêu hay điều kiện nghiệm thu bắt buộc của TQSVN. Audit ngoài scope chỉ là tham khảo trừ khi phát hiện lỗi nạp registry hoặc tác động chung làm Quốc Chiến hỏng.
- Các backlog ngoài mục tiêu này trong tài liệu cũ là tham khảo/lịch sử và không chặn nghiệm thu Quốc Chiến. TQSShop là ứng dụng riêng trong cùng repo; không mở việc Shop, xóa code/gói đang dùng, hoặc thay production chỉ vì điều chỉnh định hướng TQSVN.

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

## Cách ly build và gate phát hành

- Shop build/clean qua `npm run build` / `npm run clean`, chỉ dùng `dist-shop/`.
  Giữ guard trong `build/` và không đặt output về root `dist/` đang tracked.
  Game build ở `game/web/`, ghi `game/web/dist/`. Chạy build tuần tự để đối chiếu
  hash trước/sau chính xác; không tự đồng bộ/xóa artifact legacy.
- Khi sửa build/output/Vercel, chạy `npm run test:build-safety`,
  `npm run check:build`, build → clean → rebuild shop và kiểm `git diff -- dist`.
  Chạy `npm run typecheck:all` để kiểm cả shop/API/tests, game app và game tools;
  không mở lại phạm vi root TypeScript sang `scratch/` hoặc bản sao của game.
- `vercel build --prod` là build local; chỉ ghi hosted/production PASS khi có
  deployment và smoke tương ứng. Push branch có auto-deploy cũng là phát hành;
  không suy ra quyền push/deploy từ một nhiệm vụ sửa mã hoặc checkpoint.
- Quy trình và mẫu evidence thiết bị thật: `docs/deploy/SHOP_BUILD_RELEASE.md`.
  Không đóng gate thiết bị thật bằng Chrome mô phỏng hoặc bằng nghiệm thu bản cũ.
- Dùng `npm run changes:plan` và `npm run test:pipelines` khi sửa CI hoặc phạm vi
  phát hành. Giữ shared policy/auth/Firebase trong mapping cả hai ứng dụng;
  đường dẫn chưa biết và thiếu lịch sử phải kiểm cả hai, không tự skip.
- CI game cần `npm --prefix game/web run prepare:upstream` trước audit/build.
  Không coi checkout `scratch/upstream` sẵn có là dependency mặc định của CI.
  Giữ SHA pin, không ghi đè checkout upstream dirty hoặc đổi pin để lấy PASS.
- Cloudflare `tqsvn` đang Direct Upload, không tự nối Git hoặc thêm auto-deploy.
  Vercel ignore chỉ quyết định phạm vi build; CI không tự cấp quyền phát hành.

Các bài test web game nằm trong `game/web/package.json`; chạy bộ test liên quan trước khi đánh dấu hoàn thành. Tài liệu kế hoạch tổng thể cho game ở `docs/web-client/MOBILE_PLAYABLE_MASTER_PLAN.md`.

## Bài học vận hành đã ghi nhớ — SMARTAI native QA (20/10/2026)

Các quy tắc dưới đây được rút ra từ lỗi thật trong SMARTAI-FACTION-P1-02. Khi gặp lỗi mới cùng loại, cập nhật mục này và tạo checkpoint; không chỉ ghi trong cuộc trò chuyện.

- Kiểm tra contract của runner/UI trước khi chạy native. `game/web/scripts/multiplayer-e2e/run.ts` từng tìm form username/password cũ trong khi `LoginScreen.tsx` chỉ còn Google OAuth. Nếu cần chạy runner legacy, chỉ dùng bridge/build test-only ngoài production; sau test phải tháo bridge và build lại bundle mặc định. Không quy lỗi UI/auth này cho native server.
- `GameAdapter.createRoom()` gọi refresh Firebase session trước khi tạo phòng. Session giả lập chỉ đủ để đi qua bước `login`; runner test-only phải bypass refresh bằng cờ rõ ràng hoặc dùng auth thật. Nếu không, UI có thể hiện “phiên hết hạn”, native chỉ thấy login rồi disconnect và phòng không được tạo.
- `selectPair()` phải chọn `.general-choice`, không lấy toàn bộ `button` trong nhóm. Nút xem thông tin kỹ năng cũng là `button`, còn popup overlay có thể che nút chọn/reset. Đây là lỗi selector/UI test, không phải lỗi chọn tướng hay luật native.
- Khi native báo MD5 mismatch, không tự đổi `runtime/flist.txt` hoặc pin. Đối chiếu `flist.txt` và package text byte-for-byte giữa client với runtime; dùng client root tạm thời, cách ly, nếu cần. Không ghi đè checkout upstream đang dirty.
- Với catalog QA có `seatRosters`, `GamePrepared` phải cập nhật cả `player.general`/`player.deputyGeneral` và các mark/fake-skill tương ứng. Chỉ thay mark khiến UI vẫn hiện cặp tướng ngẫu nhiên và các event hậu kỳ có thể index sai deputy.
- `fk.GameFinished` là nil-target event; không khóa cleanup/trace bằng `player == room.players[1]`, vì người đang giữ `room.current` lúc GameOver có thể là ghế khác. Dùng room hiện hành và cờ `emitted` để đảm bảo phát một lần.
- Port QA native có thể chỉ bind nội bộ dù production port public. Khi vậy phải chạy gateway cạnh đúng runtime QA và dùng SSH tunnel riêng; không trỏ local gateway vào port QA public giả định, và không sửa firewall/production để làm test chạy được.
- Native A/B phải phân biệt rate theo request với rate theo thời gian. `illegal_reply` được phân loại qua `invalid_details`; `feasibility_rejected` nghĩa là reply đã qua structural validation nhưng handler `feasible()` từ chối, chưa phải semantic root cause cuối. Không suy ra faction regression từ dữ liệu theo thời gian hoặc phép kiểm định trên các request tương quan.
- A/B gameplay chưa ghép seed, cặp tướng và request-state chỉ là exploratory. Muốn đóng gate non-regression phải có deterministic replay/snapshot tương đương và telemetry bounded cho unknown active fallbacks; không chuyển sang tactical optimization khi gate này còn mở.
- QA native dùng room quota và port cô lập. Sau khi probe đã chạy, ghi log/seed/evidence trước khi thử lại; dọn process và tunnel ở cuối; xác nhận port QA đã tắt còn port production vẫn hoạt động. Không để process QA sống hoặc nhầm QA PASS với production/device PASS.
- Log và evidence QA chỉ chứa metadata đã sanitize: không credentials, `.env`, prompt, card ID, target ID, private hand/general data hoặc raw exception.
- Cùng seed chưa đủ để chứng minh cùng AI input: Hegemony rút hand trước khi QA `shuffleTail` áp seed. Bounded `ai-trace` phải cấp `fixedHands` với semantic `trueName+suit+color`, gọi đúng `player.ai:makeReply()` thật (không chỉ dựng `SmartAI:new` fixture), và so sánh fingerprint/shape đã sanitize giữa baseline/candidate.
- `selectPair()` exhaustive search phải reset lựa chọn trước từng cặp `(a,b)`. Nếu chỉ reset khi đổi `a`, một cặp không hợp lệ làm selection cũ còn sót và runner có thể báo giả `No valid native general pair`.
- Scenario native bounded kết thúc bằng `GameOver` không được đi qua nhánh Trust/full-match hoặc chờ nút `Về sảnh`; runner phải coi `GameOver` packet là điều kiện hoàn tất và chỉ đóng browser sau khi evidence đã ghi.
- Native QA restart sau lỗi `RoomThread` không được giả định unit `freekill-asio` theo tên process: binary có thể hiện `comm=MainThread` và chạy dưới `root`. Phải xác thực đúng PID/process owner, dừng process QA root, relaunch `run-server.sh` với auth environment của máy QA (không in giá trị), chờ log `server is ready` và kiểm `9527/9000` trước khi rerun. Nếu không, room/account stale có thể làm lượt control tiếp theo fail ở lobby và tạo evidence nhiễu; cleanup phải xác nhận `tqsQa=false`, package/symlink QA absent.
