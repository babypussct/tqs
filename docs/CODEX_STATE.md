# CODEX_STATE — bàn giao công việc TQS

> Cập nhật handoff: 15/10/2026 20:55 (giờ Việt Nam). Đây là trạng thái hiện hành, không phải nhật ký commit. Chi tiết luật/evidence chỉ giữ ở [`web-client/QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md).

## Mục tiêu và phạm vi

Hoàn thiện client Tam Quốc Sát trên trình duyệt điện thoại bằng React + Wasmoon Lua + gateway, dùng FreeKill C++/Lua làm nguồn sự thật. Scope hiện tại là `new_heg_mode` với 14 package; không port luật server sang TypeScript và không trộn TQSShop.

## Handoff ngắn

- **Render candidate:** [`tqs-mobile-candidate`](https://tqs-mobile-candidate.onrender.com) đang ở identity CP96 UI trên runtime CP92; deployment `dep-db8cgp6q1p3s73acdhcg` từ HEAD `568f69bb` đã Live, health/manifest/asset probe PASS. Hotfix UI/dịch `d28a0679` đã build + release-verify PASS nhưng chưa bấm deploy manual; hai commit QA/docs sau đó (`c8078be2`, `eb4e9570`) không đổi `game/web/src`, `dist`, gateway hoặc runtime. Candidate sẵn sàng smoke test, chưa phải official.
- **Điều kiện người dùng nêu:** native chỉ coi skill fake là hoạt động khi đã prelight; `SkillEffect` gọi `revealBySkillName` trước effect. Quách Gia úp → prelight Di Kế → nhận sát thương → invoke → mở đúng chủ/phó → chạy Di Kế đã PASS NATIVE-LOCAL ở nhánh negative/positive/skip và re-hide main/deputy. Đây chưa phải evidence Render/Oracle.
- **React boundary:** fake/regular skill projection, privacy theo Self, prelight wire `prelight,<skill>,true|false`, request/reply và reconnect duplicate đã được kiểm chứng; React không tự quyết damage, reveal, card, phe hoặc winner.
- **Coverage hiện hành:** source projection/lifecycle `520/520`, slot route `155.168/155.168`, prelight sync `403/403`; inventory có `607` cặp trigger `skill × event` non-delay trên `53` event kinds, native-local effect evidence hiện **21/607** trên **13/53** event kinds. `hidden-kuanggu` main/deputy đã PASS `BeforeHpChanged → Damage → SkillEffect → mở đúng slot → draw1`; hosted/Oracle vẫn chưa có package identity.
- **Native probe mới nhất:** đã cài/verify `tqs_qa` hiện hành vào scratch runtime và tạo release manifest đúng với UI CP96; identity gate PASS, hai account vào được phòng `hidden-tiandu`, nhưng host không phát fake Thiên Đố và `nativeQaGateSeen=false` (cặp tướng ngẫu nhiên), nên probe dừng trước gameplay. Evidence: [`reconnect-failure-1792066870927.json`](../scratch/evidence/reconnect-failure-1792066870927.json). Không dùng kết quả này để kết luận `FinishJudge` sai; remote package/config vẫn chưa xác định.
- **Gate vừa chạy PASS:** fresh `npm --prefix game/web run test:e2e:lua` **63/63**, `test:hidden-rule-contract` **8/8**, `audit:hidden-skills`, `audit:hidden-effects`, `test:qa-server-contract` **33/33**, `typecheck`; release verifier trước đó PASS. Đây là bằng chứng browser/Wasmoon/React và native-local, không thay thế hosted/Oracle evidence.
- **Fresh native-local hidden-yiji:** trên C++/Lua thật, source pin `b8a2ad4…`, runtime flist MD5 `ca33a1e8…`, QA package revision `b412f91b…` nguyên trạng, đã PASS đủ `positive`/`negative`/`skip`: prelight + invoke mở Quách Gia trước Di Kế và chuyển 2 lá; không prelight không hỏi/không mở; prelight nhưng bỏ qua không mở/không effect. Evidence chi tiết và hash chỉ giữ ở audit canonical; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-tiandu:** cùng runtime/package identity đã PASS cả main/deputy: `room:judge` → `FinishJudge` → reveal đúng slot → lấy lá đang ở `Card.Processing`; harness đã loại assertion generic `PlayCard` không áp dụng cho trigger này. Evidence chi tiết chỉ giữ ở audit canonical; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-fanjian:** cùng runtime/package identity đã PASS cả main/deputy: `PlayCard` khi Chu Du còn úp → reveal đúng slot → tặng Đào → mục tiêu chọn “Mất 1 máu” → GameOver/cleanup sạch. Harness được mở rộng để nhận đúng nhãn bản dịch hiện hành; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-kuanggu:** cùng runtime/package identity `3d88cece…` + QA package `eb4e9570…` đã PASS cả main [`1792072481881`](../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792072481881.json) và deputy [`1792072494326`](../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792072494326.json): Ngụy Diên còn úp, đã prelight, dùng Sát cự ly 1; native đánh dấu `BeforeHpChanged`, chạy `Damage`, mở đúng chủ/phó trước `SkillEffect` và rút 1 lá. Đây là bằng chứng trực tiếp cho điều kiện “tướng úp nhưng đủ điều kiện vẫn kích hoạt”, vẫn là NATIVE-LOCAL/unpinned.
- **Tích hợp toàn diện 100% từ điển chính thức (UI-01):** Đã nạp thành công 13.031 mục bản dịch tiếng Việt do người dùng cung cấp từ `ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv`. Đã qua khâu kiểm tra tự động: 0 ô trống, 0 chữ Hán sót lại, 0 lỗi placeholder, 0 lỗi thẻ HTML; sửa 152 điểm lỗi máy dịch (như `Người đóa` -> `Họa`, `Lá Phi` -> `Trương Phi`, `Điển là` -> `Điển Vi`, `Lưu lượt` -> `Lưu Hiệp`, `vàng Cái` -> `Hoàng Cái`, v.v.). Biên dịch sang `officialTranslations.json`, nạp vào `VI_ADDITIONS` trong `vietnamese.ts` và cập nhật đồng bộ `ZH_CN_ORIGINAL_CATALOG.json`, `ZH_CN_ORIGINAL_CATALOG.md`. Toàn bộ `test:store` (40/40), `test:vietnamese` (4/4), `test:card-display` (12/12), `test:e2e` (20/20), `test:e2e:lua` (63/63) và `npm run build` đều PASS 100%.
- **Lua ABI:** launcher và installer đã fail-closed với Lua 5.5, chọn Lua 5.4 và preflight `socket`/`lfs`; native-local đã verify. Oracle chưa được verify lại package hiện hành.
- **Oracle/SSH:** profile `tqs-native-qa` và public key local tồn tại nhưng `ssh -o BatchMode=yes tqs-native-qa true` vẫn `Permission denied (publickey)`. Chưa có quyền guest để đọc manifest hoặc cài `tqs_qa`; không ghi nhận deploy trên VM và không dùng NATIVE-LOCAL để suy ra LIVE.

## Evidence và trạng thái ticket

| Tầng | Trạng thái | Giới hạn phải giữ rõ |
| --- | --- | --- |
| Source/runtime contract | PASS | Code/catalog/caller hợp lệ trong 14 package; không chứng minh effect đã chạy. |
| React/Wasmoon/local | PASS | Projection, privacy, request/reply, dialog và lifecycle đã có regression; fixture không thay thế C++. |
| NATIVE-LOCAL hidden skill | PASS bounded | Các case Di Kế, staged trigger add-on, Cuồng Cốt và Phản Gián main/deputy đã chạy C++/Lua thật trong runtime cô lập; không phải Render/Oracle. |
| LIVE candidate | PASS bounded | Login/lobby/room/bot/GameOver và CP96 asset probe đã có; chưa là full rule parity. |
| Exhaustive hidden effects | OPEN | `21/607` cặp native-local trên 13 event kinds; cần scenario main/deputy cho event groups còn lại. |
| PLAYABLE_MOBILE / official | FALSE / OPEN | Còn live interaction matrix, rescue/wild/founding, release operations và sign-off. |

## Việc còn mở theo thứ tự

1. Khôi phục guest admin/recovery access, đọc manifest thực tế trên Oracle, rồi install/verify `tqs_qa` và rerun hosted/Oracle; hiện SSH là blocker môi trường, không phải bằng chứng luật React sai.
2. Dùng [`audit:hidden-effects`](../game/web/scripts/hidden-effect-audit.ts) làm checklist dựng native scenario main/deputy cho `TargetSpecified`, `TargetConfirmed`, `Damage`, `DamageCaused`, `CardUseFinished`, `EnterDying`, rescue/retrial, phase/death/round và package-specific hooks.
3. Hoàn tất live native interaction matrix: CardChosen, Poxi, CardsAndChoice, ArrangeCards, AG, MoveCardInBoard, SkillInvoke, CustomDialog; kiểm cancel/expiry/cleanup/reconnect theo semantics từng request.
4. Sau xác nhận thao tác, deploy hotfix `d28a0679` lên Render và probe health/manifest/assets; sau đó mở smoke test candidate cho người dùng. Chỉ cập nhật release/`PLAYABLE_MOBILE` khi evidence đúng tầng đã có.

## Nguyên tắc phiên sau

- `SOURCE` = code tồn tại; `LOCAL` = fixture/VM; `NATIVE-LOCAL` = browser + C++ thật trong runtime cô lập; `LIVE` = candidate/hosted release. Không trộn các tầng.
- Không port luật gốc sang React, không auto-select để vượt request chưa hỗ trợ, không suy ra full parity từ số skill/file/test.
- Bảo toàn mọi thay đổi dirty hiện có; không reset/clean/checkout ghi đè hoặc commit thay người dùng.
- Sau mốc đáng kể: cập nhật [`CODEX_PLAN.md`](CODEX_PLAN.md), tài liệu canonical nếu cần, rồi chạy `npm run codex:checkpoint`.

## Bước tiếp theo có thể chạy ngay

Tập trung guest access/recovery để cài và đọc manifest `tqs_qa` trên đúng target remote; sau khi Kuanggu local đã PASS, deploy hotfix Render khi được xác nhận, mở smoke test người dùng và tiếp tục native matrix theo các event group còn thiếu. Không đánh dấu goal hoàn tất khi exhaustive effect matrix hoặc hosted native identity còn mở.

## Ảnh chụp Git (tự động)

<!-- CODEX_SNAPSHOT_START -->
- Ghi lúc: 2026-10-15T13:58:42.381Z (UTC).
- Nhánh: `codex/cp89-render-current` · HEAD: `93b707502ec2`.
- File thay đổi hiển thị: 0 (đã ẩn tên file có thể nhạy cảm và không tính chính tài liệu này).

```text
(không có thay đổi ngoài CODEX_STATE.md)
```

Ba commit gần nhất:

```text
93b70750 docs: record kuanggu native evidence and release gates
eb4e9570 test: fix kuanggu owner trace assertion
c8078be2 qa: cover hidden kuanggu damage reveal path
```

> Ảnh chụp này chỉ phản ánh metadata Git lúc chạy lệnh. Để biết trạng thái **ngay bây giờ**, chạy `git status --short`; không suy diễn PASS từ danh sách file.
<!-- CODEX_SNAPSHOT_END -->
