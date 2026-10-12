# CP12 Render: triển khai, kiểm chứng và khôi phục

Ngày 12/10/2026. Candidate công khai: https://tqs-mobile-candidate.onrender.com. Service `srv-db63aclckfvc73bvrli0`, Free/Docker/Singapore. Auto Deploy Off. Backend FreeKill và ba revision Lua giữ nguyên. Root checkout không commit; branch `codex/mobile-candidate-cp11` chứa generated deployment snapshot, tên branch được giữ để service tiếp tục dùng cùng nguồn.

CP11 deployment `dep-db63addckfvc73bvrnp0`, commit `b98b8bde7b62cb558d89c30d0d0b62437be95da0`: Live, HTTPS sáu dist hashes/health/MD5/foreign Origin403 PASS. Hai ván URL Render thật PASS; ván thứ hai thực hiện card/target/OK/native reply, controlled transport loss, native Reconnect rồi hai GameOver/result/lobby/disconnect, zero errors. Không coi transport close điều khiển là mất mạng vật lý. Evidence ở `scratch/evidence/cp11-render-verification-manifest.json`.

Người dùng báo cáo iPhone17 Pro Max/5G: BOT chơi hộ hoàn tất, màn hình kết quả/Về sảnh/Ngắt kết nối hoạt động, đã về login. iOS chưa cung cấp. Ngang trong nội dung ổn, sát mép phải kích hoạt thanh Safari. CP12 mở rộng scroll surface hết viewport với safe-area/content padding. Chrome geometry bốn kích thước PASS; Safari gesture cần re-test. Không vô hiệu hóa mọi touchmove hoặc hứa điều khiển thanh Safari.

CP12 final artifact `scratch/deployments/cp12-render/release`: 1043 files verify PASS. Commit `082f3fe18550774f28221b2b2b4db80aeb0f908f`; deployment `dep-db63lkjbc2fs73amhgn0`, Live29.4s. Docker base pin `node:22-alpine@sha256:0a7108bf6c7bf5de370ffb1a3ed6be93d405b43ff159f681a8d18c0e2bc2e402`, digest quan sát từ CP11 Render build và CP12 Docker build thành công. CP12 HTTPS sáu hashes/health PASS. Layout source archive đã khôi phục 102 source hashes, runtime/dist; build riêng cho sáu dist hashes khớp. Các chứng cứ có scope/time riêng, không cập nhật JSON lịch sử để làm nó thành PASS mới.

## Quy trình vận hành

1. Chỉ deploy/restart/rollback khi người chơi đã kết thúc ván. Gateway hiện chưa có drain API. Trong kiểm thử 12/10, người dùng đã xác nhận về login trước thao tác.
2. Verify release bằng `node deploy/mobile/verify-release.mjs /absolute/release`. Dùng exact SHA trong Manual Deploy → Deploy a specific commit. Chờ dashboard Live và đối chiếu SHA, không coi bấm Deploy là thành công.
3. So SHA-256 index/assets/wasm/manifest qua HTTPS, MD5 `/gateway/manifest.json`, `/gateway/healthz`, Origin khác bị từ chối. Healthz chỉ là HTTP process liveness, không chứng minh backend đăng nhập hoặc gameplay.
4. Rollback qua Deploys → bản đã xác minh → Rollback; kiểm source SHA/Live/hashes thực tế. Sau đó quay lại CP12 bằng exact SHA hoặc rollback deployment CP12. Kiểm login/ván sau khôi phục. Mỗi thao tác cần timestamp/deployID/hash evidence. Kết quả thực tế được ghi ở CODEX_STATE khi quan sát.
5. Chờ không có HTTP/WebSocket activity đủ thời gian để đo Free cold-start; không ping keepalive nhằm che idle behavior. Runner remote health bounded120s, local10s, timeout riêng từng fetch. Không gọi một lần chậm là cold-start nếu chưa chứng minh khoảng idle.

Với native FreeKill, chạy `deploy/freekill-native/scripts/verify-backup.sh`
trên archive trước mọi restore rehearsal; chỉ giải nén vào thư mục test mới,
kiểm tra `verify-install.sh` và service ở đó, rồi mới lập kế hoạch cutover.
Verifier chỉ bảo vệ tính toàn vẹn cơ bản của archive và quyền truy cập; chưa
được coi là bằng chứng rollback host thật hay drain người chơi.

## Quota và giới hạn

Gateway exact canonical HTTPS Origin, không tin XFF tùy ý. MAX_CONNECTIONS=128 và MAX_WS_PER_IP=128 là admission caps; Render proxy có thể gom client IP nên không diễn giải cap per-IP là 128 cho mỗi người. Local test thực tế global3/4th503 và traffic burst200 đóng sender, peer khác vẫn mở PASS. Chưa benchmark128 phiên production. Render metrics quan sát tháng8MB outbound; Free giới hạn512MB/0.15CPU, số CPU/memory thực tế cần paid UI để xem. Không tự nâng gói, không giả định metrics không hiện là usage0.

Free idle/cold-start/giới hạn giờ tháng không phải cam kết uptime production. Tài liệu nhà cung cấp: https://render.com/docs/free và https://render.com/docs/websocket. Chỉ dùng domain onrender đã cấp; chưa có domain riêng hoặc chi phí được cấu hình.

## Đánh giá advisory node-forge

Audit mới `scratch/evidence/cp12-web-audit.json`: **1 high**, GHSA-86w9-cpqp-85rv, chưa có fixAvailable. Advisory chính thức https://github.com/advisories/GHSA-86w9-cpqp-85rv mô tả RSA PKCS#1 v1.5 **signature verification** chấp nhận DigestAlgorithm nested sai; patched versions None tại thời điểm kiểm.

Rà toàn bộ `game/web/src`: chỉ một import forge tại `engine/connection.ts`. `sendSetup` dùng random bytes, bytesToHex/encodeUtf8, PEM publicKeyFromPem, rồi RSAES-PKCS1-V1_5 **encrypt**; không có verify/signature verification callsite. Đây là căn cứ kết luận đường khai thác mô tả trong advisory chưa được gọi bởi client hiện tại; không chứng minh toàn thư viện an toàn, không xóa audit hoặc đổi thuật toán server. Giữ cảnh báo visible; đánh giá lại nếu thêm signature/certificate verification hoặc thay dependency. Việc chốt release phải ghi rõ residual dependency risk cùng phạm vi này.

Official release còn mở: Safari CP12/device manual controls, mất mạng vật lý, cold-start/restart/rollback evidence đầy đủ và coverage luật liên quan trong master plan. Không tự chuyển mọi gate thành PASS do Render Live.
