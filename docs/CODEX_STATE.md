# CODEX_STATE — bàn giao công việc TQS

> Cập nhật handoff: 16/10/2026 sau CP15 hidden Ký Ly/Jilix chủ/phó trên identity Render → Oracle mới (giờ Việt Nam). Đây là trạng thái hiện hành, không phải nhật ký commit. Chi tiết luật/evidence chỉ giữ ở [`web-client/QUOC_CHIEN_RULE_AUDIT.md`](web-client/QUOC_CHIEN_RULE_AUDIT.md); hồ sơ vận hành Oracle/SSH chỉ giữ ở [`deploy/freekill-native/README.md`](../deploy/freekill-native/README.md).

## Mục tiêu và phạm vi

Hoàn thiện client Tam Quốc Sát trên trình duyệt điện thoại bằng React + Wasmoon Lua + gateway, dùng FreeKill C++/Lua làm nguồn sự thật. Scope hiện tại là `new_heg_mode` với 14 package; không port luật server sang TypeScript và không trộn TQSShop.

## Handoff ngắn

- **Render → Oracle replacement:** [`tqs-mobile-candidate`](https://tqs-mobile-candidate.onrender.com) **Live** từ deployment [`dep-db8pmpcs728c73akbvr0`](https://dashboard.render.com/web/srv-db63aclckfvc73bvrli0/deploys/dep-db8pmpcs728c73akbvr0), commit `32ac4be2`. Public health `200 / ok`, HTML SHA-256 `591c51f15482d78267b3db4c48b150d20747d5bf83631f01c335e7799e114012`, manifest `5.279` file, runtime MD5 `29653b06f1db4a1cece2941f79cbe648`, bundle `ce342f067f61796e`; Oracle QA revision hiện hành `a6c47982d6f0140eaa2869cbaa6c5a780d688396`, package `5b45411afa767898860e81ee8a8307b52e1ad936b0b3bc67ee08839257be9ef2`, catalog `945b063fa44264a058a41141d3324275b48690018bdd4b4f23be97961ca76bbe`, package isolated at `qa_packages/tqs_qa`. Ký Ly/Jilix `TargetConfirmed` + lần `DamageInflicted` thứ hai chủ/phó đã PASS trên QA current; các family khác vẫn ghi theo revision bounded của từng evidence. Đây vẫn là candidate, chưa official.
- **Production reconnect policy:** template production đã đặt `tempBanTime: 5`; source bootstrap có patch xác thực mật khẩu trước khi áp temp-ban, cho phép reconnect tài khoản còn player trong room và dời capacity gate sau xác thực. QA replacement trước CP16 vẫn dùng `tempBanTime=0`. Đã bắt đầu chuyển replacement sang source-built production nhưng build trên VM 1 GB bị nghẽn ở C++ compile trước khi đổi symlink; service hiện đang tạm dừng để phục hồi. Chưa claim guard native active cho tới khi reboot/recovery, binary hash và reconnect thật PASS.
- **Ước tính tiến độ:** mục tiêu candidate mobile để người dùng smoke test vẫn khoảng **65%**, còn khoảng **35%** đến mốc public/official. CP15 đã khóa thêm Ký Ly/Jilix `TargetConfirmed` + lần `DamageInflicted` thứ hai ở cả chủ/phó và sửa source ownership slot; exhaustive rule parity vẫn xa hơn: native-local direct effect evidence **29/607** cặp (**16/53** event kinds). Không quy đổi 29/607 thành tỷ lệ hoàn thiện toàn goal; corpus 51 run identity cũ chỉ giữ làm historical reference.
- **Điều kiện người dùng nêu:** native chỉ coi skill fake là hoạt động khi đã prelight; `SkillEffect` gọi `revealBySkillName` trước effect. CP15 đã chứng minh Ký Ly/Jilix khi cả hai slot còn ẩn: Sát đỏ tạo `TargetConfirmed`, effect lặp Sát, `DamageInflicted` lần hai bị ngăn và `removeGeneral` loại đúng main/deputy; PASS cả main [`cp08-hidden-jilix-multiplayer-live-1792121835568.json`](../scratch/evidence/cp08-hidden-jilix-multiplayer-live-1792121835568.json) và deputy [`cp08-hidden-jilix-deputy-multiplayer-live-1792121858243.json`](../scratch/evidence/cp08-hidden-jilix-deputy-multiplayer-live-1792121858243.json). Đây là source-law fix trong `HegUtil.inGeneralSkills`, không phải workaround React; `runtime/flist.txt` đã được refresh cùng identity. CP14 Phụ Âm và CP13 Chế Man vẫn được giữ theo revision QA đã ghi; đây là bounded evidence, chưa phải full effect parity.
- **React boundary:** fake/regular skill projection, privacy theo Self, prelight wire `prelight,<skill>,true|false`, request/reply và reconnect duplicate đã được kiểm chứng; React không tự quyết damage, reveal, card, phe hoặc winner.
- **Coverage hiện hành:** source projection/lifecycle `520/520`, slot route `155.168/155.168`, prelight sync `403/403`; inventory có `607` cặp trigger `skill × event` non-delay trên `53` event kinds, native-local effect evidence hiện **29/607** trên **16/53** event kinds. Hosted current đã PASS Ký Ly/Jilix, Ân Oán và Phụ Âm chủ/phó, nhưng không được tính vào native-local ratio. CP13 hosted proof Chế Man `DamageCaused` ở cả chủ/phó thuộc QA package trước refresh; các batch hidden-trigger khác dùng revision QA trước và được tách khỏi current package proof. Exhaustive matrix vẫn mở.
- **Native probe lịch sử:** lần thử Thiên Đố trước khi thay VM đã vào được phòng nhưng host chưa có gate deterministic (`nativeQaGateSeen=false`), nên dừng trước gameplay. Evidence [`reconnect-failure-1792066870927.json`](../scratch/evidence/reconnect-failure-1792066870927.json) chỉ là diagnostic cũ, không dùng để kết luận `FinishJudge` sai. Replacement hiện đã cài/verify `tqs_qa` và đã có native gate PASS cho bộ bounded nêu trên. `fazheng-enyuan` broad contract vẫn là scope riêng cần hoàn thiện; không được dùng nó để phủ định hidden Ân Oán `TargetConfirmed` đã PASS.
- **Gate vừa chạy PASS:** `npm --prefix game/web run test:qa-server-contract` **44/44**, `test:live-config` **2/2**, `test:release` **4/4**, `audit:hidden-skills`, `test:hidden-rule-contract`, `audit:skill-activation`, `audit:native-callers`, typecheck và `audit:hidden-effects` (**29/607**, **16/53**) đều PASS. Đây là bằng chứng browser/Wasmoon/React, native-local, Oracle bounded và Render → Oracle bounded; không thay thế full effect matrix.
- **Fresh Render → Oracle CP15 probe:** deployment `dep-db8pmpcs728c73akbvr0` build từ `32ac4be2`; gateway :10000 → `161.33.209.212:9527`, public HTML và runtime MD5 cùng identity `591c51f1…` / `29653b06…`, bundle `ce342f067f61796e`. Hidden Ký Ly/Jilix main/deputy, GameOver và clean disconnect đều PASS trên QA revision `a6c47982…`; bundle `util.lua` byte SHA-256 `60d5f00d…` khớp local. Evidence chi tiết nằm trong audit canonical. Đây là hosted bounded, chưa là official.
- **Fresh native-local hidden-yiji:** trên C++/Lua thật, source pin `b8a2ad4…`, runtime flist MD5 `ca33a1e8…`, QA package revision `b412f91b…` nguyên trạng, đã PASS đủ `positive`/`negative`/`skip`: prelight + invoke mở Quách Gia trước Di Kế và chuyển 2 lá; không prelight không hỏi/không mở; prelight nhưng bỏ qua không mở/không effect. Evidence chi tiết và hash chỉ giữ ở audit canonical; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-tiandu:** cùng runtime/package identity đã PASS cả main/deputy: `room:judge` → `FinishJudge` → reveal đúng slot → lấy lá đang ở `Card.Processing`; harness đã loại assertion generic `PlayCard` không áp dụng cho trigger này. Evidence chi tiết chỉ giữ ở audit canonical; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-fanjian:** cùng runtime/package identity đã PASS cả main/deputy: `PlayCard` khi Chu Du còn úp → reveal đúng slot → tặng Đào → mục tiêu chọn “Mất 1 máu” → GameOver/cleanup sạch. Harness được mở rộng để nhận đúng nhãn bản dịch hiện hành; đây là NATIVE-LOCAL/unpinned, không phải Render/Oracle.
- **Fresh native-local hidden-kuanggu:** cùng runtime/package identity `3d88cece…` + QA package `eb4e9570…` đã PASS cả main [`1792072481881`](../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792072481881.json) và deputy [`1792072494326`](../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792072494326.json): Ngụy Diên còn úp, đã prelight, dùng Sát cự ly 1; native đánh dấu `BeforeHpChanged`, chạy `Damage`, mở đúng chủ/phó trước `SkillEffect` và rút 1 lá. Đây là bằng chứng trực tiếp cho điều kiện “tướng úp nhưng đủ điều kiện vẫn kích hoạt”, vẫn là NATIVE-LOCAL/unpinned.
- **Fresh native-local hidden-liegong:** runtime `flist.txt` MD5 `4ab95597…`, QA revision `a3618958…`, package SHA-256 `6b8e5b7c…` đã PASS cả main [`1792073569775`](../scratch/evidence/cp08-hidden-liegong-multiplayer-live-1792073569775.json) và deputy [`1792073583047`](../scratch/evidence/cp08-hidden-liegong-deputy-multiplayer-live-1792073583047.json): Hoàng Trung còn úp nhưng đã prelight, dùng Sát thỏa predicate HP; native phát `TargetSpecified`, mở đúng chủ/phó trước `SkillEffect`, nhận lựa chọn `damage +1` và gây đúng 2 damage. Đây là bằng chứng trực tiếp cho một cặp TargetSpecified mới, vẫn là NATIVE-LOCAL/unpinned.
- **Tích hợp toàn diện 100% từ điển chính thức (UI-01):** Đã nạp thành công 13.031 mục bản dịch tiếng Việt do người dùng cung cấp từ `ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv`. Đã qua khâu kiểm tra tự động: 0 ô trống, 0 chữ Hán sót lại, 0 lỗi placeholder, 0 lỗi thẻ HTML; sửa 152 điểm lỗi máy dịch (như `Người đóa` -> `Họa`, `Lá Phi` -> `Trương Phi`, `Điển là` -> `Điển Vi`, `Lưu lượt` -> `Lưu Hiệp`, `vàng Cái` -> `Hoàng Cái`, v.v.). Biên dịch sang `officialTranslations.json`, nạp vào `VI_ADDITIONS` trong `vietnamese.ts` và cập nhật đồng bộ `ZH_CN_ORIGINAL_CATALOG.json`, `ZH_CN_ORIGINAL_CATALOG.md`. Toàn bộ `test:store` (40/40), `test:vietnamese` (4/4), `test:card-display` (12/12), `test:e2e` (20/20), `test:e2e:lua` (63/63) và `npm run build` đều PASS 100%.
- **Lua ABI:** launcher và installer đã fail-closed với Lua 5.5, chọn Lua 5.4 và preflight `socket`/`lfs`; native-local và Oracle replacement đều verify PASS. Oracle đang chạy Lua 5.4.8; old VM chưa cập nhật.
- **Oracle/SSH:** hồ sơ vận hành đã được lưu tập trung ở [`deploy/freekill-native/README.md`](../deploy/freekill-native/README.md). VM cũ `freekill-hegemony` (`168.110.36.224`) chưa xoá vì replacement chưa khôi phục sau build. Replacement `freekill-hegemony-qa` (`161.33.209.212`, alias `tqs-native-qa-replacement`) đã PASS trước CP16 với Lua 5.4.8, 14/14 package pin, QA revision `a6c47982…`, runtime MD5 `29653b06…`; hiện cần OCI reboot/recovery hoặc SSH tự hồi phục, sau đó mới source-build production `tempBanTime=5` và kiểm reconnect. Không xoá VM cũ trước khi replacement health/port/reconnect/rollback evidence PASS.
- **Oracle/hosted hidden-trigger QA:** Ký Ly/Jilix `TargetConfirmed` + lần `DamageInflicted` thứ hai chủ/phó đã PASS trên current QA revision `a6c47982…`; Ân Oán và Phụ Âm `TargetConfirmed` cũng có current proof. CP13 pre-refresh package proof là Chế Man `DamageCaused` chủ/phó trên Render → Oracle. Native QA gate chỉ chuẩn bị prelight/fixture; các cổng source và lá Sát/target thật đã được quan sát. CP09–CP14 proof của các family khác thuộc revision QA trước và được giữ làm bounded reference. Full effect matrix, native interaction matrix và official release vẫn mở.

## Evidence và trạng thái ticket

| Tầng | Trạng thái | Giới hạn phải giữ rõ |
| --- | --- | --- |
| Source/runtime contract | PASS | Code/catalog/caller hợp lệ trong 14 package; không chứng minh effect đã chạy. |
| React/Wasmoon/local | PASS | Projection, privacy, request/reply, dialog và lifecycle đã có regression; fixture không thay thế C++. |
| NATIVE-LOCAL hidden skill | PASS bounded | Các case Di Kế, staged trigger add-on, Cuồng Cốt, Liệt Cung, Ách Tuyệt, Độc Phu và Phản Gián main/deputy đã chạy C++/Lua thật trong runtime cô lập; không gộp thành hosted/official. |
| Oracle QA hidden-trigger | PASS bounded current / historical corpus separated | Replacement VM current identity, Lua 5.4.8, isolated QA package; CP15 Ký Ly/Jilix `TargetConfirmed` + second `DamageInflicted` main/deputy trên Render → Oracle PASS với revision `a6c47982…`, runtime MD5 `29653b06…` và `tempBanTime=0`. CP14 Phụ Âm vẫn current proof; CP13 Chế Man thuộc package trước refresh; batch CP09–CP12 thuộc revision QA trước. Full matrix và official release còn mở. |
| LIVE candidate | PASS bounded | Login/lobby/room/bot/GameOver và CP96 asset probe đã có; chưa là full rule parity. |
| Exhaustive hidden effects | OPEN | `29/607` cặp native-local trên 16 event kinds; `DamageCaused` còn 12/16 cặp chưa có evidence; cần scenario main/deputy cho event groups còn lại. |
| PLAYABLE_MOBILE / official | FALSE / OPEN | Còn live interaction matrix, rescue/wild/founding, release operations và sign-off. |

## Việc còn mở theo thứ tự

1. CP15 Ký Ly/Jilix chủ/phó đã PASS trên current replacement identity (`29653b06…`, QA `a6c47982…`, package `5b45411a…`, catalog `945b063f…`) và vẫn giữ `tempBanTime=0` ở mốc evidence. Render artifact là deployment `dep-db8pmpcs728c73akbvr0`, commit `32ac4be2`; `runtime/flist.txt` đã được cập nhật đồng bộ với `util.lua`. CP16 production reconnect mới chỉ có source patch/config và backup PASS; source compile chưa hoàn thành, service cần recovery. Việc kế tiếp bắt buộc là khôi phục replacement, build giới hạn tài nguyên, verify binary/config/reconnect thật rồi mới xoá VM cũ; sau đó tiếp tục native interaction matrix/rescue/wild/founding và hidden-effect family còn thiếu.
2. Dùng [`audit:hidden-effects`](../game/web/scripts/hidden-effect-audit.ts) làm checklist dựng native scenario main/deputy cho `TargetSpecified` còn lại, `TargetConfirmed`, `Damage`, `DamageCaused` còn 12 cặp, `CardUseFinished`, `EnterDying`, rescue/retrial, phase/death/round và package-specific hooks.
3. Hoàn tất live native interaction matrix: CardChosen, Poxi, CardsAndChoice, ArrangeCards, AG, MoveCardInBoard, SkillInvoke, CustomDialog; kiểm cancel/expiry/cleanup/reconnect theo semantics từng request.
4. Mở smoke test candidate cho người dùng trên deployment Live hiện tại; ghi lại lỗi theo đúng tầng (UI/bridge/native/harness). Chỉ cập nhật release/`PLAYABLE_MOBILE` khi evidence đúng tầng đã có.

## Nguyên tắc phiên sau

- `SOURCE` = code tồn tại; `LOCAL` = fixture/VM; `NATIVE-LOCAL` = browser + C++ thật trong runtime cô lập; `LIVE` = candidate/hosted release. Không trộn các tầng.
- Không port luật gốc sang React, không auto-select để vượt request chưa hỗ trợ, không suy ra full parity từ số skill/file/test.
- Bảo toàn mọi thay đổi dirty hiện có; không reset/clean/checkout ghi đè hoặc commit thay người dùng.
- Sau mốc đáng kể: cập nhật [`CODEX_PLAN.md`](CODEX_PLAN.md), tài liệu canonical nếu cần, rồi chạy `npm run codex:checkpoint`.

## Bước tiếp theo có thể chạy ngay

Giữ Render candidate và Oracle replacement theo cùng web/runtime identity; hiện runtime MD5 `29653b06f1db4a1cece2941f79cbe648`, bundle `ce342f067f61796e`, QA revision `a6c47982d6f0140eaa2869cbaa6c5a780d688396`, package `5b45411afa767898860e81ee8a8307b52e1ad936b0b3bc67ee08839257be9ef2`, catalog `945b063fa44264a058a41141d3324275b48690018bdd4b4f23be97961ca76bbe`, deployment `dep-db8pmpcs728c73akbvr0`. QA replacement vẫn `tempBanTime=0`; production template là 5 nhưng native guard chưa active trên VM cũ. Render artifact là commit `32ac4be2`; package/runtime identity đã được health/manifest/login/hidden-Jilix main/deputy probe. Song song tiếp tục native matrix theo các event group còn thiếu. Không đánh dấu goal hoàn tất khi exhaustive effect matrix, interaction matrix hoặc official release còn mở.

## Ảnh chụp Git (tự động)

<!-- CODEX_SNAPSHOT_START -->
- Ghi lúc: 2026-10-16T03:41:17.634Z (UTC).
- Nhánh: `codex/cp89-render-current` · HEAD: `38dda9db25a7`.
- File thay đổi hiển thị: 0 (đã ẩn tên file có thể nhạy cảm và không tính chính tài liệu này).

```text
(không có thay đổi ngoài CODEX_STATE.md)
```

Ba commit gần nhất:

```text
38dda9db docs: record CP15 hidden Jilix parity
32ac4be2 fix: refresh runtime identity for hidden skill patch
a6c47982 fix: resolve hidden general skill ownership
```

> Ảnh chụp này chỉ phản ánh metadata Git lúc chạy lệnh. Để biết trạng thái **ngay bây giờ**, chạy `git status --short`; không suy diễn PASS từ danh sách file.
<!-- CODEX_SNAPSHOT_END -->
