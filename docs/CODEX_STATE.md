# CODEX_STATE — bàn giao công việc TQS

> Cập nhật handoff: 16/10/2026 sau CP12 hidden Gian Chí trên tuyến Render → Oracle (giờ Việt Nam). Đây là trạng thái hiện hành, không phải nhật ký commit. Chi tiết luật/evidence chỉ giữ ở [`web-client/QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md); hồ sơ vận hành Oracle/SSH chỉ giữ ở [`deploy/freekill-native/README.md`](../deploy/freekill-native/README.md).

## Mục tiêu và phạm vi

Hoàn thiện client Tam Quốc Sát trên trình duyệt điện thoại bằng React + Wasmoon Lua + gateway, dùng FreeKill C++/Lua làm nguồn sự thật. Scope hiện tại là `new_heg_mode` với 14 package; không port luật server sang TypeScript và không trộn TQSShop.

## Handoff ngắn

- **Render → Oracle replacement:** [`tqs-mobile-candidate`](https://tqs-mobile-candidate.onrender.com) **Live** từ deployment [`dep-db8j9gei0phs73fs8pcg`](https://dashboard.render.com/web/srv-db63aclckfvc73bvrli0/deploys/dep-db8j9gei0phs73fs8pcg), commit `798dc2e4`. Public health `200 / ok`, HTML SHA-256 `591c51f15482d78267b3db4c48b150d20747d5bf83631f01c335e7799e114012`, manifest `5.279` file, runtime MD5 `43b6cdade072b75f93b9d49b3384f08f`; Oracle QA revision `48725c8ae9cc1917d415eec442841835ae881394`, package `4209c70465366a19ea75f104f53874ffa50c1656e7fec084c493f5b9a4f9cb45`, catalog `054d955bfd70bd14bef28ea9b925585974599b78a95c053261b59576df48ece2`, package isolated at `qa_packages/tqs_qa`. Hidden Fuyin, Di Kế, Ách Tuyệt, Độc Phu và Gian Chí `DamageCaused` chủ/phó đã PASS hosted trên đúng identity. Render artifact không đổi ở CP11/CP12; chỉ QA package native trên replacement được cập nhật. Đây vẫn là candidate, chưa official.
- **Ước tính tiến độ:** mục tiêu candidate mobile để người dùng smoke test vẫn khoảng **65%**, còn khoảng **35%** đến mốc public/official. CP12 đã khóa thêm một cặp `DamageCaused` của Gian Chí ở cả chủ/phó, gồm lethal damage, bỏ tay, banner thưởng và reveal đúng slot; exhaustive rule parity vẫn xa hơn: native-local direct effect evidence **25/607** cặp (**15/53** event kinds). Không quy đổi 25/607 thành tỷ lệ hoàn thiện toàn goal; corpus 51 run identity cũ chỉ giữ làm historical reference.
- **Điều kiện người dùng nêu:** native chỉ coi skill fake là hoạt động khi đã prelight; `SkillEffect` gọi `revealBySkillName` trước effect. Current CP09/CP10 đã chạy đúng ví dụ Quách Gia/Di Kế: pre-gate thấy fake skill khi tướng còn úp, sau đó nhận damage → `AskForSkillInvoke` → invoke → chuyển 2 lá; PASS cả chủ [`cp08-hidden-yiji-multiplayer-live-1792097106182.json`](../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792097106182.json) và phó [`cp08-hidden-yiji-deputy-multiplayer-live-1792097120803.json`](../scratch/evidence/cp08-hidden-yiji-deputy-multiplayer-live-1792097120803.json). CP12 bổ sung Gian Chí: prelight gate → Sát lethal → prompt invoke thật → bỏ lá còn lại → reward banner/reveal, PASS cả chủ [`cp12-hidden-jianzhi-multiplayer-live-1792112786904.json`](../scratch/evidence/cp12-hidden-jianzhi-multiplayer-live-1792112786904.json) và phó [`cp12-hidden-jianzhi-deputy-multiplayer-live-1792112874147.json`](../scratch/evidence/cp12-hidden-jianzhi-deputy-multiplayer-live-1792112874147.json). Cùng identity, Fuyin PASS `TargetConfirmed`/reveal/vô hiệu Sát, Ách Tuyệt và Độc Phu PASS `DamageCaused`/damage+1 ở cả chủ/phó; với Độc Phu, skill source là compulsory và gate QA không phải prompt lựa chọn của source. Đây là bounded evidence, chưa phải full effect parity.
- **React boundary:** fake/regular skill projection, privacy theo Self, prelight wire `prelight,<skill>,true|false`, request/reply và reconnect duplicate đã được kiểm chứng; React không tự quyết damage, reveal, card, phe hoặc winner.
- **Coverage hiện hành:** source projection/lifecycle `520/520`, slot route `155.168/155.168`, prelight sync `403/403`; inventory có `607` cặp trigger `skill × event` non-delay trên `53` event kinds, native-local effect evidence hiện **25/607** trên **15/53** event kinds. Current CP09/CP10/CP11/CP12 hosted proof đã khóa Di Kế positive, Fuyin `TargetConfirmed`, Ách Tuyệt, Độc Phu và Gian Chí `DamageCaused` ở cả chủ/phó; các batch hidden-trigger khác dùng identity trước và chỉ là historical reference. Exhaustive matrix vẫn mở.
- **Native probe lịch sử:** lần thử Thiên Đố trước khi thay VM đã vào được phòng nhưng host chưa có gate deterministic (`nativeQaGateSeen=false`), nên dừng trước gameplay. Evidence [`reconnect-failure-1792066870927.json`](../scratch/evidence/reconnect-failure-1792066870927.json) chỉ là diagnostic cũ, không dùng để kết luận `FinishJudge` sai. Replacement hiện đã cài/verify `tqs_qa` và đã có native gate PASS cho bộ bounded nêu trên. `fazheng-enyuan` broad contract vẫn là scope riêng cần hoàn thiện; không được dùng nó để phủ định hidden Ân Oán `TargetConfirmed` đã PASS.
- **Gate vừa chạy PASS:** sau CP12, `npm --prefix game/web run test:qa-server-contract` **42/42**, `npm --prefix game/web exec -- tsx --test game/web/scripts/qa-scenarios.test.ts` **5/5**, `audit:hidden-effects` (**25/607**, **15/53**), `npm --prefix game/web run test:e2e:qa` **4/4**, typecheck và build; `git diff --check`, catalog JSON và native QA contract đều PASS. Đây là bằng chứng browser/Wasmoon/React, native-local, Oracle bounded và Render → Oracle bounded; không thay thế full effect matrix.
- **Fresh Render → Oracle probe:** deployment `dep-db8j9gei0phs73fs8pcg` build từ `798dc2e4`; gateway :10000 → `161.33.209.212:9527`, public HTML và runtime MD5 cùng identity `591c51f1…` / `43b6cdad…`. Login, hidden Di Kế positive chủ/phó, native QA gate, hidden Fuyin chủ/phó, hidden Ách Tuyệt `DamageCaused` chủ/phó, hidden Độc Phu `DamageCaused` chủ/phó, hidden Gian Chí lethal `DamageCaused` chủ/phó, GameOver và clean disconnect đều PASS; evidence chi tiết nằm trong audit canonical. Đây là hosted bounded, chưa là official.
- **Fresh native-local hidden-yiji:** trên C++/Lua thật, source pin `b8a2ad4…`, runtime flist MD5 `ca33a1e8…`, QA package revision `b412f91b…` nguyên trạng, đã PASS đủ `positive`/`negative`/`skip`: prelight + invoke mở Quách Gia trước Di Kế và chuyển 2 lá; không prelight không hỏi/không mở; prelight nhưng bỏ qua không mở/không effect. Evidence chi tiết và hash chỉ giữ ở audit canonical; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-tiandu:** cùng runtime/package identity đã PASS cả main/deputy: `room:judge` → `FinishJudge` → reveal đúng slot → lấy lá đang ở `Card.Processing`; harness đã loại assertion generic `PlayCard` không áp dụng cho trigger này. Evidence chi tiết chỉ giữ ở audit canonical; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-fanjian:** cùng runtime/package identity đã PASS cả main/deputy: `PlayCard` khi Chu Du còn úp → reveal đúng slot → tặng Đào → mục tiêu chọn “Mất 1 máu” → GameOver/cleanup sạch. Harness được mở rộng để nhận đúng nhãn bản dịch hiện hành; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-kuanggu:** cùng runtime/package identity `3d88cece…` + QA package `eb4e9570…` đã PASS cả main [`1792072481881`](../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792072481881.json) và deputy [`1792072494326`](../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792072494326.json): Ngụy Diên còn úp, đã prelight, dùng Sát cự ly 1; native đánh dấu `BeforeHpChanged`, chạy `Damage`, mở đúng chủ/phó trước `SkillEffect` và rút 1 lá. Đây là bằng chứng trực tiếp cho điều kiện “tướng úp nhưng đủ điều kiện vẫn kích hoạt”, vẫn là NATIVE-LOCAL/unpinned.
- **Fresh native-local hidden-liegong:** runtime `flist.txt` MD5 `4ab95597…`, QA revision `a3618958…`, package SHA-256 `6b8e5b7c…` đã PASS cả main [`1792073569775`](../scratch/evidence/cp08-hidden-liegong-multiplayer-live-1792073569775.json) và deputy [`1792073583047`](../scratch/evidence/cp08-hidden-liegong-deputy-multiplayer-live-1792073583047.json): Hoàng Trung còn úp nhưng đã prelight, dùng Sát thỏa predicate HP; native phát `TargetSpecified`, mở đúng chủ/phó trước `SkillEffect`, nhận lựa chọn `damage +1` và gây đúng 2 damage. Đây là bằng chứng trực tiếp cho một cặp TargetSpecified mới, vẫn là NATIVE-LOCAL/unpinned.
- **Tích hợp toàn diện 100% từ điển chính thức (UI-01):** Đã nạp thành công 13.031 mục bản dịch tiếng Việt do người dùng cung cấp từ `ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv`. Đã qua khâu kiểm tra tự động: 0 ô trống, 0 chữ Hán sót lại, 0 lỗi placeholder, 0 lỗi thẻ HTML; sửa 152 điểm lỗi máy dịch (như `Người đóa` -> `Họa`, `Lá Phi` -> `Trương Phi`, `Điển là` -> `Điển Vi`, `Lưu lượt` -> `Lưu Hiệp`, `vàng Cái` -> `Hoàng Cái`, v.v.). Biên dịch sang `officialTranslations.json`, nạp vào `VI_ADDITIONS` trong `vietnamese.ts` và cập nhật đồng bộ `ZH_CN_ORIGINAL_CATALOG.json`, `ZH_CN_ORIGINAL_CATALOG.md`. Toàn bộ `test:store` (40/40), `test:vietnamese` (4/4), `test:card-display` (12/12), `test:e2e` (20/20), `test:e2e:lua` (63/63) và `npm run build` đều PASS 100%.
- **Lua ABI:** launcher và installer đã fail-closed với Lua 5.5, chọn Lua 5.4 và preflight `socket`/`lfs`; native-local và Oracle replacement đều verify PASS. Oracle đang chạy Lua 5.4.8; old VM chưa cập nhật.
- **Oracle/SSH:** hồ sơ vận hành đã được lưu tập trung ở [`deploy/freekill-native/README.md`](../deploy/freekill-native/README.md). VM cũ `freekill-hegemony` (`168.110.36.224`) vẫn giữ nguyên làm rollback/reference. VM thay thế `freekill-hegemony-qa` (`161.33.209.212`, alias `tqs-native-qa-replacement`) RUNNING và SSH PASS; Lua 5.4.8, 14/14 package pin, QA revision `48725c8…`, package `4209c704…`, catalog `054d955b…`, runtime MD5 `43b6cdad…`, service/port 9527. Public `packages/tqs_qa` không có file; QA chạy ngoài public flist. Chưa phải official/public.
- **Oracle/hosted hidden-trigger QA:** current CP09/CP10/CP11/CP12 proof là Di Kế positive, Fuyin `TargetConfirmed`, Ách Tuyệt, Độc Phu và Gian Chí `DamageCaused` chủ/phó trên Render → Oracle. Độc Phu là compulsory trong source; Gian Chí là optional sau lethal `DamageCaused`; native QA gate chỉ chuẩn bị prelight và fixture. Các batch 32 slot/nhánh trước đó thuộc identity `ae598…`/QA `f80d…`, giữ làm historical reference và không dùng làm current proof. Full effect matrix, native interaction matrix và official release vẫn mở.

## Evidence và trạng thái ticket

| Tầng | Trạng thái | Giới hạn phải giữ rõ |
| --- | --- | --- |
| Source/runtime contract | PASS | Code/catalog/caller hợp lệ trong 14 package; không chứng minh effect đã chạy. |
| React/Wasmoon/local | PASS | Projection, privacy, request/reply, dialog và lifecycle đã có regression; fixture không thay thế C++. |
| NATIVE-LOCAL hidden skill | PASS bounded | Các case Di Kế, staged trigger add-on, Cuồng Cốt, Liệt Cung, Ách Tuyệt, Độc Phu và Phản Gián main/deputy đã chạy C++/Lua thật trong runtime cô lập; không gộp thành hosted/official. |
| Oracle QA hidden-trigger | PASS bounded current / historical corpus separated | Replacement VM current identity, Lua 5.4.8, isolated QA package; Di Kế positive, Fuyin `TargetConfirmed`, Ách Tuyệt, Độc Phu và Gian Chí `DamageCaused` chủ/phó trên Render → Oracle PASS. Batch cũ thuộc identity trước và cần rerun nếu muốn tái sử dụng. Full matrix và official release còn mở. |
| LIVE candidate | PASS bounded | Login/lobby/room/bot/GameOver và CP96 asset probe đã có; chưa là full rule parity. |
| Exhaustive hidden effects | OPEN | `25/607` cặp native-local trên 15 event kinds; `DamageCaused` còn 13/16 cặp chưa có evidence; cần scenario main/deputy cho event groups còn lại. |
| PLAYABLE_MOBILE / official | FALSE / OPEN | Còn live interaction matrix, rescue/wild/founding, release operations và sign-off. |

## Việc còn mở theo thứ tự

1. Đã khóa current CP09/CP10/CP11/CP12 identity (`43b6…`, QA `48725c8…`) và Di Kế positive/Fuyin/Ách Tuyệt/Độc Phu/Gian Chí chủ-phó qua Render → Oracle. Render artifact vẫn là commit `798dc2e4`; CP11/CP12 chỉ cập nhật QA package native trên replacement. Các evidence hosted khác thuộc identity trước không tính vào current proof. Việc kế tiếp là tiếp tục native interaction matrix/rescue/wild/founding và các hidden-effect family còn thiếu trên Oracle; không mở rộng bounded scenario thành full parity.
2. Dùng [`audit:hidden-effects`](../game/web/scripts/hidden-effect-audit.ts) làm checklist dựng native scenario main/deputy cho `TargetSpecified` còn lại, `TargetConfirmed`, `Damage`, `DamageCaused` còn 13 cặp, `CardUseFinished`, `EnterDying`, rescue/retrial, phase/death/round và package-specific hooks.
3. Hoàn tất live native interaction matrix: CardChosen, Poxi, CardsAndChoice, ArrangeCards, AG, MoveCardInBoard, SkillInvoke, CustomDialog; kiểm cancel/expiry/cleanup/reconnect theo semantics từng request.
4. Mở smoke test candidate cho người dùng trên deployment Live hiện tại; ghi lại lỗi theo đúng tầng (UI/bridge/native/harness). Chỉ cập nhật release/`PLAYABLE_MOBILE` khi evidence đúng tầng đã có.

## Nguyên tắc phiên sau

- `SOURCE` = code tồn tại; `LOCAL` = fixture/VM; `NATIVE-LOCAL` = browser + C++ thật trong runtime cô lập; `LIVE` = candidate/hosted release. Không trộn các tầng.
- Không port luật gốc sang React, không auto-select để vượt request chưa hỗ trợ, không suy ra full parity từ số skill/file/test.
- Bảo toàn mọi thay đổi dirty hiện có; không reset/clean/checkout ghi đè hoặc commit thay người dùng.
- Sau mốc đáng kể: cập nhật [`CODEX_PLAN.md`](CODEX_PLAN.md), tài liệu canonical nếu cần, rồi chạy `npm run codex:checkpoint`.

## Bước tiếp theo có thể chạy ngay

Giữ Render candidate và Oracle replacement theo cùng web/runtime identity; hiện runtime MD5 `43b6cdade072b75f93b9d49b3384f08f`, QA revision `48725c8ae9cc1917d415eec442841835ae881394`, package `4209c70465366a19ea75f104f53874ffa50c1656e7fec084c493f5b9a4f9cb45`, catalog `054d955bfd70bd14bef28ea9b925585974599b78a95c053261b59576df48ece2`, deployment `dep-db8j9gei0phs73fs8pcg`. Render artifact vẫn commit `798dc2e4`; chỉ đổi `FK_HOST`/deploy khi có artifact web/runtime tương ứng, rồi chạy lại health/manifest/login probe. Song song tiếp tục native matrix theo các event group còn thiếu. Không đánh dấu goal hoàn tất khi exhaustive effect matrix, interaction matrix hoặc official release còn mở.

## Ảnh chụp Git (tự động)

<!-- CODEX_SNAPSHOT_START -->
- Ghi lúc: 2026-10-16T01:14:07.140Z (UTC).
- Nhánh: `codex/cp89-render-current` · HEAD: `3c99bdbf9754`.
- File thay đổi hiển thị: 6 (đã ẩn tên file có thể nhạy cảm và không tính chính tài liệu này).

```text
 M deploy/freekill-native/README.md
 M docs/CODEX_PLAN.md
 M docs/web-client/MOBILE_PLAYABLE_MASTER_PLAN.md
 M docs/web-client/QUOC_CHIEN_RULE_AUDIT.md
 M docs/web-client/hosting/CP08_RENDER.md
 M game/web/scripts/multiplayer-e2e/run.ts
```

Ba commit gần nhất:

```text
3c99bdbf test: use Jianzhi-specific native request assertion
48725c8a fix: make hidden Jianzhi lethal fixture deterministic
05766335 test: cover hidden Jianzhi DamageCaused parity
```

> Ảnh chụp này chỉ phản ánh metadata Git lúc chạy lệnh. Để biết trạng thái **ngay bây giờ**, chạy `git status --short`; không suy diễn PASS từ danh sách file.
<!-- CODEX_SNAPSHOT_END -->
