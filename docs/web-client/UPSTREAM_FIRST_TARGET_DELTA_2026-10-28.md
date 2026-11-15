# Upstream-first — Hegemony target delta đã xác minh ngày 28/10/2026

## Identity

- Remote: `https://gitee.com/qsgs-fans/hegemony.git`
- Branch được đọc: `refs/heads/master`
- SHA hiện tại quan sát qua `git ls-remote`: `e8d93acd34a357f96b0105aef7d661708c211626`
- Parent trực tiếp: `d069cd1f5c6df8d93af0ea101b82a5bed2781f01`
- Commit date: `2026-10-26T21:31:18+08:00`
- Subject: `fix`
- Mốc khảo sát cũ `d069cd1…` **không còn là HEAD mới nhất** và chỉ được giữ làm parent/điểm so sánh.

Đã xác minh bằng `git ls-remote` và clone tạm `--filter=blob:none --depth=2`, không checkout hoặc cập nhật bất kỳ worktree đang dirty nào. Clone tạm cho phép đọc tree/diff của parent và target; không dùng floating `master` làm source nghiệm thu.

## Delta từ pin hiện tại → target (phạm vi phải nghiệm thu)

Pin Hegemony hiện tại trong `deploy/freekill-native/versions.env` là `d616978ad2a53055f5815f3ae19f2d2b239862e0`, không phải parent trực tiếp `d069cd1…`. Vì vậy delta thực tế của candidate là `d616978… → e8d93a…`, gồm **8 commit, 204 tệp, +4.893/-1.464 dòng**: **113 tệp source text** (Lua/QML/JS/JSON/Markdown) và **91 tệp binary/media**. Con số 14 tệp dưới đây chỉ là commit cuối `d069cd1… → e8d93a…`, không đại diện cho toàn bộ nâng cấp từ pin đang chạy.

Candidate cô lập đã được dựng với Hegemony `e8d93a…` và core API floor `3c40e0f8…`; smoke Wasmoon trên đúng candidate mount **PASS** (5.588 file, 2.338 generals, 4.971 skills, 264 card types, 17 game modes, có `new_heg_mode`). Đây chỉ là source/client boot proof, chưa là native/gameplay/privacy/reconnect acceptance. Retarget evidence đầy đủ nằm ở `scratch/evidence/upstream-first-a-20261028/retarget-report.{json,md}`.

## Delta parent trực tiếp → target (14 tệp; chỉ là phần fix cuối)

Commit cuối của target thay đổi **14 file Lua**, tổng cộng **55 dòng thêm / 81 dòng xóa**:

| File | Nội dung cần đánh giá | Mức ưu tiên | Trạng thái |
| --- | --- | --- | --- |
| `pkg/hegemony_nos/skills/wenji.lua` | Chuyển cấm đáp lại sang `UseCardData:setDisresponsive()` | P1 | Chưa port; cần core API + native effect |
| `pkg/jin_zqdl/skills/chujue.lua` | Cấm đáp lại theo từng mục tiêu qua API mới | P1 | Chưa port; cần native effect |
| `pkg/lord_ex/skills/qiance.lua` | Cấm đáp lại mục tiêu đại thế lực qua API mới | P1 | Candidate bounded native PASS; port/chốt identity còn mở |
| `pkg/lord_ex/skills/wenji.lua` | Cấm đáp lại toàn bàn qua API mới | P1 | Chưa port; cần core default semantics |
| `pkg/lord_ex/skills/xishe.lua` | Đổi event sang `CardUsing`, áp cấm đáp lại theo mục tiêu | P1 | Chưa port; cần kiểm lifecycle |
| `pkg/mobile_heg/skills/bawei.lua` | Cấm đáp lại các mục tiêu đã gây damage trong round | P1 | Chưa port; cần native effect |
| `pkg/mobile_heg/skills/fengshi.lua` | Cấm đáp lại toàn bàn qua API mới | P1 | Chưa port; cần core default semantics |
| `pkg/power/skills/tieqi.lua` | Cấm đáp lại mục tiêu sau phán xét | P1 | Chưa port; cần native effect |
| `pkg/standard/skills/jianchu.lua` | Cấm đáp lại mục tiêu khi bỏ trang bị | P1 | Chưa port; cần native effect |
| `pkg/standard/skills/tieqi.lua` | Cấm đáp lại mục tiêu sau phán xét | P1 | Chưa port; cần native effect |
| `pkg/strategic_advantage/skills/halberd.lua` | Gộp active skill vào skill phụ, đổi thêm mục tiêu/nullify | P1 | Chưa port; cần registry + target/nullify test |
| `pkg/strategic_advantage/skills/halberd_active.lua` | Xóa file, logic chuyển vào `halberd.lua` | P1 | Chưa port; cần kiểm không double-register |
| `pkg/tenyear_heg/skills/zhente.lua` | Dùng `AimData:setNullified(target)` và `getTableMark` | P1 | Chưa port; cần native target-nullify test |
| `pkg/transformation/skills/xiongsuan.lua` | Sửa chọn một lá bài từ `#selected == 1` thành `#selected == 0` | P0 | Candidate bounded native PASS; compatibility retarget còn phải port/chốt identity |

## Compatibility finding

Hegemony target dùng `UseCardData:setDisresponsive()` trong các event `fk.CardUsing`. Core runtime hiện hành tại `ade837d74c616dbd2d169934b0bec4a5a5dc0a85` chỉ có các helper tương ứng trên `AimData`/`CardEffectData`, chưa có `UseCardData:setDisresponsive`. Core remote commit `3c40e0f8dc54608a3b862c0cfcad80e5e61f5e02` đã được đọc trực tiếp trong clone lọc; source có phương thức `UseCardData:setDisresponsive(target)` với mặc định là toàn bộ người chơi.

Vì vậy, Hegemony `e8d93a…` không thể được port độc lập trên toàn bộ dependency pin hiện tại. `3c40e0f8…` là **API floor tối thiểu provisional**, không phải lệnh đổi pin. Core master tại thời điểm kiểm tra là `19200891f8120f557c1eb2b5a724936a0e13f4e4`; không tự nâng tới master khi chưa audit thêm delta và kiểm native.

`AimData:setNullified(target)` và `CardEffectData:setNullified(target)` đã có trong core runtime hiện tại; thay đổi `zhente.lua` vẫn phải chạy effect test để chứng minh đúng lifecycle, không suy ra tương thích chỉ từ tên API. Thay đổi `xiongsuan.lua` là lỗi chọn bài trực tiếp trong mode, phải có test P0 riêng.

## Bounded proof — `delta-xiongsuan` (29/10/2026)

Candidate private với delayed-link đã đạt native/browser bounded PASS: hai account qua lobby/room/StartGame/cặp tướng/privacy DOM; native `AskForSkillInvoke` → `AskForUseActiveSkill` → `AskForChoices`; `#selected == 0`, discard đúng một Jink, damage `1`, draw `3`, reset limited skill và `GameOver` trên 2/2 client, `errors=[]`. Evidence sanitized: `scratch/evidence/cp08-delta-xiongsuan-multiplayer-live-1793256712388.json`.

Lượt này phát hiện compatibility gap riêng của upstream `xiongsuan.lua`: target ghi mark bằng `xiongsuan-turn` nhưng đọc alias `_xiongsuan-turn`, trong khi candidate core chỉ cung cấp mark trực tiếp. Private candidate dùng patch tối thiểu `player:getTableMark("xiongsuan-turn")`; patch chưa được port vào production source/pin. Vì vậy baseline public flist chưa patch là `2e453ed37f894bed95c0b80f99bd1809`, còn candidate sau retarget có identity `02743247224e06c89efc5c05a9b97634`. `xiongyi` chỉ được thêm trong server-only QA fixture để ép `AskForChoices`, không phải production behavior. Đây là **bounded_native_pass_candidate_retarget_open**, chưa phải release acceptance.

## Bounded proof — `delta-wenji` (29/10/2026)

Candidate runtime giữ MD5 `2e453ed37f894bed95c0b80f99bd1809` với upstream Hegemony target `e8d93acd34a357f96b0105aef7d661708c211626`, QA source revision `c74e6ff8c3654a64447b6a66642ee1cf1d98af44` và package SHA `20cb23a07e7d31b42456d6d29ba69305e1c81b5c8a31b37a13a49e855cc37eb1`. Hai account thật và hai Chrome mobile viewport đã vượt auth/lobby/room/StartGame/general-pair/privacy DOM; upstream `nos_heg__wenji` thực sự chọn recipient, nhận Slash từ target, dùng Slash lên target, đặt disresponsive cho CardUsing, giữ Jink trong hand, làm target mất 1 HP và đạt `GameOver` trên 2/2 client. Không có `AskForResponseCard`, `errors=[]`, runner exit `0`. Evidence sanitized: `scratch/evidence/cp08-delta-wenji-multiplayer-live-1793263517792.json`.

Để đóng đúng contract này, QA source đã gắn lại **skill thật** `nos_heg__wenji` vào room logic thay vì chỉ fake-skill trên roster; launcher candidate có fallback kiểm listener `/proc/net` cho image thiếu `ss`; runner đọc prompt hiện hành và chọn card bằng accessible name `Slash` để không nhầm Jink. Contract suite `54/54`, web typecheck, `typecheck:all`, shell syntax và `git diff --check` đều PASS sau mốc. Đây là bounded candidate proof, không phải physical-device sign-off/release; production/current/DB/KV/DNS/service không bị chạm.

## Bounded proof — `delta-qiance` (29/10/2026)

Candidate runtime `2e453ed37f894bed95c0b80f99bd1809` với upstream Hegemony `e8d93acd34a357f96b0105aef7d661708c211626`, QA source revision `c74e6ff8c3654a64447b6a66642ee1cf1d98af44` và package `tqs_qa` đã đạt native/browser bounded PASS trên hai account, hai Chrome mobile viewport, room/StartGame/general-pair/privacy DOM và native Trust. Scenario dùng skill thật `ld__qiance`: actor dùng Duel lên target cùng đại thế lực; native log xác nhận `card_using=true`, `skill_effect=true`, `response_blocked=true`, `target_slash_retained=true`, damage `1`, `AskForResponseCard=0` và `GameOver` trên 2/2 client, `errors=[]`, runner exit `0`. Evidence sanitized: `scratch/evidence/cp08-delta-qiance-multiplayer-live-1793284904008.json`.

Package identity được ghi trong evidence với manifest SHA-256 `9c1ae4c0041e02d9a37b800dc27b1442753bf2f517629cdf440873a7c14b64a6`, catalog SHA-256 `51bcd406648f82ac3d63663517676bd845e485bbe4715a5c31db06fa33b05c41` và package SHA-256 `9999ac8e5c976b55070c786e0d21136866b7213543aeb04dfb746a4e9cc0dbca`. Native build expose `room:askToUseRealCard()` thành `AskForUseActiveSkill`, nên runner chọn Duel/target bằng semantic branch; đây là QA contract correction, không phải thay đổi production. Candidate qiance đã cleanup; production/current/DB/KV/DNS/service không bị chạm. Status: **bounded_native_pass_candidate_open**, còn 11 target-delta scenario và full release acceptance.

## Bounded proof — `delta-jianchu` (29/10/2026)

Candidate private với upstream Hegemony `e8d93acd34a357f96b0105aef7d661708c211626`, QA source revision `c74e6ff8c3654a64447b6a66642ee1cf1d98af44` và runtime MD5 `f9ec603e2d68a5e45bf1b1b6592491d9` đã đạt native/browser bounded PASS trên hai account, hai Chrome mobile viewport, room/StartGame/general-pair/privacy DOM và native QA gate. Scenario dùng skill thật `hs__pangde`/`jianchu`: actor dùng Slash lên target có equipment, equipment branch chạy qua `AskForCardChosen`, equipment vào discard, target mất `1` HP, Jink vẫn ở hand và `setDisresponsive(target)` làm `AskForResponseCard=0`; GameOver trên **2/2** client, `errors=[]`, runner exit `0`. Evidence sanitized: `scratch/evidence/cp08-delta-jianchu-multiplayer-live-1793286187399.json`.

Evidence ghi `gateReply=true`, `useReply=true`, `invokeReply=true`, `cardReply=true`, `responseRequests=0`; native log ghi `equipment_branch=true`, `response_blocked=true`, `target_jink_retained=true`, `damage=1`. QA manifest/catalog/package SHA-256 lần lượt là `2dd237a7645ed31b7b65142138adc40f14cba7561372c87780025091f8e53243`, `9c93f45c978289b7c75f233ae606acf0a14481d2650dbd209cdbed43c72fc626`, `4b31baa6c3d5a232f5969af8d302be3a6d67a5c32f71c5821f2c4a3412bd348f`; runtime SmartAI/room/QA-overlay provenance được lưu trong evidence. Official QA installer/verifier không chạy được vì image thiếu `sqlite3`; package bounded được dựng bằng shared hash/manifest helper và package-db read-only check. Đây là **bounded_native_pass_candidate_open**, chưa phải device sign-off hoặc release acceptance; QA container đã dừng, ports `19728/9000` đóng, production/current/DB/KV/DNS/service không bị chạm.

## Quyết định gate

- Khóa candidate target tạm thời ở full SHA `e8d93acd34a357f96b0105aef7d661708c211626`, parent đã biết rõ, nhưng **chưa cập nhật `versions.env`**.
- Retarget phải dùng đúng baseline pin `d616978…`, không chỉ dùng delta parent `d069cd1…`; ma trận U1/U2 cũ được xây theo snapshot lịch sử và không được coi là đã bao phủ 8 commit/204 tệp mới.
- Bản quét source text hiện khớp toàn bộ **43/43** dòng inventory lịch sử, phát hiện thêm một runtime overlay chưa có hồ sơ (`hegemony/pkg/standard/skills/sijian.lua`), **3 source omission** trong preserved runtime tree (README/QML) và **2 QML bị target xóa**; có **5 conflict** cần review hunk ba phía.
- Chỉ sau khi chọn exact core SHA (ít nhất đạt API floor), dựng source candidate cô lập và chạy native proof mới được mở U3.
- Không thay `current`, binary, runtime live, DB, KV, DNS, service hoặc production web trong bước này.

Evidence tĩnh liên quan: `scratch/evidence/upstream-u1u2-20261027/overlay-impact-matrix.json`, `scratch/evidence/upstream-u1u2-20261027/three-way-hunk-review.json`, `scratch/evidence/upstream-u0-20261028/` và snapshot Phase A cùng ngày.
