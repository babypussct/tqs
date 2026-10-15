# CODEX_STATE — bàn giao công việc TQS

> Cập nhật handoff: 15/10/2026 23:40 (giờ Việt Nam). Đây là trạng thái hiện hành, không phải nhật ký commit. Chi tiết luật/evidence chỉ giữ ở [`web-client/QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md); hồ sơ vận hành Oracle/SSH chỉ giữ ở [`deploy/freekill-native/README.md`](../deploy/freekill-native/README.md).

## Mục tiêu và phạm vi

Hoàn thiện client Tam Quốc Sát trên trình duyệt điện thoại bằng React + Wasmoon Lua + gateway, dùng FreeKill C++/Lua làm nguồn sự thật. Scope hiện tại là `new_heg_mode` với 14 package; không port luật server sang TypeScript và không trộn TQSShop.

## Handoff ngắn

- **Render candidate:** [`tqs-mobile-candidate`](https://tqs-mobile-candidate.onrender.com) sẽ được deploy manual từ branch `codex/cp89-render-current` sau khi push commit hiện hành. Build/typecheck PASS; artifact vẫn là candidate UI/dịch đã release-verify, chưa phải official. Sau deploy phải ghi deployment ID cùng health/manifest/asset probe vào handoff.
- **Điều kiện người dùng nêu:** native chỉ coi skill fake là hoạt động khi đã prelight; `SkillEffect` gọi `revealBySkillName` trước effect. Quách Gia úp → prelight Di Kế → nhận sát thương → invoke → mở đúng chủ/phó → chạy Di Kế đã PASS NATIVE-LOCAL ở nhánh negative/positive/skip và re-hide main/deputy. Đây chưa phải evidence Render/Oracle.
- **React boundary:** fake/regular skill projection, privacy theo Self, prelight wire `prelight,<skill>,true|false`, request/reply và reconnect duplicate đã được kiểm chứng; React không tự quyết damage, reveal, card, phe hoặc winner.
- **Coverage hiện hành:** source projection/lifecycle `520/520`, slot route `155.168/155.168`, prelight sync `403/403`; inventory có `607` cặp trigger `skill × event` non-delay trên `53` event kinds, native-local effect evidence hiện **22/607** trên **14/53** event kinds. Oracle replacement có **51 run bounded PASS**, gồm bộ 32 run ban đầu và các nhánh DrawNCards, EventPhaseStart, BeforeCardsMove, active/ViewAs, re-hide Di Kế, Song Hùng, Phản Gián và helper mở tướng; rescue/founding request cũng PASS riêng. Render hosted route và exhaustive matrix vẫn mở.
- **Native probe lịch sử:** lần thử Thiên Đố trước khi thay VM đã vào được phòng nhưng host chưa có gate deterministic (`nativeQaGateSeen=false`), nên dừng trước gameplay. Evidence [`reconnect-failure-1792066870927.json`](../scratch/evidence/reconnect-failure-1792066870927.json) chỉ là diagnostic cũ, không dùng để kết luận `FinishJudge` sai. Replacement hiện đã cài/verify `tqs_qa` và đã có native gate PASS cho bộ bounded nêu trên. Run `fazheng-enyuan` mới nhất vẫn dừng ở assertion roster/owner của harness; không được ghi nhận là luật PASS hay FAIL.
- **Gate vừa chạy PASS:** fresh `npm --prefix game/web run test:e2e:lua` **63/63**, `test:hidden-rule-contract` **8/8**, `audit:hidden-skills`, `audit:hidden-effects` (**22/607**, **14/53**), `test:qa-server-contract` **34/34**, `typecheck`; release verifier và Oracle `verify-install.sh`/`verify-qa-package.sh` đều PASS. Đây là bằng chứng browser/Wasmoon/React, native-local và Oracle bounded; không thay thế Render hosted route hoặc full effect matrix.
- **Fresh native-local hidden-yiji:** trên C++/Lua thật, source pin `b8a2ad4…`, runtime flist MD5 `ca33a1e8…`, QA package revision `b412f91b…` nguyên trạng, đã PASS đủ `positive`/`negative`/`skip`: prelight + invoke mở Quách Gia trước Di Kế và chuyển 2 lá; không prelight không hỏi/không mở; prelight nhưng bỏ qua không mở/không effect. Evidence chi tiết và hash chỉ giữ ở audit canonical; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-tiandu:** cùng runtime/package identity đã PASS cả main/deputy: `room:judge` → `FinishJudge` → reveal đúng slot → lấy lá đang ở `Card.Processing`; harness đã loại assertion generic `PlayCard` không áp dụng cho trigger này. Evidence chi tiết chỉ giữ ở audit canonical; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-fanjian:** cùng runtime/package identity đã PASS cả main/deputy: `PlayCard` khi Chu Du còn úp → reveal đúng slot → tặng Đào → mục tiêu chọn “Mất 1 máu” → GameOver/cleanup sạch. Harness được mở rộng để nhận đúng nhãn bản dịch hiện hành; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-kuanggu:** cùng runtime/package identity `3d88cece…` + QA package `eb4e9570…` đã PASS cả main [`1792072481881`](../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792072481881.json) và deputy [`1792072494326`](../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792072494326.json): Ngụy Diên còn úp, đã prelight, dùng Sát cự ly 1; native đánh dấu `BeforeHpChanged`, chạy `Damage`, mở đúng chủ/phó trước `SkillEffect` và rút 1 lá. Đây là bằng chứng trực tiếp cho điều kiện “tướng úp nhưng đủ điều kiện vẫn kích hoạt”, vẫn là NATIVE-LOCAL/unpinned.
- **Fresh native-local hidden-liegong:** runtime `flist.txt` MD5 `4ab95597…`, QA revision `a3618958…`, package SHA-256 `6b8e5b7c…` đã PASS cả main [`1792073569775`](../scratch/evidence/cp08-hidden-liegong-multiplayer-live-1792073569775.json) và deputy [`1792073583047`](../scratch/evidence/cp08-hidden-liegong-deputy-multiplayer-live-1792073583047.json): Hoàng Trung còn úp nhưng đã prelight, dùng Sát thỏa predicate HP; native phát `TargetSpecified`, mở đúng chủ/phó trước `SkillEffect`, nhận lựa chọn `damage +1` và gây đúng 2 damage. Đây là bằng chứng trực tiếp cho một cặp TargetSpecified mới, vẫn là NATIVE-LOCAL/unpinned.
- **Tích hợp toàn diện 100% từ điển chính thức (UI-01):** Đã nạp thành công 13.031 mục bản dịch tiếng Việt do người dùng cung cấp từ `ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv`. Đã qua khâu kiểm tra tự động: 0 ô trống, 0 chữ Hán sót lại, 0 lỗi placeholder, 0 lỗi thẻ HTML; sửa 152 điểm lỗi máy dịch (như `Người đóa` -> `Họa`, `Lá Phi` -> `Trương Phi`, `Điển là` -> `Điển Vi`, `Lưu lượt` -> `Lưu Hiệp`, `vàng Cái` -> `Hoàng Cái`, v.v.). Biên dịch sang `officialTranslations.json`, nạp vào `VI_ADDITIONS` trong `vietnamese.ts` và cập nhật đồng bộ `ZH_CN_ORIGINAL_CATALOG.json`, `ZH_CN_ORIGINAL_CATALOG.md`. Toàn bộ `test:store` (40/40), `test:vietnamese` (4/4), `test:card-display` (12/12), `test:e2e` (20/20), `test:e2e:lua` (63/63) và `npm run build` đều PASS 100%.
- **Lua ABI:** launcher và installer đã fail-closed với Lua 5.5, chọn Lua 5.4 và preflight `socket`/`lfs`; native-local và Oracle replacement đều verify PASS. Oracle đang chạy Lua 5.4.8; old VM chưa cập nhật.
- **Oracle/SSH:** hồ sơ vận hành đã được lưu tập trung ở [`deploy/freekill-native/README.md`](../deploy/freekill-native/README.md). VM cũ `freekill-hegemony` (`168.110.36.224`) vẫn giữ nguyên và SSH guest trên máy cũ còn PENDING; không xoá/reinstall hay sửa guest file. VM thay thế `freekill-hegemony-qa` (`161.33.209.212`, OCID mới, alias `tqs-native-qa-replacement`) RUNNING và SSH PASS bằng key Ed25519 đã lưu. Trên replacement, `verify-install.sh` PASS với Lua 5.4.8, 14/14 package pin, hardening prelight/reattach và port 9527; `verify-qa-package.sh` PASS với QA revision `5218c225…`, package SHA `6b8e5b7c…`, catalog SHA `887544d1…`; service enabled/active. Old VM là rollback/reference, replacement chỉ là QA-verified native target, chưa phải official/public.
- **Oracle hidden-trigger QA:** qua isolated local gateway trỏ `FK_HOST=161.33.209.212`, identity gate PASS (`runtime MD5 07ef36b3…`, web `dist/index.html` SHA-256 `7c34d093…`, 14 package). Bộ gốc **32/32** run PASS; sau đó thêm 19 run PASS cho Yingzi, Luoshen, delayed-Trick `BeforeCardsMove`, active/ViewAs, re-hide Di Kế, Song Hùng, Phản Gián và helper mở tướng; rescue-normal, rescue-battle và founding request cũng PASS riêng. Tất cả kết quả được giữ trong audit/evidence canonical, nhưng run `fazheng-enyuan` mới nhất chưa đạt assertion roster owner. Đây là Oracle native bounded evidence, chưa chứng minh Render → Oracle route, full effect matrix hoặc official release.

## Evidence và trạng thái ticket

| Tầng | Trạng thái | Giới hạn phải giữ rõ |
| --- | --- | --- |
| Source/runtime contract | PASS | Code/catalog/caller hợp lệ trong 14 package; không chứng minh effect đã chạy. |
| React/Wasmoon/local | PASS | Projection, privacy, request/reply, dialog và lifecycle đã có regression; fixture không thay thế C++. |
| NATIVE-LOCAL hidden skill | PASS bounded | Các case Di Kế, staged trigger add-on, Cuồng Cốt, Liệt Cung và Phản Gián main/deputy đã chạy C++/Lua thật trong runtime cô lập; không gộp thành hosted/official. |
| Oracle QA hidden-trigger | PASS bounded | Replacement VM identity, Lua 5.4.8, package/QA manifest và **51 run bounded PASS** qua isolated gateway; thêm rescue/founding request PASS, còn `fazheng-enyuan` owner-roster harness chưa đóng. Render → Oracle route, full matrix và official release còn mở. |
| LIVE candidate | PASS bounded | Login/lobby/room/bot/GameOver và CP96 asset probe đã có; chưa là full rule parity. |
| Exhaustive hidden effects | OPEN | `22/607` cặp native-local trên 14 event kinds; cần scenario main/deputy cho event groups còn lại. |
| PLAYABLE_MOBILE / official | FALSE / OPEN | Còn live interaction matrix, rescue/wild/founding, release operations và sign-off. |

## Việc còn mở theo thứ tự

1. Đã đóng guest/package identity và bounded Oracle hidden/activation evidence ở mức 51 run PASS; `fazheng-enyuan` còn blocker harness. Việc kế tiếp là (a) probe Render candidate sau deploy và nếu dùng đường public thì trỏ Render candidate/gateway vào replacement rồi rerun đúng identity qua hosted URL, (b) tiếp tục native interaction matrix/rescue/wild/founding và các hidden-effect family còn thiếu trên Oracle; không gắn kết quả local gateway này thành Render evidence.
2. Dùng [`audit:hidden-effects`](../game/web/scripts/hidden-effect-audit.ts) làm checklist dựng native scenario main/deputy cho `TargetSpecified` còn lại, `TargetConfirmed`, `Damage`, `DamageCaused`, `CardUseFinished`, `EnterDying`, rescue/retrial, phase/death/round và package-specific hooks.
3. Hoàn tất live native interaction matrix: CardChosen, Poxi, CardsAndChoice, ArrangeCards, AG, MoveCardInBoard, SkillInvoke, CustomDialog; kiểm cancel/expiry/cleanup/reconnect theo semantics từng request.
4. Deploy commit hiện hành lên Render, probe health/manifest/assets và mở smoke test candidate cho người dùng. Chỉ cập nhật release/`PLAYABLE_MOBILE` khi evidence đúng tầng đã có.

## Nguyên tắc phiên sau

- `SOURCE` = code tồn tại; `LOCAL` = fixture/VM; `NATIVE-LOCAL` = browser + C++ thật trong runtime cô lập; `LIVE` = candidate/hosted release. Không trộn các tầng.
- Không port luật gốc sang React, không auto-select để vượt request chưa hỗ trợ, không suy ra full parity từ số skill/file/test.
- Bảo toàn mọi thay đổi dirty hiện có; không reset/clean/checkout ghi đè hoặc commit thay người dùng.
- Sau mốc đáng kể: cập nhật [`CODEX_PLAN.md`](CODEX_PLAN.md), tài liệu canonical nếu cần, rồi chạy `npm run codex:checkpoint`.

## Bước tiếp theo có thể chạy ngay

Tập trung vào hosted route nếu cần: giữ Render candidate và Oracle replacement độc lập, chỉ đổi `FK_HOST`/deploy khi có release identity tương ứng, rồi rerun hosted URL. Song song tiếp tục native matrix theo các event group còn thiếu. Không đánh dấu goal hoàn tất khi exhaustive effect matrix hoặc hosted native route còn mở.

## Ảnh chụp Git (tự động)

<!-- CODEX_SNAPSHOT_START -->
- Ghi lúc: 2026-10-15T16:09:39.242Z (UTC).
- Nhánh: `codex/cp89-render-current` · HEAD: `d48b4a907621`.
- File thay đổi hiển thị: 3 (đã ẩn tên file có thể nhạy cảm và không tính chính tài liệu này).

```text
 M deploy/freekill-native/README.md
 M docs/CODEX_PLAN.md
 M docs/web-client/QUOC_CHIEN_RULE_AUDIT.md
```

Ba commit gần nhất:

```text
d48b4a90 docs: refresh codex checkpoint
f3c0cfed docs: record hidden liegong native evidence
a3618958 qa: cover hidden liegong reveal damage path
```

> Ảnh chụp này chỉ phản ánh metadata Git lúc chạy lệnh. Để biết trạng thái **ngay bây giờ**, chạy `git status --short`; không suy diễn PASS từ danh sách file.
<!-- CODEX_SNAPSHOT_END -->
