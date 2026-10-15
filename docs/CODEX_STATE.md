# CODEX_STATE — bàn giao công việc TQS

> Cập nhật handoff: 15/10/2026 19:37 (giờ Việt Nam). Đây là trạng thái hiện hành, không phải nhật ký commit. Chi tiết luật/evidence chỉ giữ ở [`web-client/QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md).

## Mục tiêu và phạm vi

Hoàn thiện client Tam Quốc Sát trên trình duyệt điện thoại bằng React + Wasmoon Lua + gateway, dùng FreeKill C++/Lua làm nguồn sự thật. Scope hiện tại là `new_heg_mode` với 14 package; không port luật server sang TypeScript và không trộn TQSShop.

## Handoff ngắn

- **Render candidate:** [`tqs-mobile-candidate`](https://tqs-mobile-candidate.onrender.com) đang ở identity CP96 UI trên runtime CP92; deployment `dep-db8cgp6q1p3s73acdhcg` từ HEAD `568f69bb` đã Live, health/manifest/asset probe PASS. Các commit sau CP96 chỉ là QA/docs/harness, không đổi `game/web/src`, `dist`, gateway hoặc runtime; lần redeploy này giữ nguyên artifact CP96 để người dùng smoke test, chưa phải official.
- **Điều kiện người dùng nêu:** native chỉ coi skill fake là hoạt động khi đã prelight; `SkillEffect` gọi `revealBySkillName` trước effect. Quách Gia úp → prelight Di Kế → nhận sát thương → invoke → mở đúng chủ/phó → chạy Di Kế đã PASS NATIVE-LOCAL ở nhánh negative/positive/skip và re-hide main/deputy. Đây chưa phải evidence Render/Oracle.
- **React boundary:** fake/regular skill projection, privacy theo Self, prelight wire `prelight,<skill>,true|false`, request/reply và reconnect duplicate đã được kiểm chứng; React không tự quyết damage, reveal, card, phe hoặc winner.
- **Coverage hiện hành:** source projection/lifecycle `520/520`, slot route `155.168/155.168`, prelight sync `403/403`; inventory có `607` cặp trigger `skill × event` non-delay trên `53` event kinds, nhưng native-local effect evidence mới `18/607`. `hidden-tiandu` và `hidden-fanjian` mới đạt source/catalog/browser contract, chưa tính native C++ gameplay.
- **Native probe mới nhất:** đã cài/verify `tqs_qa` hiện hành vào scratch runtime và tạo release manifest đúng với UI CP96; identity gate PASS, hai account vào được phòng `hidden-tiandu`, nhưng host không phát fake Thiên Đố và `nativeQaGateSeen=false` (cặp tướng ngẫu nhiên), nên probe dừng trước gameplay. Evidence: [`reconnect-failure-1792066870927.json`](../scratch/evidence/reconnect-failure-1792066870927.json). Không dùng kết quả này để kết luận `FinishJudge` sai; remote package/config vẫn chưa xác định.
- **Gate vừa chạy PASS:** source-law contract `test:hidden-rule-contract` 8/8 (thêm đường ActiveSkill/ViewAsSkill → regular PlayCard → `useSkill` → reveal-before-effect); `audit:hidden-skills`; `audit:hidden-effects`; `test:qa-server-contract` 32/32; `typecheck`; các gate trước đó gồm `test:store` 40/40 và `test:e2e:lua` 63/63. Các fixture/local gate không thay thế native hosted evidence.
- **Lua ABI:** launcher và installer đã fail-closed với Lua 5.5, chọn Lua 5.4 và preflight `socket`/`lfs`; native-local đã verify. Oracle chưa được verify lại package hiện hành.
- **Oracle/SSH:** profile `tqs-native-qa` và public key local tồn tại nhưng `ssh -o BatchMode=yes tqs-native-qa true` vẫn `Permission denied (publickey)`. Chưa có quyền guest để đọc manifest hoặc cài `tqs_qa`; không ghi nhận deploy trên VM và không dùng NATIVE-LOCAL để suy ra LIVE.

## Evidence và trạng thái ticket

| Tầng | Trạng thái | Giới hạn phải giữ rõ |
| --- | --- | --- |
| Source/runtime contract | PASS | Code/catalog/caller hợp lệ trong 14 package; không chứng minh effect đã chạy. |
| React/Wasmoon/local | PASS | Projection, privacy, request/reply, dialog và lifecycle đã có regression; fixture không thay thế C++. |
| NATIVE-LOCAL hidden skill | PASS bounded | Các case Di Kế và staged add-on đã chạy C++/Lua thật trong runtime cô lập; không phải Render/Oracle. |
| LIVE candidate | PASS bounded | Login/lobby/room/bot/GameOver và CP96 asset probe đã có; chưa là full rule parity. |
| Exhaustive hidden effects | OPEN | `18/607` cặp native-local; cần scenario main/deputy cho event groups còn lại. |
| PLAYABLE_MOBILE / official | FALSE / OPEN | Còn live interaction matrix, rescue/wild/founding, release operations và sign-off. |

## Việc còn mở theo thứ tự

1. Khôi phục guest admin/recovery access, đọc manifest thực tế trên Oracle, rồi install/verify `tqs_qa` và rerun hosted/Oracle; hiện SSH là blocker môi trường, không phải bằng chứng luật React sai.
2. Dùng [`audit:hidden-effects`](../game/web/scripts/hidden-effect-audit.ts) làm checklist dựng native scenario main/deputy cho `TargetSpecified`, `TargetConfirmed`, `Damage`, `DamageCaused`, `CardUseFinished`, `EnterDying`, rescue/retrial, phase/death/round và package-specific hooks.
3. Hoàn tất live native interaction matrix: CardChosen, Poxi, CardsAndChoice, ArrangeCards, AG, MoveCardInBoard, SkillInvoke, CustomDialog; kiểm cancel/expiry/cleanup/reconnect theo semantics từng request.
4. Mở smoke test CP96 cho người dùng; chỉ cập nhật release/`PLAYABLE_MOBILE` khi evidence đúng tầng đã có.

## Nguyên tắc phiên sau

- `SOURCE` = code tồn tại; `LOCAL` = fixture/VM; `NATIVE-LOCAL` = browser + C++ thật trong runtime cô lập; `LIVE` = candidate/hosted release. Không trộn các tầng.
- Không port luật gốc sang React, không auto-select để vượt request chưa hỗ trợ, không suy ra full parity từ số skill/file/test.
- Bảo toàn mọi thay đổi dirty hiện có; không reset/clean/checkout ghi đè hoặc commit thay người dùng.
- Sau mốc đáng kể: cập nhật [`CODEX_PLAN.md`](CODEX_PLAN.md), tài liệu canonical nếu cần, rồi chạy `npm run codex:checkpoint`.

## Bước tiếp theo có thể chạy ngay

Tập trung guest access/recovery để cài và đọc manifest `tqs_qa` trên đúng target remote, rồi rerun cả `hidden-tiandu` main/deputy; song song giữ Render CP96 hiện hành cho smoke test UI. Không đánh dấu goal hoàn tất khi exhaustive effect matrix hoặc hosted native identity còn mở.

## Ảnh chụp Git (tự động)

<!-- CODEX_SNAPSHOT_START -->
- Ghi lúc: 2026-10-15T12:37:57.650Z (UTC).
- Nhánh: `codex/cp89-render-current` · HEAD: `1a47bebcfefc`.
- File thay đổi hiển thị: 6 (đã ẩn tên file có thể nhạy cảm và không tính chính tài liệu này).

```text
 M game/web/scripts/card-display.test.ts
 M game/web/scripts/store.test.ts
?? docs/translations/ZH_CN_ORIGINAL_CATALOG.json
?? docs/translations/ZH_CN_ORIGINAL_CATALOG.md
?? docs/translations/ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv
?? game/web/scripts/export-all-zh.ts
```

Ba commit gần nhất:

```text
1a47bebc docs: record Render hotfix redeploy
568f69bb docs: checkpoint hidden active skill gate
857ee0f2 qa: lock hidden active skill reveal path
```

> Ảnh chụp này chỉ phản ánh metadata Git lúc chạy lệnh. Để biết trạng thái **ngay bây giờ**, chạy `git status --short`; không suy diễn PASS từ danh sách file.
<!-- CODEX_SNAPSHOT_END -->
