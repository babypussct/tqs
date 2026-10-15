# CP08 — Render → Oracle replacement và nghiệm thu mobile

> Cập nhật 16/10/2026. Đây là runbook ngắn cho tuyến candidate hiện hành; không
> phải cam kết official/SLA.

## Tuyến hiện hành

| Thành phần | Giá trị |
| --- | --- |
| Web/gateway | `https://tqs-mobile-candidate.onrender.com` |
| Render deployment | [`dep-db8hu43ncjis73b3u1r0`](https://dashboard.render.com/web/srv-db63aclckfvc73bvrli0/deploys/dep-db8hu43ncjis73b3u1r0), commit `cc5d4ea6` |
| Native replacement | `161.33.209.212:9527`, VM `freekill-hegemony-qa` |
| Cấu hình bền vững | `render.yaml` và service env cùng ghim `FK_HOST` vào replacement; `FK_PORT=9527` |
| Vai trò | Render phục vụ React/gateway; Oracle chạy FreeKill C++/Lua và state server |

## Release identity đã xác minh

- Health public: `200 / ok`.
- Gateway manifest: 14 package, 5.279 file, bundle hash
  `0b4c3d1ea4f5eae7`, runtime MD5
  `fc7357dd585b614312a6894eb16552be`.
- Public HTML SHA-256: `fa42af15…`; JS
  `index-DXmKDLu9.js`; CSS `index-7DaeryPw.css`.
- Oracle: Lua 5.4.8, service enabled/active, port 9527; current QA revision
  `8b7b6938…`, package SHA `006e541b…`, catalog SHA `5ad80f76…`; identity đã
  được verify trên VM.

## Acceptance đã PASS

- Login/lobby thật qua Chrome + Wasmoon + Render gateway + Oracle C++.
- Hidden Gongqing chủ tướng: fake trigger trước damage gate; hai nhánh tầm
  thấp/tầm cao gây lần lượt 1/2 damage; mở Phan Tuấn đúng slot.
  Evidence: [`cp08-hidden-gongqing-multiplayer-live-1792085727624.json`](../../../scratch/evidence/cp08-hidden-gongqing-multiplayer-live-1792085727624.json).
- Hidden Gongqing phó tướng: cùng hợp đồng và mở đúng slot phó.
  Evidence: [`cp08-hidden-gongqing-deputy-multiplayer-live-1792085744289.json`](../../../scratch/evidence/cp08-hidden-gongqing-deputy-multiplayer-live-1792085744289.json).
- Hidden Yiji chủ tướng: Quách Gia còn úp → prelight Di Kế → nhận damage →
  invoke → mở đúng chủ tướng → chuyển 2 lá. Evidence: [`cp08-hidden-yiji-multiplayer-live-1792088748424.json`](../../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792088748424.json).
- Hidden Yiji phó tướng: cùng hợp đồng và mở đúng phó tướng. Evidence: [`cp08-hidden-yiji-deputy-multiplayer-live-1792088763447.json`](../../../scratch/evidence/cp08-hidden-yiji-deputy-multiplayer-live-1792088763447.json).
- Hidden Jueqing chủ tướng: tướng còn ẩn + prelight → `PreDamage` → mở Trương Xuân Hoa ở chủ tướng → mất đúng 1 HP và chặn `DamageEvent`. Evidence: [`cp08-hidden-jueqing-multiplayer-live-1792090046211.json`](../../../scratch/evidence/cp08-hidden-jueqing-multiplayer-live-1792090046211.json).
- Hidden Jueqing phó tướng: cùng hợp đồng và mở đúng phó tướng. Evidence: [`cp08-hidden-jueqing-deputy-multiplayer-live-1792090065108.json`](../../../scratch/evidence/cp08-hidden-jueqing-deputy-multiplayer-live-1792090065108.json).

Kết luận hiện hành: **Render → Oracle replacement parity đã PASS bounded** cho
identity, login, hidden Gongqing, hidden Yiji và hidden Jueqing ở cả main/deputy. Đây chưa
phải full rule parity; ma trận effect, native interaction còn lại,
cold-start/rollback/SLA và official sign-off vẫn OPEN. Corpus 51 run trước đó
thuộc identity cũ và không được gộp vào bằng chứng current identity.

## Quy tắc vận hành

- Mọi deployment mới phải giữ một identity duy nhất giữa `runtime/flist.txt`,
  `RELEASE.json`, gateway manifest và public web artifact; sau deploy chạy
  health, manifest, artifact hash và login probe.
- Không dùng VM cũ `168.110.36.224` cho release mới; VM đó chỉ là
  rollback/reference.
- QA allowlist và credential chỉ nằm ngoài repository; tài liệu chỉ ghi count,
  hash hoặc revision không nhạy cảm.
- Render Free có cold-start và không phải SLA 24/7; không tự chuyển gói trả phí
  hoặc mua domain khi chưa có yêu cầu riêng.

## Mobile smoke test

Mở URL Render trên iPhone Safari và ghi model/iOS, Wi-Fi/4G. Kiểm màn hình
dọc/ngang, bàn phím login, tạo/vào phòng, chọn tướng, bài/mục tiêu/OK/Cancel,
log cuộn, vùng tai thỏ/Home và nút Về sảnh. Mất mạng thật chỉ thử trong phiên
riêng; ghi thời gian reconnect và không đổi tài khoản/IP để vượt temp-ban.
Kết quả thiết bị thật là evidence riêng, không nâng bounded server parity thành
official release.
