# CP08 — Render → Oracle replacement và nghiệm thu mobile

> Cập nhật 16/10/2026. Đây là runbook ngắn cho tuyến candidate hiện hành; không
> phải cam kết official/SLA.

## Tuyến hiện hành

| Thành phần | Giá trị |
| --- | --- |
| Web/gateway | `https://tqs-mobile-candidate.onrender.com` |
| Render deployment | [`dep-db8iptu7bikc73e8p100`](https://dashboard.render.com/web/srv-db63aclckfvc73bvrli0/deploys/dep-db8iptu7bikc73e8p100), commit `93b9f652` |
| Native replacement | `161.33.209.212:9527`, VM `freekill-hegemony-qa` |
| Cấu hình bền vững | `render.yaml` và service env cùng ghim `FK_HOST` vào replacement; `FK_PORT=9527` |
| Vai trò | Render phục vụ React/gateway; Oracle chạy FreeKill C++/Lua và state server |

## Release identity đã xác minh

- Health public: `200 / ok`.
- Gateway manifest: 14 package, 5.279 file, bundle hash
  `0b4c3d1ea4f5eae7`, runtime MD5
  `ae598a4c946040df3a458ddeb4771999`.
- Public HTML SHA-256: `fa42af15…`; JS
  `index-DXmKDLu9.js`; CSS `index-7DaeryPw.css`.
- Public release snapshot: 16.522 file, 14 package; `dist/index.html` SHA-256
  `fa42af15a4591bc5cf252d1834c9175c2d629a8a6c0328447e2518a3ed21f68b`.
- Oracle: Lua 5.4.8, service enabled/active, port 9527; current QA revision
  `f80d346e…`, package SHA `7145a646…`, catalog SHA `ac0be89d…`; identity đã
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
- Hidden Ân Oán chủ tướng: prelight trước `TargetConfirmed`, request Peach riêng tới actor đang úp, mở Pháp Chính và rút đúng 1 lá. Evidence: [`cp08-hidden-enyuan-multiplayer-live-1792093571889.json`](../../../scratch/evidence/cp08-hidden-enyuan-multiplayer-live-1792093571889.json).
- Hidden Ân Oán phó tướng: cùng hợp đồng và mở đúng slot phó. Evidence: [`cp08-hidden-enyuan-deputy-multiplayer-live-1792093587237.json`](../../../scratch/evidence/cp08-hidden-enyuan-deputy-multiplayer-live-1792093587237.json).
- Hidden Jueqing chủ tướng: tướng còn ẩn + prelight → `PreDamage` → mở Trương Xuân Hoa ở chủ tướng → mất đúng 1 HP và chặn `DamageEvent`. Evidence: [`cp08-hidden-jueqing-multiplayer-live-1792090046211.json`](../../../scratch/evidence/cp08-hidden-jueqing-multiplayer-live-1792090046211.json).
- Hidden Jueqing phó tướng: cùng hợp đồng và mở đúng phó tướng. Evidence: [`cp08-hidden-jueqing-deputy-multiplayer-live-1792090065108.json`](../../../scratch/evidence/cp08-hidden-jueqing-deputy-multiplayer-live-1792090065108.json).
- Hidden Jianxiong chủ tướng: tướng còn ẩn + prelight → `Damaged` → mở Tào Tháo ở chủ tướng → chọn/nhận 1 lá sát thương. Evidence: [`cp08-hidden-jianxiong-multiplayer-live-1792090284132.json`](../../../scratch/evidence/cp08-hidden-jianxiong-multiplayer-live-1792090284132.json).
- Hidden Jianxiong phó tướng: cùng hợp đồng và mở đúng phó tướng. Evidence: [`cp08-hidden-jianxiong-deputy-multiplayer-live-1792090299019.json`](../../../scratch/evidence/cp08-hidden-jianxiong-deputy-multiplayer-live-1792090299019.json).
- Hidden Phản Gián chủ/phó: ActiveSkill `PlayCard` mở đúng Chu Du, tặng Đào và mục tiêu chọn mất 1 HP. Evidence: [`1792090932936`](../../../scratch/evidence/cp08-hidden-fanjian-multiplayer-live-1792090932936.json) / [`1792090944332`](../../../scratch/evidence/cp08-hidden-fanjian-deputy-multiplayer-live-1792090944332.json).
- Hidden Lạc Thần chủ/phó: `EventPhaseStart` phán xét thật, mở đúng slot và lấy lá đen. Evidence: [`1792091111699`](../../../scratch/evidence/cp08-hidden-luoshen-multiplayer-live-1792091111699.json) / [`1792091126085`](../../../scratch/evidence/cp08-hidden-luoshen-deputy-multiplayer-live-1792091126085.json).
- Hidden Đoạn Trường chủ/phó: `fk.Death` thật, mở đúng slot, chọn chủ tướng killer và gỡ đúng kỹ năng chủ. Evidence: [`1792091142647`](../../../scratch/evidence/cp08-hidden-duanchang-multiplayer-live-1792091142647.json) / [`1792091155661`](../../../scratch/evidence/cp08-hidden-duanchang-deputy-multiplayer-live-1792091155661.json).
- Hidden ActiveSkill/ViewAs: Chế Hành và Long Đảm đều đi qua native `PlayCard`, mở đúng chủ/phó và giữ privacy owner. Evidence: [`1792091265053`](../../../scratch/evidence/cp08-hidden-active-multiplayer-live-1792091265053.json), [`1792091276756`](../../../scratch/evidence/cp08-hidden-active-main-multiplayer-live-1792091276756.json), [`1792091289038`](../../../scratch/evidence/cp08-hidden-view-as-multiplayer-live-1792091289038.json), [`1792091300559`](../../../scratch/evidence/cp08-hidden-view-as-main-multiplayer-live-1792091300559.json).
- Hidden dual/reveal: Song Hùng tự bỏ nguồn màu rồi chuyển Sát → Quyết Đấu; `reveal_skill&` mở đúng Lục Tốn chủ/phó. Evidence: [`1792091320794`](../../../scratch/evidence/cp08-hidden-dual-multiplayer-live-1792091320794.json), [`1792091332078`](../../../scratch/evidence/cp08-hidden-reveal-multiplayer-live-1792091332078.json), [`1792091343440`](../../../scratch/evidence/cp08-hidden-reveal-deputy-multiplayer-live-1792091343440.json).
- Batch current hosted bổ sung 32 slot/nhánh hidden-trigger (Phản Quỹ, Thiên Đố, Liệt Cung, Cuồng Cốt, Danh Sĩ, Cơ Trí, Tuần Tầm, Không Thành, Vi Mộ, Tôn Thượng Hương/Xiaoji, Guanxing, Anh Tư, Thiên Hương, Phản Gián) đều PASS ở cả chủ/phó; index evidence duy nhất ở [`QUOC_CHIEN_RULE_AUDIT.md`](../QUOC_CHIEN_RULE_AUDIT.md).

Kết luận hiện hành: **Render → Oracle replacement parity đã PASS bounded** cho
identity, login, hidden Gongqing, hidden Yiji/Di Kế, hidden Ân Oán, hidden Jueqing, hidden Jianxiong, hidden Phản Gián, Lạc Thần, Đoạn Trường, ActiveSkill/ViewAs main/deputy, dual, reveal và batch 32 slot/nhánh hidden-trigger ở các slot đã nêu. Đây chưa
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
