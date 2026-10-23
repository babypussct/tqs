# SMARTAI Prompt 4 — inventory, ưu tiên và ba nhóm kỹ năng đã triển khai

## Final bounded AI closure — downstream native matrix 18/18 PASS trên identity cuối (22/10/2026)

Đã đóng gate behavioral downstream cuối cho cải tiến AI Prompt 4 sau khi `huoji:addAI` thay đổi hành vi. Ma trận `ai-trace` cố định seed `1780420130` và roster bốn ghế (hai account browser thật + hai native SmartAI BOT) chạy đủ **18/18 profile**. Tất cả runner EXIT `0`; mỗi run có hai live trace, mỗi trace đúng một `GameOver`, tổng `36/36` client observations; evidence đều `result=PASS` và `errors=[]`.

Artifact metadata-only đầy đủ là [`SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_FINAL_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_FINAL_2026-10-22.json). Các profile được lưu bằng evidence `cp39/cp40/cp41` và `cp50..cp64`; mỗi native summary đi qua `Room:handleUseCardReply` → `Room:useSkill` → `SkillEffect`, đạt `attempted=1`, `accepted=1`, `handled=1`, `skill_effects=4`, `errors=0`, `resource_retarget_error=0`, `nested_invalid=0`, `nested_metric_errors=0`. `beizhu` có `nested_fallback=1` vì oracle profile khai báo rõ `AskForSkillInvoke=1/1/0`; fallback đó được kiểm đúng, không bị coi là lỗi.

Identity cuối: runtime `flist.txt` MD5 `96a26aff51298c3615c9ea506109c4f4`; QA revision `43c306eafae8570ab6f71185e0a37979321e15d3`; package tree `2dac53e8c815ca29effc2087979223e688a720cc3b1718e541b045b926643308`; native binary SHA-256 `080b2d14e1e7840275ae431ae2474c679ff904a3351baf242c188d78c5bcf14b`; browser dist SHA-256 `029f742b3e2e0afe03bc02b3b8ec7a9a7cb15b42dfd4b16fb2935918f079ba54`; SmartAI/room/QA overlay lần lượt `b76f87a8…`, `f71e71a7…`, `867db423…` như artifact. Production source Huoji không bị thay đổi trong các lượt fixture QA.

QA corrections cần ghi nhớ: Huoji remap theo luật đỏ/non-equipment thay vì trueName; chỉ thêm resource profile sau khi thu đủ privacy/legality matrix; Wusheng dùng native target tách actor, cấp Jink phía target và kỳ vọng đúng một lá vật liệu ViewAs. Đây đều là QA overlay/fixture/oracle, không phải thay đổi luật/effect production.

Focused verification sau run: SmartAI **12/12**, Prompt 4 **5/5**, QA server contract **51/51**, `npm run typecheck:all`, Lua syntax, package/manifest/flist/evidence identity, JSON parse và `git diff --check` đều **PASS**. QA native/tunnel/gateway đã dừng; production ports `9000/9527` vẫn hoạt động. Đây là bounded AI closure, không phải device, release, canary, rollback hay production sign-off.

## Current request-safety checkpoint — CP99 baseline paired with CP98 (22/10/2026)

Đã chạy thêm baseline full-match bằng cờ QA-only `tqsPrompt4Baseline=true` trong runtime tạm, cùng scenario `general-pair-match-mixed-a`, seed `1780421000` và package/runtime identity với CP98 candidate. Cả hai run đều EXIT `0`, tới GameOver, browser errors `0`, public BOT skill log `0`, và sau run đã restore cờ về `false`, dọn process/port/symlink.

Candidate CP98 ghi `143/76/67/0/67`; baseline CP99 ghi `181/100/81/0/78` theo `total/accepted/fallback/invalid/noDecision`. Mọi command bucket của cả hai nhánh đều `invalid=0`. Baseline no-strategy/unsupported là hành vi kỳ vọng vì cờ baseline cố ý ẩn 18 Prompt 4 strategy; hai full match không được coi là matched request-state causal replay vì state gameplay có thể phân kỳ sau quyết định đầu tiên.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CP99_BASELINE_MATCH_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CP99_BASELINE_MATCH_2026-10-22.json). Kết luận vẫn là bounded zero-invalid PASS, nhưng P0 matched/aggregate safety còn OPEN, `REQUEST_SAFETY_OPEN`, production **NO-GO**. Production thay đổi vẫn là **AI/request adapter dùng chung + SmartAI dispatcher + từng `addAI` hunk**, không phải Codex `SKILL.md` hay luật/effect skill; QA baseline/fixture/profile/sanitizer tách riêng. Khi upstream update, port theo hunk và giữ QA overlay riêng.

Attempt baseline `ai-trace` cùng identity được **loại khỏi gate**: runner EXIT `1` vì không quan sát GameOver ở mọi client trước deadline; chỉ 5 deterministic trace decisions xuất hiện trước soft-cleanup. Đây là giới hạn của driver khi baseline tắt strategy, không phải bằng chứng candidate/baseline matched; attempt và lý do loại được ghi trong `excludedAttempts` của artifact.

## Current request-safety checkpoint — CP98 four-trajectory matrix (22/10/2026)

Candidate `cp98` đã chạy bốn full-match trajectory `general-pair-match-mixed-a/b/c/d` trên cùng identity: **4/4 EXIT 0**, GameOver `4/4`, browser errors `0`, public BOT skill logs `0`. Aggregate là `655/327/328/0/328` theo `total/accepted/fallback/invalid/noDecision`; reasons `no_decision=203`, `no_strategy=125`. Đây là bằng chứng bounded rằng các trajectory hiện tại không phát invalid reply, không phải full legal denominator, tactical-quality, downstream-effect, reconnect/device hoặc release proof. Artifact: [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CP98_MATRIX_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CP98_MATRIX_2026-10-22.json).

## Native downstream-effect replay matrix — 13/18 skill PASS bounded, aocai response path PASS (22/10/2026)

Đã mở rộng downstream proof lên **13/18** bằng candidate `cp92`, `ai-trace`, seed `1780420130`, với `aocai` là profile `AskForResponseCard`. Runner native **EXIT 0**; hai account thật + hai native BOT auth/lobby/StartGame/GameOver PASS, browser errors `0`, Prompt 4 trace **18/18 accepted/acted**, `0 fallback`, `0 invalid`, `0 errors`, cleanup PASS.

Điểm quan trọng của ca này là ngữ cảnh luật: `aocai` chỉ được phép khi người sở hữu đang **ngoài lượt**. Native replay đầu tiên `cp90` đã trả một Basic vật lý từ offer và không phát `SkillEffect`; đó là lỗi fixture context, không phải bằng chứng skill chạy. Sau khi QA mô phỏng đúng `room.current ~= actor`, `cp91` đã phát `SkillEffect` nhưng vẫn còn `fake=1`; profile QA tiếp tục promote riêng skill fixture trước downstream replay. `cp92` mới là run được tính: `handled=1`, `executedUseResult=1`, `skill_effects=4`, `fake=0`, `hp_delta=0`, `hand_delta=0`, `target_count=0`, `nested_requests=0`, `nested_fallback=0`, `nested_invalid=0`, `errors=0`.

Đường native đã được xác nhận là `AskForResponseCard` → `Room:handleUseCardReply` → `Room:useSkill` → `SkillEffect` → `RespondCard`/`CardResponding`/`CardRespondFinished`; không dùng physical-card fallback để giả danh `aocai`. `skill_effects=4` vẫn là fan-out của một effect thật qua global QA director, không phải bốn lần kích hoạt. Evidence [`cp92-ai-trace-multiplayer-live-1792620166501.json`](../../scratch/evidence/cp92-ai-trace-multiplayer-live-1792620166501.json) giữ metadata bounded; public audit arrays đều rỗng, không có card/general/hand/target/private payload.

Phần production được kiểm chứng vẫn là **AI/request adapter dùng chung**, không sửa luật/effect của `aocai`, không phải Codex `SKILL.md`. Sửa `requiresOutOfTurn`, fake-skill promotion và response profile chỉ nằm trong QA harness. Khi upstream update, tái sử dụng bằng cách port từng hunk adapter/dispatcher và từng `addAI` theo ngữ cảnh; giữ QA overlay/profile/evidence sanitizer tách riêng, không copy đè nguyên file upstream.

Identity cp92: runtime MD5 `b874e8ec61f6641261993854c5cb02a7`, browser dist SHA `029f742b3e2e0afe03bc02b3b8ec7a9a7cb15b42dfd4b16fb2935918f079ba54`, native binary SHA `de24b9078ae13879e1548387c87af7fc8cd94ebfb1435979a4930b89940980ba`, QA revision `3c4d9cb8a359725674882b803204e0671dfca400`, package SHA `300e0a143b9563108c607ae42428e5866988670919dc770dbb4c24ab8941967f`, manifest SHA `f6da372a330bb0b50f148c9c4255ed69f67e726154a13bcfc592b7cef67cbfba`. Hai attempt `cp90`/`cp91` được ghi failed-excluded trong matrix, không đưa vào clean coverage.

Coverage còn **5/18** skill chưa có clean downstream proof: `hs__longdan`, `hs__luanji`, `huoji`, `kanpo`, `beizhu`. P0/P1/P2/P3/P4/P5 vẫn mở, `REQUEST_SAFETY_OPEN`, production **NO-GO**; không release/commit/push/deploy.

## Native downstream-effect replay matrix — 12/18 skill PASS bounded, choufa card-chosen path PASS (22/10/2026)

Đã mở rộng downstream proof lên **12/18** bằng candidate `cp88`, `ai-trace`, seed `1780420130`, với `choufa` là profile active có target thân thiện và nested `AskForCardChosen`. Runner native EXIT `0`; hai account thật, fixed four-seat roster gồm hai native BOT, StartGame/GameOver, browser errors `0`, Prompt 4 trace **18/18 accepted/acted**, `0 fallback`, `0 invalid`, `0 errors`, cleanup PASS.

Downstream chain đi qua `Room:handleUseCardReply` → `Room:useSkill` → `SkillEffect` → source skill. Native summary ghi `handled=1`, `skill_effects=4`, `fake=0`, `hp_delta=0`, `hand_delta=0`, `target_hp_delta=0`, `target_hand_delta=0`, `target_hand_total_delta=0`, `target_count=1`, `target_policy=native_bot_other`, `actor_policy=native_bot`, `target_retargeted=1`, `errors=0`; nested metric là `AskForCardChosen=1/0/0` theo `total/fallback/invalid`. Đây là card choice của native BOT khác qua Request/SmartAI thật, không phải effect giả hoặc target fixture-only.

Phần production được kiểm chứng vẫn là **AI/request adapter dùng chung**, không sửa luật/effect của `choufa`, không phải Codex `SKILL.md`. Profile, nested telemetry và fixture là QA-only. Khi upstream update, tái sử dụng bằng cách port từng hunk adapter/dispatcher và từng `addAI` theo ngữ cảnh; giữ QA overlay/profile/harness tách riêng, không copy đè nguyên file upstream.

Runner cũng được siết policy evidence: bounded `ai-trace` không cài/đọc public UI audit và chỉ ghi audit metadata rỗng; evidence cp88 không có public GameLog, tên người chơi, card/general text hay private payload. Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_MATRIX_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_MATRIX_2026-10-22.json), [`cp88-ai-trace-multiplayer-live-1792619259945.json`](../../scratch/evidence/cp88-ai-trace-multiplayer-live-1792619259945.json). Artifact cp87 cũ được loại bỏ vì tạo trước sanitizer.

Identity của cp88: runtime MD5 `98724aeb112c1746861551254695b0ca`, browser dist SHA `029f742b3e2e0afe03bc02b3b8ec7a9a7cb15b42dfd4b16fb2935918f079ba54`, QA revision `3c4d9cb8a359725674882b803204e0671dfca400`, package SHA `b60a16143d3f7864b5f5b824749b083658520ce998b0fadb70448a03b9cfa964`, manifest SHA `8098f784f1121fd92991dfb8df2a689bf03e362b0d2a3891b535fc97f566bb17`. Local QA contract **48/48**, `npm run typecheck:all`, Lua 5.4 runtime preflight và `git diff --check` đều PASS; port/symlink QA đã dọn.

Coverage còn **6/18** skill chưa có clean downstream proof: `hs__longdan`, `hs__luanji`, `huoji`, `kanpo`, `aocai`, `beizhu`. P0/P1/P2/P3/P4/P5 vẫn mở, `REQUEST_SAFETY_OPEN`, production **NO-GO**; không release/commit/push/deploy.

## Native downstream-effect replay matrix — 11/18 skill PASS bounded, tiaoxin nested path PASS (22/10/2026)

Đã mở rộng downstream proof từ mười profile lên **11/18** bằng candidate `cp86`, `ai-trace`, seed `1780420130`, với `tiaoxin` là profile active có native forced Slash/Jink path. Runner native EXIT `0`; hai account thật, fixed four-seat roster gồm hai native BOT, StartGame/GameOver, browser errors `0`, public BOT skill log `0`, cleanup PASS.

Request trace vẫn là **18/18 opportunities, 18/18 accepted/acted, 0 fallback, 0 invalid, 0 errors**. Downstream chain đi qua `Room:handleUseCardReply` → `Room:useSkill` → `SkillEffect` → source skill. Với `tiaoxin`, QA giữ actor ở native BOT và target ở native BOT riêng; source skill mở đúng nested request cho forced Slash rồi Jink response. Native summary ghi `handled=1`, `skill_effects=4`, `fake=0`, `hp_delta=0`, `hand_delta=-1`, `target_hp_delta=0`, `target_hand_delta=-1`, `target_hand_total_delta=-1`, `target_count=1`, `target_policy=native_bot_tiaoxin`, `actor_policy=native_bot`, `target_retargeted=1`, `errors=0`; nested metrics là `AskForUseCard=2/0/0`, `AskForResponseCard=0/0/0` theo `total/fallback/invalid`.

Để cp86 đi qua đúng protocol, core change nằm ở AI/request adapter dùng chung: parent ActiveSkill reason không còn bị lưu nhầm thành `ViewAsSkill`, dashboard nhận diện đúng command, và physical-card path chỉ chọn card khớp pattern (đặc biệt Jink). Đây không phải sửa luật/effect của `tiaoxin`, không phải Codex `SKILL.md`; QA profile/telemetry/fixture vẫn là lớp QA-only. Khi upstream thay đổi, port từng hunk theo ngữ cảnh và chạy lại contract/native gates, không copy đè nguyên file.

Lưu ý lifecycle: các lần direct launch trước đó bị loại vì bỏ qua `lua54_prepare`, làm Lua worker EOF sau `GameStart`; cp86 với preflight đúng PASS. QA native phải chạy preflight Lua 5.4, tính flist khi QA symlink còn broken rồi mới bật `qa_packages`. Đây là lỗi harness/lifecycle, không phải kết luận AI.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_MATRIX_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_MATRIX_2026-10-22.json), evidence browser [`cp86-ai-trace-multiplayer-live-1792618440113.json`](../../scratch/evidence/cp86-ai-trace-multiplayer-live-1792618440113.json). Coverage còn **7/18** skill chưa có clean downstream proof; P0/P1/P2/P3/P4/P5 vẫn mở, `REQUEST_SAFETY_OPEN`, production **NO-GO**. Không release/commit/push/deploy.

Regression sau core fix: Lua syntax **PASS**, QA contract **48/48**, SmartAI **11/11**, Prompt 4 **5/5**, observed-reasons **4/4**, request-safety-followup **3/3**, chooser-native-replay **5/5**, `npm run typecheck:all` **PASS**, matrix JSON và `git diff --check` **PASS**. Native QA vẫn chỉ là bounded evidence; chưa phải release/device/canary proof.

## Native downstream-effect replay matrix — 7/18 skill PASS bounded, nested request giữ OPEN (22/10/2026)

Sau mốc `hs__kurou`, QA-only native replay đã mở rộng thành bảy run sạch trên cùng fixture `ai-trace`, seed `1780420130`, public runtime/browser/native identity. Mỗi run vẫn capture **18/18 request opportunities, 18/18 accepted/acted, 0 fallback, 0 invalid, 0 errors**, đi qua `player.ai:makeReply()` thật và native feasibility; cả bảy runner EXIT `0`, GameOver, browser errors `0`, public BOT skill log `0` và cleanup PASS.

Downstream chain thật đã được assert cho `hs__kurou`, `hs__zhiheng`, `hs__qiangxi`, `cunsi`, `dimeng`, `duanfa` và `jijiu`: `Room:handleUseCardReply` → `Room:useSkill` → `SkillEffect` → source skill effect. State evidence gồm HP loss của Khổ Nhục, discard/draw của Chế Hành/Đoạn Phát, damage của Cường Tập, grant `yongjue` + draw của Tồn Tự, hand swap của Kết Minh và hồi máu của Cấp Cứu. `jijiu` cần QA nối `must_targets` của request vào returned ViewAs `useResult`, rồi thực thi useResult thật; không phải fixture-only effect.

Một thử nghiệm `hs__wusheng` bị loại khỏi clean gate: thực thi Slash mở nested Jink request, làm runner EXIT `1` và chậm tới timeout dù native server cuối cùng mới GameOver. Profile đã bị gỡ allowlist. Điều này xác nhận các skill ViewAs/response/choice không được phép dùng assertion “SkillEffect đã xuất hiện” để che nested protocol chưa có driver.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_MATRIX_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_MATRIX_2026-10-22.json). Coverage hiện là **7/18**, còn 11 skill OPEN; chưa đóng P0 aggregate, P2 quality, P3 reconnect/device, P4 release/rollback hoặc P5 canary. `REQUEST_SAFETY_OPEN`, production **NO-GO**, không release/commit/push/deploy.

Khi upstream thay đổi, profile table và nested-request exclusion chỉ là QA harness; port request adapter, common SmartAI dispatcher, từng `addAI`, QA overlay và assertion theo hunk riêng. Bước tiếp theo là xây nested-request driver bounded cho Jink/choice/card-chosen/pindian, không mở rộng allowlist mù.

## Native downstream-effect replay — 18/18 request PASS, `hs__kurou` effect PASS bounded (22/10/2026)

Đây là bước nối giữa hai câu hỏi khác nhau: AI có tạo reply hợp lệ không, và reply đó có đi vào skill effect thật không. QA-only `ai-trace` seed `1780420130`, candidate `cp50`, chạy native C++ thật với hai client loopback + hai native BOT; runner **EXIT 0**, GameOver, browser errors `0`, public BOT skill log `0`, process/port cleanup PASS.

Request trace vẫn đi qua `player.ai:makeReply()` thật và native feasibility: **18/18 opportunities, 18/18 accepted/acted, 0 fallback, 0 invalid, 0 errors**. Sau khi capture xong 18 reply, harness chỉ replay reply đã accepted của `hs__kurou` qua `Room:handleUseCardReply` → `Room:useSkill` → `SkillEffect` → `hs__kurou:onUse`, với config tạm và allowlist QA-only. Native summary quan sát `attempted=1 accepted=1 handled=1 skill_effects=4 fake=0 hp_delta=-1 errors=0`, HP **3→2**. `skill_effects=4` là fan-out của global QA director một lần effect qua bốn player, không phải bốn lần replay; vì vậy assertion yêu cầu `>=1` observation.

Identity: public runtime MD5 `01dc027eaa8c8171fc5e4c1e8afc6f50`, browser dist SHA-256 `029f742b3e2e0afe03bc02b3b8ec7a9a7cb15b42dfd4b16fb2935918f079ba54`, native binary SHA-256 `de24b9078ae13879e1548387c87af7fc8cd94ebfb1435979a4930b89940980ba`; QA package revision `3c4d9cb8a359725674882b803204e0671dfca400`, package SHA `78a05d82911f5930bd42622f74541f7480b7e0fce752d3d46de1d049194f2845`. Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_DOWNSTREAM_EFFECT_REPLAY_2026-10-22.json). Không lưu raw log, credential, private card/target/hand/general state hoặc exception payload.

Evidence này **không** có nghĩa cả Prompt 4 đã hoàn tất: mới downstream replay **1/18 skill**, chưa apply 17 reply còn lại qua full event chain; chưa đóng P0 aggregate, P1 toàn bộ effect, P2 causal/tactical quality, P3 reconnect/device, P4 release/rollback hoặc P5 canary. `REQUEST_SAFETY_OPEN`, production **NO-GO**. Runner dùng cờ local `TQS_LIVE_ALLOW_UNPINNED=1` vì không có release manifest, nên đây là diagnostic evidence chứ không phải release proof.

Khi upstream cập nhật, phần này tái sử dụng được theo hunk: giữ adapter request, common SmartAI dispatcher, từng `addAI` của skill, QA overlay và harness assertion tách riêng; không copy đè toàn bộ file upstream. Bước tiếp theo là mở rộng replay bounded cho các active skill không nested-request, thêm state assertion tương ứng và chạy lại local/native gates.

## Card-chooser request adapter — custom display prompt không còn bị gắn nhãn malformed (22/10/2026)

Đây là sửa ở **AI/request-safety layer**, không phải sửa effect hay luật của skill. `Room:askToChooseCard` nay truyền `skill_name` ở field thứ tư, tách khỏi display prompt; UI/client vẫn dùng ba field đầu như cũ. `SmartAI:handleAskForCardChosen` ưu tiên skill metadata và chỉ dùng parser legacy khi metadata không có, nên có thể port ngược vào upstream bằng hai hunk nhỏ mà không ghi đè toàn bộ `room.lua`/`smart_ai.lua`. QA overlay được giữ đồng bộ riêng.

## Matched native request-state A/B sau card adapter — 3/3 cặp, 54/54 matched (22/10/2026)

Candidate và baseline đã chạy tuần tự cùng fixture `ai-trace` trên seed `1780420130/0131/0132`; baseline chỉ bật `tqsPrompt4Baseline=true` để ẩn 18 strategy Prompt 4. Cả **6/6 runner EXIT 0**, mọi run tới `GameOver`, browser errors `0`, public BOT skill log `0` và QA process/port được dọn. Public runtime identity giữa hai nhánh ổn định ở MD5 `01dc027eaa8c8171fc5e4c1e8afc6f50`.

Official analyzer xác nhận **3/3 `MATCHED_NATIVE_SKILLS`**, `54/54 matchedRequests`, `requestStateMismatches=0` và `NO_INVALID_NATIVE_REPLIES`. Candidate có `54/54 accepted/acted`, `0` fallback, `0` invalid; baseline có `3/54 accepted/acted`, `51` fallback, `0` invalid. Bounded delta là `changedTargetQualities=51`, `changedSelectedCardCounts=33`, `changedSelectedTargetCounts=36`, `changedResourceValues=33`. Vì baseline cố ý tắt strategy nên đây là delta hành vi dự kiến của phép A/B, không phải causal proof rằng candidate chơi tốt hơn hoặc có win-rate cao hơn.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CARD_ADAPTER_MATCHED_AB_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CARD_ADAPTER_MATCHED_AB_2026-10-22.json). Probe gọi `player.ai:makeReply()` thật và native feasibility, nhưng chưa apply mọi reply accepted qua full skill-effect/event chain; target/resource values cũng chỉ là coarse snapshot. Vì vậy mốc này đóng bounded request-state pairing, chưa đóng P0 aggregate safety, downstream effect, tactical quality, full-state equivalence, reconnect/device, release/rollback hoặc canary. `REQUEST_SAFETY_OPEN` và production **NO-GO** vẫn giữ nguyên.

Bước kế tiếp là dựng downstream-effect assertion/replay bounded ngay sau `makeReply()` cho 18 request, giữ fingerprint/state pairing và sanitize; sau đó mới mở rộng seed/roster. Khi upstream đổi, port riêng hunk adapter trong `room.lua`, dispatcher trong `smart_ai.lua` và QA overlay; chạy lại local/native gates, không copy đè nguyên file.

Regression local cho prompt canonical, custom prompt và malformed prompt là **7/7 PASS**. Native candidate `cp38` chạy `general-pair-match-mixed-c`, seed `1780421002`, trên QA port cô lập `19647` đã đạt `GameOver/result`; browser errors `0`, public BOT skill log `0`, process/port sạch. Counter sanitize là `206 total / 97 accepted / 109 fallback / 0 invalid / 109 no_decision`; riêng `AskForCardChosen` có `3 total / 3 fallback / 0 invalid`, tất cả là `no_strategy`, và `malformed_prompt=0`. Matrix trước đó có một `malformed_prompt`, nên targeted run xác nhận đúng hướng phân loại nhưng chưa phải causal/full coverage proof.

Node runner đã phát các PASS lines cần thiết; wrapper shell sau đó trả `1` vì dùng biến zsh read-only `status` để lưu `$?`. Evidence không gọi đây là clean runner `EXIT 0`; lỗi chỉ ở bookkeeping sau khi gameplay đã xong và được ghi rõ trong artifact [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CARD_ADAPTER_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CARD_ADAPTER_2026-10-22.json). `EmptyRequest` do `Room:animDelay` vẫn là operational no-op `unsupported_command`, không biến thành một quyết định AI.

Kết luận hiện tại vẫn là `REQUEST_SAFETY_OPEN` và production **NO-GO**: fallback/no-decision còn cao, chưa có denominator 18 skill đầy đủ, matched baseline, downstream effect, reconnect/device hoặc release gates. Bước kế tiếp là chạy lại mixed matrix với wrapper sạch, rồi tiếp tục matched state/downstream-effect replay.

## Clean mixed matrix after adapter — public identity stable, zero invalid (22/10/2026)

Đã chạy lại đủ bốn trajectory `general-pair-match-mixed-a/b/c/d` với seed `1780421000..1780421003`, seat swap A–D và candidate `cp40..cp43`. Native được khởi động với `.tqs_qa-pending` thật sự không tồn tại để `freekill-asio` tính public `flist.txt` trước khi bật symlink `qa_packages`; cả bốn runner sau đó báo cùng runtime MD5 `01dc027eaa8c8171fc5e4c1e8afc6f50`, không đưa QA package vào public identity. Cả **4/4 runner EXIT 0**, đạt GameOver/result; browser errors và public native-BOT skill log đều `0`.

Aggregate sanitize là **`621 total / 295 accepted / 326 fallback / 0 invalid / 314 no_decision`**, với reason `no_decision=216`, `no_strategy=98`, `unsupported_command=12`, `invalid_details={}`. `AskForCardChosen` xuất hiện `10` lần, cả `10` đều fallback có chủ đích vì chưa có strategy bounded (`no_strategy`), không có `malformed_prompt` và không có invalid reply. Per-skill provenance chỉ partial: 13 request qua `hs__longdan`, `dimeng`, `hs__wusheng`; không suy diễn cho phần còn thiếu.

Một attempt trước đó bị loại khỏi evidence vì pending symlink trong temp runtime vẫn resolve tới QA tree, làm MD5 có QA files; hai attempt preflight khác không mở gameplay. Artifact mới chỉ chứa bốn run identity sạch: [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CARD_ADAPTER_MATRIX_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_CARD_ADAPTER_MATRIX_2026-10-22.json). Đây là bounded request-safety evidence, không phải matched A/B, downstream-effect, tactical-quality hoặc win-rate proof; `REQUEST_SAFETY_OPEN` và production **NO-GO** vẫn giữ nguyên.

## Matched native resource-value snapshot — 54/54 request-state matched (bounded evidence, 22/10/2026)

Đã chạy lại candidate và baseline của fixture `ai-trace` trên ba seed `1780420130/0131/0132` sau khi thêm trường QA-only `resource_value`. Baseline chỉ bật `tqsPrompt4Baseline=true`; cả hai nhánh dùng cùng native binary, catalog, browser dist và package tree đã staging. Cả **6/6 runner EXIT 0**, fixed roster đạt `GameOver` ở mỗi run, browser trace được lưu và process/port QA được dọn.

Analyzer chính thức xác nhận **3/3 cặp `MATCHED_NATIVE_SKILLS`**, `54/54` request-state matched, `requestStateMismatches=0`, `NO_INVALID_NATIVE_REPLIES`. Candidate có `54/54 accepted/acted`, baseline `3/54 accepted/acted`; invalid cả hai nhánh `0`. Resource bucket aggregate của candidate là `none=18, low=36`; baseline `none=51, low=3`; `changedResourceValues=33`, và cả `108/108` decision đều phân loại được, không có `unknown`.

`resource_value` được tính từ `ai.getCardValue(id, "keep_value")` trên resource card mà AI thật sự chọn rồi lượng tử hóa thành `none/low/medium/high/unknown`; artifact không lưu giá trị số, card ID hay private state. Đây chỉ là **coarse AI valuation snapshot** để kiểm tra downstream analysis tiếp theo, không phải resource cost, tactical quality, downstream-effect success hay win-rate evidence. Baseline cố ý tắt 18 strategy nên các reply/resource delta là hành vi dự kiến của phép A/B, chưa phải causal conclusion.

Verification sau khi thêm field: native trace parser **7/7**, SmartAI **11/11**, Prompt 4 **5/5**, QA server contract **48/48**, `npm run typecheck:all`, Lua 5.4 syntax, JSON/source-hash integrity và `git diff --check` đều **PASS**; port QA không còn listener.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_RESOURCE_VALUE_MATRIX_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_RESOURCE_VALUE_MATRIX_2026-10-22.json). Manifest revision trong artifact được giữ để runner kiểm identity; package SHA-256 mới nhận diện chính xác staged working-tree QA tree và không đại diện một clean commit. P0 aggregate safety, full-state/downstream effect, opportunity denominator ngoài fixture, reconnect/device, release/rollback và canary vẫn **OPEN**; production vẫn **NO-GO**.

## Current mixed full-match rerun — 113 bounded outcomes, per-command provenance and zero invalid (22/10/2026)

Để kiểm tra package hiện tại sau khi thêm resource instrumentation, candidate `cp34` đã chạy lại `general-pair-match-mixed-a`, seed `1780421000` trên QA port cô lập `19647`. Runner EXIT `0`; hai client + hai native BOT đạt `GameOver/result`; browser errors `0`; không có public skill log của BOT; process/port đã dọn.

Aggregate sanitize là `113 total / 57 accepted / 56 fallback / 0 invalid / 49 no_decision`. Detail reason là `no_decision=28`, `no_strategy=21`, `unsupported_command=7`, `invalid_details={}`. Lần này native log có **8 command records** được đối soát đầy đủ: `PlayCard 45/12/0`, `AskForUseCard 31/25/0`, `AskForUseActiveSkill 6/3/0`, `AskForCardChosen 3/3/0`, `AskForSkillInvoke 10/5/0`, `AskForResponseCard 2/1/0`, `AskForChoices 9/0/0`, `EmptyRequest 7/7/0` theo `total/fallback/invalid`; tổng khớp aggregate.

Per-skill provenance mới chỉ có một entry allowlist: `hs__wusheng / PlayCard / no_decision / none = 2`, `overflow=0`. Đây là dấu hiệu instrumentation đã nối được skill với request reason ở một nhánh, nhưng chưa phải attribution đầy đủ cho 18 skill hoặc toàn bộ 56 fallback.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_RESOURCE_FULL_MATCH_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_RESOURCE_FULL_MATCH_2026-10-22.json). Đây là một trajectory mới với identity package SHA `e6b2…` và runtime MD5 `f119…`, không gộp với run lịch sử khác identity. Per-command provenance giúp khoanh vùng request safety tốt hơn nhưng chưa có per-skill attribution, matched baseline, Prompt 4-only denominator, downstream-effect evidence, reconnect/device, release/rollback hoặc canary; P0 và production gate vẫn **OPEN/NO-GO**.

## Four mixed full-match trajectories — 614 bounded outcomes, 0 invalid and partial per-skill provenance (22/10/2026)

Để mở rộng ngoài một trajectory, candidate đã chạy `general-pair-match-mixed-a/b/c/d` với seed `1780421000..1780421003` và bốn seat swap A–D bằng cùng package/runtime hiện tại. Cả **4/4 runner EXIT 0**, mọi trận đạt `GameOver/result`, browser errors `0`, public native-BOT skill log `0`, và port/process được dọn sau từng run.

Aggregate sanitize là `614 total / 300 accepted / 314 fallback / 0 invalid / 295 no_decision`; reason counts là `no_decision=200`, `no_strategy=94`, `unsupported_command=19`, `malformed_prompt=1`, `invalid_details={}`. Ba mươi hai command records được đối soát và lưu trong artifact; các bucket lớn là `PlayCard 226/69/0`, `AskForUseCard 146/119/0`, `AskForUseActiveSkill 80/46/0`, `AskForSkillInvoke 78/45/0`, `EmptyRequest 19/19/0` theo `total/fallback/invalid`.

Per-skill provenance đã xuất hiện ở 5 entry, tổng 11 request: `hs__wusheng=6`, `dimeng=4`, `huoji=1`, đều thuộc `PlayCard/no_decision/none`, overflow `0`. Đây là partial coverage; các fallback thiếu skill attribution không được gán ngược cho một skill cụ thể.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_RESOURCE_MIXED_MATRIX_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_RESOURCE_MIXED_MATRIX_2026-10-22.json). Bốn trajectory này vẫn không phải matched A/B, không tách Prompt 4-only denominator và không chứng minh tactical quality, downstream effect hay win-rate. P0 aggregate safety, per-skill coverage đầy đủ, reconnect/device, release/rollback và canary vẫn **OPEN**; production **NO-GO**.

## Mixed full-match request-safety review — 196 bounded outcomes, no invalid reply (22/10/2026)

Một run mới của `general-pair-match-mixed-a`, seed `1780421000`, dùng candidate package/runtime hiện tại và QA port cô lập `19647`. Runner EXIT `0`; hai client thật và hai native BOT đi tới `GameOver/result`; browser errors `0`; không có public skill log bị gán cho native BOT.

Native log phát ra aggregate `AI_MATCH_METRICS` và một aggregate `AI_MATCH_METRICS_DETAIL`, đều được đọc bằng allowlist: `196 total / 120 accepted / 76 fallback / 0 invalid / 72 no_decision`; reason counts là `no_decision=53`, `no_strategy=19`, `unsupported_command=4`, `invalid_details={}`. `no_decision` là subset của fallback. Vì vậy run này cung cấp evidence bounded rằng trajectory không có invalid reply, nhưng không thể dùng để đóng request-safety toàn cục: fallback/no-decision còn tồn tại, reason provenance chưa gắn được per-command/per-skill và denominator không tách Prompt 4-only.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_MIXED_FULL_MATCH_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_MIXED_FULL_MATCH_2026-10-22.json). QA process/port đã dọn; production không chạm. P0 aggregate safety, matched resource/downstream effect, reconnect/device và release gates vẫn OPEN.

## Matched native target-quality A/B — 54/54 request-state matched (bounded P2 evidence, 22/10/2026)

Candidate và baseline đã chạy cùng fixture `ai-trace` trên ba seed `1780420130/0131/0132`; baseline chỉ bật QA flag `tqsPrompt4Baseline=true` để ẩn strategy Prompt 4. Cả 6 runner EXIT 0, hai nhánh đều auth/lobby/StartGame/GameOver thành công. Official analyzer xác nhận 3/3 cặp `MATCHED_NATIVE_SKILLS`, tổng `54/54` request-state matched và `0` request-state mismatch.

Candidate có `54/54 accepted/acted`, `0` fallback, `0` invalid; baseline có `3/54 accepted/acted`, `51` fallback, `0` invalid. Các delta bounded là `changedTargetQualities=51`, selected-card count `33` và selected-target count `36`, trong khi opportunity/request-state không đổi. Baseline `tqsPrompt4Baseline` cố ý tắt 18 strategy nên đây là delta hành vi dự kiến của phép kiểm A/B, không phải causal proof hay win-rate evidence. Target quality chỉ là coarse role alignment: baseline `3 expected + 51 no_action`, candidate `54 expected`.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_TARGET_QUALITY_AB_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_TARGET_QUALITY_AB_2026-10-22.json). Global `AI_MATCH_METRICS` được giữ riêng vì còn gồm legacy requests; không trộn vào Prompt 4-only safety. P2 mới đóng bounded request-state pairing, còn full-state equivalence, downstream effect/resource value, quality rubric độc lập, nhiều roster hơn, P0 aggregate safety, E2E/reconnect/device, release/rollback và canary vẫn OPEN.

## Native target/card snapshot matrix — 54/54 expected across 3 seed variants (22/10/2026)

Candidate native `ai-trace` đã được chạy lại trên đủ ba seed/roster variant đã khai báo (`1780420130`, `1780420131`, `1780420132`) bằng cùng QA package revision `3c4d9cb8a359725674882b803204e0671dfca400`. Sau khi sửa lỗi staging symlink trong runtime tạm, cả 3/3 runner EXIT 0, hai client hoàn tất auth/lobby/StartGame, fixed four-seat roster đạt GameOver và trace được lưu. Lần thử đầu tiên của `0131` bị loại vì Lua worker không mở được QA package khi symlink còn pending; đó là lỗi launcher staging, không phải kết quả gameplay.

Parser chính thức xác nhận aggregate `54 decisions / 54 opportunities / 54 accepted / 54 acted / 0 miss / 0 fallback / 0 invalid / 0 error`; snapshot card/target đủ `54/54`; `target_quality=expected` đủ `54/54`, không có `unexpected`, `no_action` hay `unknown`. Mỗi seed có `18/18 expected`; cả 18 skill đều có ba quan sát expected.

Counter cần đọc tách lớp: legacy `AI_MATCH_METRICS` mỗi run là `25 total / 24 accepted / 1 fallback / 0 invalid / 1 no_decision`, tổng ba run `75/72/3/0/3`. Đây là counter rộng còn gồm legacy `ai-trace` và request bounded khác, không phải Prompt 4-only denominator. Trace Prompt 4 riêng biệt có `0` fallback và `0` invalid trong cả 54 quyết định.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_TARGET_QUALITY_MATRIX_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_TARGET_QUALITY_MATRIX_2026-10-22.json). Đây vẫn chỉ là bounded coarse-role alignment; không chứng minh target chiến thuật tối ưu, resource value, downstream effect, observed-match frequency hay win-rate. Full Prompt 4, P0 aggregate safety, P2 matched A/B quality, E2E/reconnect/thiết bị, release/rollback và canary vẫn OPEN.

## Native target/card snapshot — 18/18 expected, bounded P1 evidence (22/10/2026)

QA-only `ai-trace` hiện ghi thêm ba trường bounded từ reply thật của native `player.ai:makeReply()`: số lá được chọn, số mục tiêu được chọn và `target_quality` theo role class đã khai báo. Chạy seed `1780420130` trên package revision `3c4d9cb8a359725674882b803204e0671dfca400`, runner EXIT 0 và GameOver; Prompt 4 có `18 decisions / 18 opportunities / 18 accepted / 18 acted / 0 fallback / 0 invalid / 0 error`. Parser chính thức xác nhận selected-card/selected-target snapshot đủ 18/18 và `target_quality=expected` đủ 18/18.

Các expectation được sửa theo quan sát native trước khi kết luận: `hs__longdan` dùng role `enemy`, `hs__luanji` dùng `mixed`, còn `jijiu` dùng `none` vì target của request cứu được mã hóa trong request/context thay vì `reply.targets`. Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_TARGET_QUALITY_SNAPSHOT_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_TARGET_QUALITY_SNAPSHOT_2026-10-22.json). Artifact chỉ giữ role class và count, không giữ card/target ID, hand/general, prompt, credential hoặc raw log.

Đây là bằng chứng **bounded semantic alignment**, không phải chứng minh AI chọn mục tiêu tối ưu, resource value, downstream effect hay win-rate. QA package/runtime là cô lập; không thay production. Full Prompt 4, P0 aggregate safety, P2 matched A/B rộng, E2E/reconnect/thiết bị, release/rollback và canary vẫn OPEN.

Ngày kiểm tra: 2026-10-22<br>
Mode mục tiêu: `new_heg_mode` (Quốc Chiến)<br>
Phạm vi runtime: package Hegemony được registry nạp cùng các package phụ trợ thực tế; không mở rộng sang toàn bộ hệ sinh thái FreeKill.

## Kết luận

Prompt 4 đã triển khai ba nhóm nhỏ với 18 skill được chọn, bounded decision/request QA và deterministic strategy telemetry; tuy nhiên **chưa đóng nghiệm thu toàn bộ Prompt 4**. Phạm vi vẫn chỉ là pool `new_heg_mode`; chưa mở rộng sang toàn bộ FreeKill. Ba generic chooser đã có regression local và **normalized native replay 6/6 input+legal-offer matched, 0 fallback/invalid** ở cả baseline/candidate. Ngoài ra, ma trận native mới nhất cho `ai-trace` đã ghép **3/3 cặp trên ba seed, 54/54 request-state**, nhưng đây vẫn là PASS bounded cho request/reply surface; request-safety toàn bộ 18 skill, target/resource valuation, full-game/reconnect và causal replay vẫn mở.

Telemetry native opt-in trước đó chỉ giữ metadata đã làm sạch: một run đi qua GameOver, trả hai client về lobby và disconnect sạch, ghi nhận 247 request AI với 142 accepted và 105 fallback; `hs__wusheng` xuất hiện 7 request và đều accepted. Đây mới là observed request telemetry của một trận, chưa phải denominator cơ hội, replay ghép baseline/candidate hay win-rate.

## Native request-safety follow-up — discard replay + nil classification PASS bounded (22/10/2026)

Lượt follow-up xác nhận sửa ở **hai lớp khác nhau**, nên có thể tái sử dụng có kiểm soát khi upstream cập nhật:

- [`runtime/packages/freekill-core/standard/aux_skills_dir/discard_skill.lua`](../../runtime/packages/freekill-core/standard/aux_skills_dir/discard_skill.lua) là strategy riêng của `discard_skill`. Nó lấy candidate cards, replay qua `getEnabledCards()`/`selectCard()`/`okButtonEnabled()` của request đang sống, rồi dọn selection trước khi trả; card stale, duplicate hoặc không qua `card_filter`/`prohibit`/`pattern`/`min-max` trở thành `no_decision` để Room fallback xử lý.
- [`runtime/packages/freekill-core/ltk/server/ai/smart_ai.lua`](../../runtime/packages/freekill-core/ltk/server/ai/smart_ai.lua) là dispatcher dùng chung. Guard mới chỉ đổi cách phân loại `nil`: `nil`/empty là không có quyết định; non-nil sai kiểu vẫn là invalid strategy reply. Đây không phải luật skill và không làm malformed reply hợp lệ.

Native fixed pre/post với `general-pair-match-a`, seed `1780420132`, đều đạt GameOver và browser errors `0`. Trước fix có `21 total / 14 accepted / 7 fallback / 3 invalid / 4 no_decision`, trong đó `discard_skill=6:3:3:3:0` và `AskForUseActiveSkill` có `3` `feasibility_rejected`. Sau discard replay có `23 / 15 / 8 / 0 / 8`, `discard_skill=6:3:3:0:3`; ba active-skill fallback đều là `no_decision`.

Mixed rerun `general-pair-match-mixed-a`, seed `1780421000`, runner exit `0`, hai client + hai native BOT đạt GameOver, browser errors `0`, public bot skill log `0`. Candidate ghi nhận `111 total / 50 accepted / 61 fallback / 0 invalid / 58 no_decision`; `discard_skill=10:4:6:0:6`, `AskForUseActiveSkill=16/11/0`, `PlayCard=39/12/0`. Đây là evidence bounded của request safety trên trajectory thực, không phải denominator quần thể hay bằng chứng win-rate.

Artifact metadata-only: [`SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_DISCARD_REPLAY_2026-10-22.json`](SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_DISCARD_REPLAY_2026-10-22.json). Verification: SmartAI **11/11**, QA contract **48/48**, native trace parser **6/6**, `typecheck:all`, Lua 5.4 syntax và `git diff --check` **PASS**; QA port/process đã dọn. Khi upstream thay đổi, port hai patch riêng rẽ theo đúng lớp và chạy lại regression/native evidence tương ứng; không copy đè nguyên file candidate lên upstream.

Full gate vẫn **OPEN**: non-nil malformed replies, aggregate ngoài trajectory, đủ 18-skill deterministic replay, target/card/resource quality, reconnect, thiết bị thật, release/rollback/canary chưa đóng.

## Native exact 18-skill trace — 3-seed matched A/B matrix PASS bounded; full gate vẫn mở

Lượt mới nhất dùng một QA package cô lập có revision `1f5e5fe9fd86c300d2aeb2f4af4b3974e2af4b82`, package SHA-256 `c936abe85bb0e878ad81564da0083791b4daf67d907adf6bbb4da3a206062667`, catalog SHA-256 `f7ca32fafaf8ff3adbdc39a2ca90aff05a09020385233376d26f8cf9f08cbef3`, native binary SHA-256 `de24b9078ae13879e1548387c87af7fc8cd94ebfb1435979a4930b89940980ba`, runtime MD5 `87ef087dc805dbe1c60101053f5ec30e` và browser dist SHA-256 `029f742b3e2e0afe03bc02b3b8ec7a9a7cb15b42dfd4b16fb2935918f079ba54`. Catalog giữ scenario ID `ai-trace` nhưng khai báo rõ seed range `1780420130..1780420132` và ba semantic roster variants; không nhận seed ngoài catalog. QA server chạy cô lập tại port `19647`, không phải production.

Candidate và baseline đã chạy tuần tự trên cả ba seed; **6/6 runner EXIT 0**, hai client loopback + hai native BOT đạt `GameOver` ở mọi run, và port được đóng sau từng run. Prompt 4 trace ở mỗi run đều có `18 decisions / 18 opportunities / errors=0 / metadata=shape_v1`; candidate có `18 accepted / 18 acted / 0 fallback / 0 invalid`, baseline có `1 accepted / 1 acted / 17 fallback / 0 invalid`. Artifact metadata-only là [SMARTAI_PROMPT4_NATIVE_SKILL_TRACE_MATRIX_2026-10-22.json](SMARTAI_PROMPT4_NATIVE_SKILL_TRACE_MATRIX_2026-10-22.json).

Parser chính thức ghép được **3/3 cặp, 54/54 request-state**, `pairVerified/stateVerified/fixtureVerified/shapeMetadataVerified=true`, `changedOpportunities=0`, `status=MATCHED_NATIVE_SKILLS` và `safetyStatus=NO_INVALID_NATIVE_REPLIES`. Candidate đạt **54/54 accepted/acted**; baseline **3/54 accepted/acted**; `changedAccepted=changedActed=changedOutputShapes=changedFallbackReasons=51`, `changedTargetProfiles=36`, `changedCardProfiles=51`, `changedResourceShapes=33`, invalid ở cả hai nhánh bằng `0`. Các delta là hành vi dự kiến vì baseline cố ý tắt 18 strategy Prompt 4; shape metadata chỉ mô tả reply, không chứng minh causal improvement, target quality, resource value hoặc win-rate.

Global legacy metrics của mỗi candidate run là `25 total / 24 accepted / 1 fallback / 0 invalid / 1 no_decision`; baseline là `25 / 5 / 20 / 0 / 20`. Counter này gồm cả legacy `ai-trace`, không phải Prompt 4-only safety gate. Vì vậy ma trận đóng được bounded matched request/reply evidence, nhưng `REQUEST_SAFETY_OPEN` của toàn bộ Prompt 4 vẫn giữ nguyên. Target/card/resource valuation, downstream effect, observed match frequency, physical device, full gameplay/reconnect, release/rollback và canary chưa có evidence.

## Native exact 18-skill trace — paired request-state PASS bounded; full gate vẫn mở

Lượt native mới nhất chạy tuần tự candidate `cp35` và baseline `cp36` trên QA cô lập `19646`/admin `9000`, cùng binary SHA-256 `de24b9078ae13879e1548387c87af7fc8cd94ebfb1435979a4930b89940980ba`, runtime MD5 `de5a8263f3fc9202e98f3e468838447a`, QA revision `c961a95259098d5199fee3ca224d863c59161bda` và verified package SHA-256 `792548920a2c48ced7bebb510aeada35d13c11757988cba24dd26ca1fc888ad0`. Cả hai runner **EXIT 0**, hai client + hai native BOT đạt **GameOver**, browser errors `0`; QA process/port đã được dọn sau run.

Trace QA-only bao phủ đúng 18 skill trong shortlist. Candidate có `18 decisions / 18 opportunities / 18 accepted / 18 acted / 0 miss / 0 fallback / 0 invalid / 0 error`; baseline có `18 / 18 / 1 / 1 / 17 / 17 / 0 / 0`. Analyzer đối chiếu cùng revision/seed/fixture và xác nhận `matchedRequests=18`, `changedOpportunities=0`, không có request-state mismatch; evidence metadata-only nằm ở [SMARTAI_PROMPT4_NATIVE_SKILL_TRACE_PAIRED_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_NATIVE_SKILL_TRACE_PAIRED_2026-10-21.json).

`MATCHED_NATIVE_SKILLS` ở đây có nghĩa là 18 input/offer/request-state đã ghép được, còn `NO_INVALID_NATIVE_REPLIES` có nghĩa là cả hai nhánh có `invalid=0`. Candidate và baseline có 17 reply-shape/acceptance delta và 17 reason delta vì baseline cố ý tắt strategy Prompt 4; các delta này là hành vi mong đợi của phép so sánh, không phải bằng chứng causal/population-level. Fixture đã được sửa để handler thật expose được các skill response thiếu trong cặp tướng: `kanpo` có 3 enabled cards và candidate `accepted/acted=1/1`; `aocai` có 2 enabled cards và cả hai nhánh `accepted/acted=1/1`. Sau review, `jijiu` đọc `must_targets` từ cả slot 4/5; `hs__longdan` duyệt toàn bộ target hợp lệ để tránh RNG-dependent miss. Candidate không còn miss trong bounded fixture; target quality, resource value và downstream effect vẫn chưa được chứng minh.

Local verification của lượt này: SmartAI **9/9**, parser trace **6/6**, QA server contract **47/47**, `npm run typecheck:all`, verified package/hash, Lua 5.4 syntax và `git diff --check` đều **PASS**; candidate và baseline native runner đều **PASS**. Gate tổng thể vẫn **OPEN** vì còn target/card/resource valuation, observed opportunity denominator thực tế, seed/roster rộng hơn, aggregate invalid/fallback review, full web/điện thoại thật gameplay + reconnect, release/rollback và canary.

## Native generic chooser QA — 6+6 GameOver PASS; matched request-state PASS bounded

Scenario QA-only `chooser-trace` chạy sáu trường hợp mandatory/optional cho `choose_players_skill`, `choose_cards_skill`, `ex__choose_skill` qua **real native `actor.ai:makeReply()`**, khóa seed `1780420132`, revision `309cae77f7a9dfade2719c7c4a69af49386d7cc8`, bốn seatRosters và bốn `fixedHands` semantic. Hai runtime `/private/tmp/tqs-chooser-paired.pK5MZp/{baseline,candidate}` đã thay binary legacy lỗi đăng nhập bằng cùng Mach-O arm64 SHA-256 `de24b9078ae13879e1548387c87af7fc8cd94ebfb1435979a4930b89940980ba`. Binary QA được build từ pin `b8a2ad48305aea7b55ccca325fcbeb100cb8a01a` với ba patch quản lý, tương thích macOS và sửa lỗi `RpcLua::alive()` kiểm Linux `/proc/<pid>/exe` khiến Lua child pipe đóng trên macOS. Sửa C++ chỉ nằm tại source tạm `/private/tmp/tqs-prompt4-native-source.QmBVBe/source`; không đưa vào binary production.

Hai runner dùng signed ticket QA và hai tài khoản riêng, đăng nhập/phòng/chọn tướng/GameStart/**GameOver** đều **PASS**. Native xác thực cặp chủ/phó và fixed hands theo cả bốn ghế ở hai nhánh. Các legal offer hash của cả sáu quyết định khớp; mỗi nhánh có **6 opportunity / 6 accepted / 3 acted / 3 optional-empty miss / 0 fallback / 0 invalid / 0 probe error**. Theo skill, mỗi chooser có `2` opportunity, `2` accepted và `1` optional-empty no-action. Vì native feasibility đã chấp nhận ba lựa chọn optional rỗng, chúng **không phải request lỗi** hoặc fallback. Native `AI_MATCH_METRICS` tổng mỗi trận là `8 total / 8 accepted / 0 fallback / 0 invalid / 0 no_decision` gồm sáu chooser và hai `CustomDialog`.

**Normalized native rerun đã xác minh thực tế:** QA fingerprint ánh xạ native target ID sang vị trí ghế ổn định **chỉ trong bản shadow dùng để so sánh**; `ai.data` truyền vào `makeReply()` vẫn giữ ID thật. Baseline/candidate dùng cùng binary, manifest SHA-256 `6031e3f1ae113ac1f0a00ce7a6bff918bbdd5a9c8a6f23003b4528d3436143d8`, QA init SHA-256 `d9c6a7a153ff7f308441239a24a265b7c8c1bfcbd25d7a16132480c261890b1c`, seed, revision và semantic hands. Cả hai browser runner/GameOver PASS, analyzer trả **`MATCHED_BOUNDED_REQUESTS`**, `comparedCases=6`, **`mismatchedCases=[]`**, toàn bộ sáu input và legal-offer fingerprint khớp. Bằng chứng metadata-only: [SMARTAI_PROMPT4_CHOOSER_NATIVE_MATCHED_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_CHOOSER_NATIVE_MATCHED_2026-10-21.json). Native-replay parser **5/5 PASS** và QA contract **47/47 PASS** đã được quan sát trong lần nghiệm thu runtime.

**Lịch sử trước chuẩn hóa:** lượt GameOver 17:32–17:33 dùng manifest cũ `643e5edcdd6fd80a381b7ca468a8c0596081ce90c4eed3fd16e34b416a3669a8` từng có `mismatchedCases=[1,3,4,6]` do target ID native cấp khác nhau. Evidence [SMARTAI_PROMPT4_CHOOSER_NATIVE_PRE_NORMALIZATION_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_CHOOSER_NATIVE_PRE_NORMALIZATION_2026-10-21.json) được giữ làm provenance **INCONCLUSIVE lịch sử**, đã được thay thế về mặt kết luận bằng normalized rerun. Lần khởi động QA trước rerun từng bị chặn nhưng lần replay cuối đã chạy thành công; các port QA `19644`, `19645`, `9000` được xác nhận đóng sau run. Điều này không chứng nhận production hoặc thiết bị thật. Hash FNV32 là guard bounded, không thay snapshot đầy đủ engine state.

**Gate hiện tại:** `NATIVE_EXECUTION_6+6_PASS`, `MATCHED_BOUNDED_REQUESTS`, `REQUEST_SAFETY_OPEN`. Đối soát metadata-only mới đã xác nhận aggregate observed candidate `247 total / 142 accepted / 105 fallback / 7 invalid / 95 no_decision / 3 other fallback`, các command cộng khớp: invalid `PlayCard=5`, `AskForUseActiveSkill=2`; other fallback `EmptyRequest=3`. Bằng chứng [SMARTAI_PROMPT4_REQUEST_SAFETY_FOLLOWUP_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_REQUEST_SAFETY_FOLLOWUP_2026-10-21.json) **không** cung cấp reason/root cause từng command và **không** ghép trajectory A/B lịch sử. Bước kế tiếp là native request-state/reason telemetry ghép được cho 18 skill, đánh giá target/card/resource và nhiều seed/roster. Không suy ra cải thiện causal/win-rate từ sáu scenario, không mở nhóm 4, không commit/push/deploy.

Đã bổ sung và **đã xác minh** source-side QA instrumentation: mỗi decision `ai-trace` v3 mang nhãn skill bounded từ metric của chính `player.ai:makeReply()`, cùng `reason/detail` allowlist; parser chỉ xác nhận provenance khi fixture là `semantic_v3` và mọi decision có skill không phải `unknown`. Candidate native `ai-trace` đạt `5 decisions`, `3 accepted`, `2 no_decision`, `0 probe error`, verified pair/hands và gán được `slash_skill`, `duel_skill`, `hs__zhiheng`. Full-match `general-pair-match-a` đạt GameOver với 2 client + 2 native BOT; metrics `38 total / 30 accepted / 8 fallback / 3 invalid / 5 no_decision`, trong đó `discard_skill` có `7 requests / 4 accepted / 3 invalid`, `AskForUseActiveSkill` có `3/3 invalid` với detail `feasibility_rejected`, còn `AskForCardChosen` có `2 malformed_prompt`. Evidence metadata-only: [SMARTAI_PROMPT4_NATIVE_V3_FULL_MATCH_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_NATIVE_V3_FULL_MATCH_2026-10-21.json). Các artifact `247` request và reason provenance hiện tại vẫn là evidence lịch sử v2, không được hồi tố gán skill. Deterministic state replay đủ 18 skill, matched target/card/resource analysis, A/B rộng và full request-safety gate vẫn còn mở.

Nhóm 1 gồm sáu kỹ năng:

- `tianyi`
- `shangyi`
- `tiaoxin`
- `hs__zhiheng`
- `hs__kurou`
- `hs__qiangxi`

Nhóm 2 gồm sáu kỹ năng được chọn từ backlog có điểm cao và đã đóng bằng fixture riêng:

- `hs__longdan`
- `hs__luanji`
- `hs__wusheng`
- `huoji`
- `jijiu`
- `kanpo`

Nhóm 3 mở tiếp sáu kỹ năng còn lại trong shortlist và đã đóng bằng fixture public-information riêng:

- `aocai`
- `beizhu`
- `dimeng`
- `choufa`
- `cunsi`
- `duanfa`

Các thay đổi chỉ bổ sung quyết định của SmartAI và các nhánh validation hẹp cần thiết cho request hợp lệ; không thay đổi cơ chế kỹ năng phía server.

## Bằng chứng pool thực tế

Audit chạy trên registry/package snapshot mà runtime có thể nạp cho `new_heg_mode`:

| Chỉ số | Kết quả |
|---|---:|
| Tướng đủ điều kiện trong pool | 301 |
| Tổng số lượt skill reference trên các tướng | 528 |
| Skill ID duy nhất | 520 |
| General trong active registry | 311 |
| General visible sau loại hidden/total-hidden | 301 |
| Skill có quyết định chiến thuật | 155 |
| Đã có AI handler trong candidate | 54 |
| Đang dùng default handler trong candidate | 101 |
| Không cần quyết định riêng | 365 |
| Skill thiếu handler/không phân loại | 0 |

Danh sách đầy đủ tướng, skill, package, surface, handler và priority nằm trong [SMARTAI_PROMPT4_POOL_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_POOL_2026-10-21.json). Backlog 101 default handler đã được xếp thứ tự minh bạch trong [SMARTAI_PROMPT4_BACKLOG_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_BACKLOG_2026-10-21.json). Con số 301/528/520 được lấy từ pool/registry, không suy ra từ tỷ lệ file có `addAI()`.

### Tần suất và giới hạn bằng chứng

- `poolFrequencyEstimate` là ước tính xuất hiện theo số general đủ điều kiện trong pool, được chuẩn hóa trên 100 general.
- `observedMatchFrequency` trong pool vẫn là `null`: đã có một mẫu telemetry trận, nhưng mẫu này chỉ đếm request/accepted/fallback theo nhãn skill, chưa có denominator cơ hội hợp lệ và chưa đủ để ước tính tần suất skill trong pool. Chỉ số sanitized nằm trong [SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json).
- Vì vậy bảng priority hiện dùng `AppearanceFrequency(pool estimate) × StrategicImpact × ImprovementOpportunity`; chưa tuyên bố đây là tỷ lệ sử dụng thực tế hay tỷ lệ thắng.

## Bảng ưu tiên

Điểm hiện tại dùng công thức:

`Priority = poolFrequencyPer100 × StrategicImpact × ImprovementOpportunity`

| Hạng | Skill | Pool frequency / 100 general | Impact | Opportunity | Priority | Trạng thái |
|---:|---|---:|---:|---:|---:|---|
| 1 | `tianyi` | 0.664 | 5 | 5 | 16.61 | Nhóm 1 |
| 2 | `shangyi` | 0.664 | 4 | 5 | 13.29 | Nhóm 1 |
| 3 | `tiaoxin` | 0.664 | 4 | 5 | 13.29 | Nhóm 1 |
| 4 | `hs__kurou` | 0.332 | 4 | 5 | 6.64 | Nhóm 1 |
| 5 | `hs__longdan` | 0.332 | 5 | 4 | 6.64 | Nhóm 2 |
| 6 | `hs__luanji` | 0.332 | 5 | 4 | 6.64 | Nhóm 2 |
| 7 | `hs__qiangxi` | 0.332 | 4 | 5 | 6.64 | Nhóm 1 |
| 8 | `hs__wusheng` | 0.332 | 5 | 4 | 6.64 | Nhóm 2 |
| 9 | `hs__zhiheng` | 0.332 | 4 | 5 | 6.64 | Nhóm 1 |
| 10 | `aocai` | 0.332 | 4 | 4 | 5.32 | Nhóm 3 |
| 11 | `beizhu` | 0.332 | 4 | 4 | 5.32 | Nhóm 3 |
| 12 | `dimeng` | 0.332 | 4 | 4 | 5.32 | Nhóm 3 |
| 13 | `huoji` | 0.332 | 4 | 4 | 5.32 | Nhóm 2 |
| 14 | `jijiu` | 0.332 | 5 | 3 | 4.98 | Nhóm 2 |
| 15 | `kanpo` | 0.332 | 5 | 3 | 4.98 | Nhóm 2 |
| 16 | `choufa` | 0.332 | 3 | 4 | 3.99 | Nhóm 3 |
| 17 | `cunsi` | 0.332 | 4 | 3 | 3.99 | Nhóm 3 |
| 18 | `duanfa` | 0.332 | 3 | 4 | 3.99 | Nhóm 3 |

Các skill còn lại được giữ trong artifact với `status` và lý do ưu tiên tương ứng; chưa triển khai chỉ vì có mặt trong registry.

## Chiến thuật đã triển khai

- `tianyi`: dùng lá của BOT có số cao, chỉ chọn mục tiêu có hand công khai; ước lượng xác suất thắng pindian, phần thưởng và rủi ro mất lượt/chi phí, có ưu tiên tình huống mục tiêu ít bài. Không đọc hand bí mật của đối thủ.
- `shangyi`: ưu tiên đối thủ có hand công khai lớn hơn 0 và chọn đúng lá đã được server reveal qua `data.cards`; thêm choice strategy `shangyi_card` để tránh gửi CustomDialog không được hỗ trợ.
- `tiaoxin`: ưu tiên đối thủ hợp lệ có hand công khai; cân đối giá trị ép discard với khả năng đối thủ trả Slash và chi phí/rủi ro tương ứng.
- `hs__zhiheng`: lọc legal cards, ưu tiên bỏ lá có keep-value thấp, mô phỏng lợi ích throw/draw và chỉ kích hoạt khi lợi ích dương.
- `hs__kurou`: không dùng khi HP thấp; cân đối mất HP với draw 3, ưu tiên bỏ lá giá trị thấp và chỉ dùng khi lợi ích dương; có xét giá trị giữ Slash.
- `hs__qiangxi`: cân đối mất HP với bỏ weapon, chọn mục tiêu địch hợp lệ và chỉ dùng khi sát thương kỳ vọng vượt chi phí; không tự ý thay đổi luật server.

Nhóm 2 bổ sung:

- `hs__longdan`: chọn đúng chuyển đổi 【闪】/【杀】 theo pattern response, chọn lá giữ lại thấp nhất trong response và mô phỏng lợi ích khi dùng 【杀】; nhánh hậu hiệu ứng chỉ gây damage lên địch hoặc hồi máu cho đồng minh theo faction inference.
- `hs__luanji`: duyệt cặp hai lá hợp lệ, tôn trọng mark花色 đã dùng trong lượt, trừ chi phí giữ lá và mô phỏng toàn bộ mục tiêu của 【万箭齐发】; invoke rút bài chỉ khi còn dung lượng hand hợp lý.
- `hs__wusheng`: chuyển lá đỏ thành 【杀】 cho play/response, đánh giá target công khai và trừ keep-value để tránh chọn lá quý khi lợi ích ngang nhau.
- `huoji`: chỉ dùng khi còn lá thứ hai cùng suit cho bước Fire Attack, chọn mục tiêu có hand công khai và cân bằng giá trị gây ảnh hưởng với hai chi phí lá.
- `jijiu`: chỉ chuyển lá đỏ thành 【桃】 trong request cứu hợp lệ có `must_targets`, bảo vệ self/đồng minh đã suy luận đủ; không dùng hand hoặc general bí mật của đối thủ.
- `kanpo`: đọc metadata effect công khai của request nullification, chỉ phản hồi khi lợi ích của effect là âm hoặc đang bảo vệ đồng minh, rồi chọn lá đen có keep-value thấp.

Pindian card selection được nối qua nhánh rất hẹp cho prompt `#askForPindian`: chọn lá có số cao nhất của BOT từ các lá được phép. Validator chỉ chấp nhận raw `card.subcards` trong đúng request `choose_cards_skill`; các request khác giữ validation hiện có.

Nhóm 3 bổ sung:

- `aocai`: trong request response, chỉ xét các lá basic server đã mở rộng và chọn lá có keep-value thấp hơn; không suy đoán thêm từ draw pile.
- `beizhu`: bỏ qua khi BOT còn 1 HP, ưu tiên địch có ít bài công khai nhất để giảm rủi ro bị ép nhiều 【杀】; ở nhánh không có 【杀】, chọn lá có keep-value cao nhất trong danh sách đã hiển thị.
- `dimeng`: duyệt cặp đồng minh–địch, chỉ giữ cặp mà địch có nhiều bài hơn đồng minh; trả chênh lệch bằng các lá hợp lệ có keep-value thấp nhất.
- `choufa`: chọn đồng minh còn bài và có hand công khai lớn; ở prompt chọn lá đã hiển thị, chọn loại bài có số lượng nhỏ nhất để tối đa hóa số lá còn lại được coi là 【杀】. Adapter `AskForCardChosen` dùng `ChooseCardStrategy` và vẫn qua validator card ID của request.
- `cunsi`: ưu tiên đồng minh cùng phe còn sống để nhận `yongjue` và hai lá bài; chỉ chọn bản thân làm phương án an toàn khi không có đồng minh phù hợp.
- `duanfa`: duyệt các prefix lá đen theo keep-value tăng dần, tôn trọng giới hạn theo phase và chỉ dùng khi mô phỏng bỏ–rút cho giá trị dương.

## So sánh baseline

Trong cùng audit fixture, cả ba nhóm đều chuyển từ default handler sang AI handler:

| Candidate state | Baseline | Candidate |
|---|---:|---:|
| Handler AI của nhóm 1 | 0/6 | 6/6 |
| Handler AI của nhóm 2 | 0/6 | 6/6 |
| Handler AI của nhóm 3 | 0/6 | 6/6 |
| Handler default của 18 skill | 18/18 | 0/18 |

Đây là so sánh bounded handler/decision fixture, không phải kết luận win-rate. Deterministic telemetry bổ sung dưới đây kiểm tra reply hợp lệ và chi phí trên request-shaped fixture; chưa có replay ghép seed, cặp tướng, request-state và GameOver match đủ để quy đổi thành ảnh hưởng tỷ lệ thắng.

## Deterministic strategy telemetry

Bộ đo chạy candidate local và pinned upstream baseline trên cùng 20 request-shaped fixture (18 active và 2 choose-card) cho ba nhóm đã triển khai. Evidence metadata-only nằm tại [SMARTAI_PROMPT4_DETERMINISTIC_TELEMETRY_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_DETERMINISTIC_TELEMETRY_2026-10-21.json); chỉ lưu skill/surface, trạng thái reply, lớp chất lượng target, điểm giá trị và chi phí bounded, không lưu card ID, target ID, hand hoặc general bí mật.

| Chỉ số deterministic | Baseline | Candidate |
|---|---:|---:|
| Cơ hội được dựng | 20 | 20 |
| Kích hoạt | 20/20 | 20/20 |
| Reply hợp lệ | 20/20 | 20/20 |
| Miss cơ hội | — | 0 |
| Target-quality ở các case có target | — | 18/18 (100%) |
| Tổng chi phí bounded | 92 | 68 |

Chi phí là thang đo fixture, không phải đơn vị tài nguyên trong luật; riêng `hs__qiangxi` quy đổi nhánh mất 1 HP thành 40 điểm để không coi reply không có subcard là miễn phí. Baseline là chính sách chọn raw/first-legal trong fixture, không phải native historical replay. Vì vậy kết quả này đóng gate decision/request local của ba nhóm, nhưng `winRateAvailable=false` và không thể dùng để tuyên bố candidate thắng nhiều hơn.

## Native baseline A/B readiness

Đã thêm một cờ QA-only `ServerConfig.tqsPrompt4Baseline`. Khi cờ này được bật trong runtime cô lập, SmartAI bỏ qua đúng 18 strategy Prompt 4 đã chọn để đi qua default/fallback path; strategy không thuộc 18 skill vẫn giữ nguyên. Cờ mặc định tắt, không được thêm vào production config và không thay đổi cơ chế skill phía server. Test `test:prompt4` kiểm tra candidate → baseline → khôi phục cấu hình với strategy `hs__wusheng` và strategy ngoài nhóm `zhiheng`.

Readiness này đã được dùng cho một ma trận paired native cô lập. Artifact metadata-only tại [SMARTAI_PROMPT4_NATIVE_AB_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_NATIVE_AB_2026-10-21.json) giữ hash runtime/package/catalog, kết quả ghép và counter đã sanitize; không giữ log thô, credential, private hand/general hoặc payload request.

## Native paired A/B — bốn hoán vị ghế

Đã chạy **8/8 trận native hoàn tất `GameOver`**: candidate và baseline cùng seed `1780421000`, cùng roster `r1`, cùng offer 10 tướng, cùng bốn hoán vị ghế `A/B/C/D`, mỗi trận có 2 client loopback và 2 native BOT. Analyzer ghép được **4/4 cặp**, không có missing, duplicate, input mismatch hoặc roster/seat mismatch; runtime/package/catalog identity khớp.

| Chỉ số | Baseline | Candidate |
|---|---:|---:|
| Trận một-winner | 4/4 | 4/4 |
| Win-rate trong mẫu nhỏ | 100% | 100% |
| General-pair decision accepted | 8/11 | 8/8 |
| General-pair fallback / invalid | 3 / 3 | 0 / 0 |

Paired win-rate delta là **0** với `n=4`, CI 95% `[0, 0]`. Đây chỉ là kết quả của một seed, một roster và một ma trận 4 hàng; không phải bằng chứng causal hay population-level. Analyzer trả `READY_FOR_TUNING_REVIEW` và integrity/sample gate của ma trận PASS.

Trong aggregate AI metrics của bốn trajectory, candidate có **752 request, 342 accepted, 410 fallback, 154 invalid, 249 no_decision**, so với baseline **783, 412, 371, 85, 278**. Vì vậy candidate giảm 31 request nhưng tăng 39 fallback và 69 invalid. Đây chưa phải attribution causal — trajectory gameplay khác nhau và counter bao gồm cả lớp default/long-tail — nhưng gate “không phát sinh request error mới” vẫn **OPEN**, cần review trước khi mở nhóm 4.

Ở 18 skill đã chọn, native run chỉ quan sát được `hs__longdan` `3/3` accepted, `hs__wusheng` `15/15` và `hs__zhiheng` `10/10`; 15 skill còn lại không có bucket trong mẫu này, không được diễn giải là không có cơ hội. Native target-quality/resource-value và denominator opportunity/miss theo từng skill vẫn chưa có.

## Generic chooser request-safety — native exploratory probe

Đã sửa ba adapter dùng chung cho active chooser: [`choose_players_skill.lua`](../../runtime/packages/freekill-core/standard/aux_skills_dir/choose_players_skill.lua), [`choose_cards_skill.lua`](../../runtime/packages/freekill-core/standard/aux_skills_dir/choose_cards_skill.lua) và [`ex__choose_skill.lua`](../../runtime/packages/freekill-core/standard/aux_skills_dir/ex__choose_skill.lua). Adapter hiện đọc strategy an toàn, replay card selection trước target selection khi target phụ thuộc card, loại card/target disabled hoặc trùng, kiểm tra min/max và `feasible()`, rồi trả `nil` để Room fallback khi reply không hợp lệ. Không thay đổi cơ chế skill phía server.

Regression local kiểm tra cả active chooser và card chooser: reply rỗng/cancelable không còn được serialize thành request giả hợp lệ; lựa chọn hợp lệ vẫn được replay và chấp nhận. Evidence native metadata-only nằm tại [SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_2026-10-21.json).

| Counter của cùng scenario/plan seed | Pre-fix | Fixed |
|---|---:|---:|
| Tổng request | 156 | 95 |
| Accepted | 68 | 46 |
| Fallback | 88 | 49 |
| Invalid | 41 | 12 |
| `no_decision` | 47 | 35 |
| `AskForUseActiveSkill` native (`total/fallback/invalid/no_decision`) | `31/23/16/7` | `6/1/1/0` |
| `AskForUseActiveSkill` accepted **suy ra** (`total - fallback`) | `8` | `5` |
| Pair decision (`records/accepted`) | `3/2` | `2/2` |

Cả hai biến thể đều chạy với 2 client loopback + 2 native BOT, nhận `GameOver`, không có public skill log và đã đóng port QA sau run. **Hiệu chỉnh provenance:** log runtime ghi command bucket theo thứ tự `total:fallback:invalid:no_decision`, còn artifact thăm dò lịch sử đã gán nhầm ba nhãn `accepted/fallback/invalid` cho các vị trí `fallback/invalid/no_decision`. Vì vậy **23** ở pre-fix là fallback, **không phải accepted**; accepted command chỉ có thể suy ra bằng `total - fallback` (8 pre-fix, 5 fixed). Không tồn tại counter native accepted độc lập theo command. Giữ nguyên artifact lịch sử để truy vết; bản đối chiếu log native (chỉ lưu metadata) là [SMARTAI_PROMPT4_ACTIVE_COUNTER_RECONCILIATION_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_ACTIVE_COUNTER_RECONCILIATION_2026-10-21.json). Báo cáo safety sau khi hiệu chỉnh là [SMARTAI_PROMPT4_REQUEST_SAFETY_REVIEW_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_REQUEST_SAFETY_REVIEW_2026-10-21.json); nhãn sai trong artifact gốc không còn dùng để tính accepted.

Đây **không phải** kết luận fixed làm giảm request lỗi trong trận thường: cùng catalog/scenario/plan seed nhưng pair selection và trajectory của mẫu thăm dò khác nhau; pre-fix có bucket `choose_players_skill`, fixed run không có bucket đó. Native binary lịch sử là bản static legacy dùng bridge auth cục bộ, không phải bằng chứng auth/deploy production. **Đã hoàn tất** probe QA riêng với semantic roster/fixedHands và `player.ai:makeReply()` thật cho ba generic chooser qua `AskForUseActiveSkill`; native feasibility và fingerprint ghép được 6/6. Chi tiết nằm ở phần native chooser ở đầu báo cáo. FNV32 chỉ là guard bounded, không chứng minh toàn bộ engine state tương đương; full request-safety vẫn **OPEN** đến khi có denominator, native reason/target/resource telemetry đủ 18 skill. Không mở nhóm 4 từ counter lịch sử.

## Observed native match telemetry

Run mới nhất dùng candidate runtime cô lập và cùng runner `--audit-bots`, với 2 client loopback và 2 native BOT. Hai client đều nhận GameOver, quay về lobby và disconnect sạch; browser errors là `0`. Artifact metadata-only tại [SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json).

| Chỉ số của một trận native | Kết quả |
|---|---:|
| Tổng request AI | 247 |
| Accepted | 142 |
| Fallback | 105 |
| Invalid | 7 |
| `no_decision` | 95 |
| Skill label hợp lệ chỉ gồm chữ/số/ký tự giới hạn | 21 |
| Nhãn skill chỉ gồm chữ số | 0 |

Trong 18 skill Prompt 4 đã chọn, chỉ `hs__wusheng` xuất hiện trong mẫu này (`7/7` accepted); 17 skill còn lại không xuất hiện và không được diễn giải là “không có cơ hội” hoặc “bỏ lỡ”. Các fallback cho thấy còn phần long-tail/default AI cần đối chiếu, nhưng không đủ để suy ra hồi quy hay hiệu quả causal từ một trận. Native metrics là opt-in, chỉ ghi counter và label an toàn; raw log, card/target ID, hand/general state, prompt, account và credential không được giữ lại.

Đối soát lại các bucket command của chính trận này xác nhận `invalid=7` gồm `PlayCard=5` và `AskForUseActiveSkill=2`; `otherFallback=3` đều thuộc `EmptyRequest` sau khi tách `invalid=7` và `no_decision=95` ra khỏi `fallback=105`. Parser chưa có reason/detail từng command trong artifact đã lưu, nên chưa xác định nguyên nhân semantic hoặc phân bổ lỗi cho riêng 18 skill. Artifact đối soát: [SMARTAI_PROMPT4_REQUEST_SAFETY_FOLLOWUP_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_REQUEST_SAFETY_FOLLOWUP_2026-10-21.json).

**Forensic follow-up log gốc (21/10/2026, metadata-only):** đọc lại log candidate trong runtime QA cô lập, dùng các dòng `[AI_MATCH_METRICS]` làm ranh giới; xác định duy nhất trận `247` request ở dòng 501–630 trong 10 summary. Analyzer [`smart-ai-prompt4-observed-reason-provenance.ts`](/Users/otada/Documents/GitHub/tqs/game/web/scripts/smart-ai-prompt4-observed-reason-provenance.ts) kiểm khớp cả per-command, per-skill và `105/105` dòng `[AI] fallback` với artifact observed gốc. Các trận lịch sử khác trong cùng log có nhãn skill legacy và chỉ dùng làm mốc ranh giới; không đưa các dòng của chúng vào tổng. Artifact mới [`SMARTAI_PROMPT4_OBSERVED_REASON_PROVENANCE_2026-10-21.json`](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_OBSERVED_REASON_PROVENANCE_2026-10-21.json) chỉ giữ số đếm theo command/reason/detail, không lưu log thô, prompt, card/target ID, hand/general hay credential.

| Command (fallback) | Reason và số lần | Invalid / no_decision |
|---|---|---|
| `PlayCard` (42) | `invalid_strategy_reply=5`, `no_decision=37` | `5 / 37` |
| `AskForUseActiveSkill` (4) | `illegal_reply=2` (`feasibility_rejected=2`), `no_strategy=2` | `2 / 2` |
| `AskForUseCard` (27) | `no_decision=15`, `no_strategy=12` | `0 / 27` |
| `AskForSkillInvoke` (24) | `no_decision=1`, `no_strategy=23` | `0 / 24` |
| `AskForCardChosen` (5) | `no_strategy=5` | `0 / 5` |
| `EmptyRequest` (3) | `unsupported_command=3` | `0 / 0` |

Reason toàn trận: `invalid_strategy_reply=5`, `illegal_reply=2`, `no_decision=53`, `no_strategy=42`, `unsupported_command=3`, tổng `105`; detail invalid duy nhất là `feasibility_rejected=2`. Đối chiếu source: `SmartAI:handlePlayCard()` (`ltk/server/ai/smart_ai.lua`) đánh dấu `invalid_strategy_reply` khi strategy trả reply không rỗng nhưng khác bảng; handler `AI:validateReply()` (`ltk/server/ai/ai.lua`) có nhánh `handler:feasible()` trả false và phát `feasibility_rejected`. Đây là vị trí logic tương ứng với **loại lỗi**, chưa thể truy ngược strategy/skill gây ra năm hay hai lần lỗi từ log metadata. Dòng fallback cũ không có room ID, nên việc cách ly giả định các trận được log tuần tự. Kết luận tổng thể vẫn `REQUEST_SAFETY_OPEN`; không suy ra causal baseline/candidate, tần suất cơ hội của 18 skill hoặc giá trị target/card/resource.

Mẫu một trận ở trên vẫn chỉ là observed candidate smoke; bằng chứng paired đầy đủ hơn nằm trong section và artifact A/B ngay phía trên. Cả hai bằng chứng đều chưa đủ để mở nhóm 4: cần denominator cơ hội theo skill, target/resource telemetry native, ma trận seed/roster rộng hơn và review aggregate `invalid/fallback` trước khi kết luận.

## Kiểm thử và gate

Đã quan sát PASS:

- `npm --prefix game/web run test:prompt4` — 5/5: inventory baseline/candidate, cờ baseline QA-only, nhóm 1, nhóm 2 và nhóm 3; nhóm 2 bao gồm response/use dispatcher bounded, nhóm 3 bao gồm target/resource và card-choice dispatcher bounded.
- `npm --prefix game/web run test:prompt4:telemetry` — 1/1: 20/20 deterministic activation, 20/20 legal reply, 0 miss, target-quality 18/18 và không có strategy error.
- `npm --prefix game/web run audit:prompt4:telemetry` — candidate local đối chiếu pinned baseline, `winRateAvailable=false`; evidence metadata-only đã lưu trong artifact nêu trên.
- `npm --prefix game/web run test:prompt4:match-metrics` — 4/4: parse/aggregate counter native, reject bucket malformed/payload-like/numeric-only và tạo delta candidate-baseline deterministic.
- `npx tsx game/web/scripts/general-pair-winrate.ts ... --baseline-branch baseline --candidate-branch candidate --strict` — analyzer `READY_FOR_TUNING_REVIEW`: 8/8 parsed runs, 4/4 paired rows, zero identity/input/roster mismatch, full-match paired delta `0` với `n=4`.
- `npm run typecheck:all`.
- `npm --prefix game/web run test:smart-ai` — 9/9: bổ sung regression cho generic active chooser, `choose_cards_skill` và `ex__choose_skill`.
- `npm --prefix game/web run test:general-pair-winrate` — 7/7.
- `npm --prefix game/web run test:hidden-rule-contract` — 8/8.
- `luac -p` trên ba generic chooser Lua đã sửa — PASS.
- `npm --prefix game/web run audit:skill-activation -- --json` — `pass=true`, `hardFailures=[]`; 25 mẫu `contextRequired` chỉ là giới hạn context fixture, không phải hard failure.
- `git diff --check`.
- Local native candidate smoke mới nhất bằng `game/web/scripts/multiplayer-e2e/run.ts --audit-bots`: 4 ghế gồm 2 client loopback và 2 native BOT, runtime MD5 `86c3575c4f35e5a781c3384c5d421d88`, `GameOver` ở cả 2 client, lobby/disconnect sạch, browser errors `0`; metadata-only match counters tại [SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json). Smoke artifact trước đó vẫn được giữ riêng tại [SMARTAI_PROMPT4_LOCAL_NATIVE_MATCH_2026-10-21.json](/Users/otada/Documents/GitHub/tqs/docs/web-client/SMARTAI_PROMPT4_LOCAL_NATIVE_MATCH_2026-10-21.json).

Không phát sinh request error mới trong các fixture bounded; không đưa private hand/general data vào quyết định hoặc artifact. Skill activation audit không thay thế deterministic gameplay replay/device QA.

Trong native run mới có quan sát fallback ở các lớp vận hành như `no_decision`, `no_strategy`, `invalid_strategy_reply`, `unsupported_command` và `feasibility_rejected`; probe generic chooser fixed vẫn có `12` invalid aggregate. Đây là tín hiệu cần đối chiếu bằng matched request-state replay, không phải bằng chứng candidate đã hồi quy hay đã phủ đủ 18 skill; artifact chỉ giữ counter bounded, không giữ raw log hoặc payload.

## Backlog sau nhóm 3

Shortlist sáu kỹ năng đã chọn hiện không còn item chưa triển khai: `aocai`, `beizhu`, `dimeng`, `choufa`, `cunsi`, `duanfa` đều đã chuyển sang `ai_handler` và có fixture riêng. Phần long-tail còn lại gồm **101 default handlers** đã có backlog thứ tự trong artifact riêng; thứ tự chỉ dùng `generalCount`, `occurrenceCount`, decision-surface và ID ổn định, không giả tạo strategic score. Chưa tự động mở rộng sang chúng chỉ từ số lần xuất hiện trong registry.

Bước tiếp theo là review aggregate `invalid/fallback`, thu thêm ma trận seed/roster với catalog cố định, và mở rộng native telemetry để có opportunity/miss, target-quality và resource-value denominator theo skill. Chỉ sau khi các gate này sạch mới đánh giá mở nhóm 4. Các trận local là bằng chứng end-to-end của runtime cô lập, không phải QA-host/device sign-off; remote QA replacement đang giữ package cũ khác hash candidate và không được dùng thay thế. Hiện chưa có dữ liệu đủ để tuyên bố hiệu quả causal hoặc tần suất sử dụng theo skill trong population match.
