# Audit luật Quốc Chiến: source gốc và React đang deploy

> Audit cập nhật 16/10/2026 sau CP13 hidden Chế Man trên tuyến Render → Oracle (giờ Việt Nam). Đây là tài liệu canonical cho câu hỏi “đã chơi được đến đâu”, không phải danh sách mọi commit lịch sử.

## Kết luận

React hiện tại là client của FreeKill, không phải một bản port luật sang TypeScript. Luật vẫn được thực thi bởi FreeKill C++ và Lua package đã pin. Vì vậy cần tách hai câu hỏi:

1. Server còn chạy luật gốc không? — Có, trong phạm vi runtime/package đang được bundle.
2. React có render và trả lời được mọi state/request do luật gốc phát sinh không? — Chưa.

Bản candidate hiện đạt **MVP browser có server thật**. Tuyến **Render → Oracle replacement đã đạt parity identity/vận hành và gameplay bounded** cho release web/runtime CP09; CP10 bổ sung hidden Ách Tuyệt, CP11 bổ sung hidden Độc Phu, CP12 bổ sung hidden Gian Chí và CP13 bổ sung hidden Chế Man trên `fk.DamageCaused` ở cả chủ/phó, bên cạnh Di Kế và Fuyin. CP13 cài QA revision mới chỉ để quan sát event trước `preventDamage()`; diff này không đổi luật production. Web artifact Render vẫn là candidate CP09. Đây vẫn chưa là **full rule parity**, chưa đóng `PLAYABLE_MOBILE` và chưa phải official release. Các batch hosted CP08 khác được giữ riêng dưới nhãn historical.

## Identity đang kiểm tra

| Hạng mục | Giá trị |
| --- | --- |
| URL | `https://tqs-mobile-candidate.onrender.com` |
| Live health | `200 / ok` |
| Runtime package | 14 package |
| Live bundle | 5.279 file |
| Runtime MD5 | `43b6cdade072b75f93b9d49b3384f08f` |
| Bundle hash | `04e2e885b9ac56c3` |
| Render deployment | [`dep-db8j9gei0phs73fs8pcg`](https://dashboard.render.com/web/srv-db63aclckfvc73bvrli0/deploys/dep-db8j9gei0phs73fs8pcg), commit `798dc2e4` |
| Public web artifact | HTML SHA-256 `591c51f15482d78267b3db4c48b150d20747d5bf83631f01c335e7799e114012` |
| Release candidate | UI/dịch hotfix trên branch `codex/cp89-render-current`; dashboard `Deploy succeeded | Live`, health `200 / ok` |
| Render → Oracle hosted route | Gateway `:10000 -> 161.33.209.212:9527`; CP13 QA revision hiện hành PASS Chế Man `DamageCaused` chủ/phó; Di Kế/Fuyin/Ách Tuyệt/Độc Phu/Gian Chí có bounded evidence trên các revision QA trước cùng web/runtime identity |
| Release status | Candidate để smoke test, chưa official |
| NATIVE-LOCAL identity hiện hành | C++ source pin `b8a2ad4…`; runtime `flist.txt` MD5 `4ab95597f67f54f9a789e8bdcc5aa160`; 14 package pin + server-only `tqs_qa`; browser artifact `dist/index.html` SHA-256 `7c34d09358070e84c3e2b3bf078333b81d4fed17549d4e2d9a2f1c2ade1c8f99`. `RELEASE.json` không pin đúng flist này, nên chỉ là local/unpinned |
| NATIVE-LOCAL QA package evidence | Các scenario local giữ identity riêng trong từng evidence JSON; evidence staged gần nhất của Liệt Cung dùng revision `a3618958…`. Không dùng dòng này để suy ra identity Oracle. |
| Evidence native-local trước đó | Các identity staged của Yiji/Xiaoji/Guanxing/Yingzi/Tiandu/Phản Gián… giữ trong từng evidence JSON; không lặp hash ở bảng này |
| Probe native remote cũ cho Thiên Đố | Lượt thử trước replacement bị dừng trước readiness gate (`nativeQaGateSeen=false`); evidence [`1792066870927`](../../scratch/evidence/reconnect-failure-1792066870927.json). Đây là **diagnostic lịch sử**, không dùng để đánh giá `FinishJudge`; đã được supersede bởi identity Oracle replacement bên dưới |
| Cài đặt native local | Lua 5.4 + `luasocket`/`luafilesystem` và package QA; ca Thiên Hương dùng runtime cô lập `flist MD5 79ef20f9a8fff39dc92310500269add0`, ca Đoạn Trường dùng `flist MD5 cc9ffae8858f3fff68f4b4f4c3d1bc9b`; chỉ phục vụ kiểm thử cục bộ, **không phải Oracle/production** |
| Oracle replacement package identity | `freekill-hegemony-qa` / `161.33.209.212`; runtime MD5 `43b6cdade072b75f93b9d49b3384f08f`; Lua `5.4.8` + LuaSocket/LuaFileSystem; 14/14 package pin + hardening; current `tqs_qa` revision `2b9a9f34154c6089ae6b05eda4c07abffc2924e3`, package SHA `bc358d3ff0ba5e71d75b156225ba9e1d530707e8390b36441864423c7f9d22f8`, catalog SHA `6eaf5a692434162d6d87c540065e5f7b75f935ca8a9546cc6322c78ccc51028e`; service enabled/active, port 9527 reachable |
| Oracle hidden-trigger QA | Current CP13: Chế Man `DamageCaused` chủ/phó hosted PASS với revision `2b9a9f34…`; CP09–CP12 evidence dùng các revision QA trước và được giữ nhãn bounded/historical relative to current package. QA luôn ở `qa_packages/tqs_qa`, ngoài public `packages/` |
| CP92/CP96 UI + lifecycle hotfix | Artifact đã build/typecheck/release-verify PASS; root `dist/` đồng bộ `game/web/dist`; deployment cuối và byte probe được ghi ở các dòng trên |
| Hotfix hiện hành | Commit `798dc2e4` đã Live trên Render; đây vẫn là candidate để smoke test, không phải official |

`CP90` (pile/tay bài), `CP91` (skill dock/time bar/action row/sorter), CP93, CP94 và CP96 UI đã được đưa vào artifact candidate và được Render deploy.

Probe public của deployment `dep-db8j9gei0phs73fs8pcg` trả `healthz=ok`, HTML SHA-256 `591c51f1…`, manifest `5.279` file với runtime MD5 `43b6cdad…`. Login thật, hidden Di Kế positive, hidden Fuyin, hidden Ách Tuyệt, hidden Độc Phu, hidden Gian Chí và hidden Chế Man chủ/phó đã đi xuyên gateway tới Oracle replacement; đây là hosted bounded acceptance, không phải full gameplay acceptance hoặc official release. CP11–CP13 không thay HTML/runtime artifact Render.

Re-validation local/native sau CP96 UI hiện ở catalog/source `57/57`, `test:qa-server-contract` **44/44**, Wasmoon/React Lua E2E `63/63` (bằng chứng trước CP11), hidden-skill lifecycle `520/520`, slot-route `155.168/155.168`, skill activation `0` hard failure. CP13 Oracle package hiện hành có Chế Man chủ/phó PASS; Di Kế, Fuyin, Ách Tuyệt, Độc Phu và Gian Chí vẫn có bounded evidence trên các revision QA trước cùng web/runtime identity. Ma trận effect native-local hiện là `29/607` cặp trên `16/53` event kinds; bổ sung thêm Ân Oán `TargetConfirmed` main/deputy từ evidence native C++/Lua local; scenario hosted/Oracle là bounded, chưa phải full matrix. `fazheng-enyuan` broad contract vẫn là scope riêng cần hoàn thiện.

Runtime source hiện có hardening ở `ServerPlayer:prelightSkill`, `ServerPlayer:addFakeSkill` và `Room:handlePrelight`. `install-packages.sh` đã áp dụng chúng vào runtime native local và Oracle replacement; native verifier và hosted identity đều PASS. `render.yaml` đã ghim `FK_HOST` vào replacement, nên các deployment sau tiếp tục đi cùng tuyến Render → Oracle này.

Regression source-law gate `npm --prefix game/web run test:hidden-rule-contract` hiện **8/8 PASS**. Gate này khóa đúng thứ tự và ownership của luật gốc: fake skill phải prelight mới qua `Player:hasSkill`; trigger phải vào `room:useSkill`; kỹ năng `ActiveSkill/ViewAsSkill` của tướng úp phải được chiếu thành regular `PlayCard`, payload phải mang đúng tên skill và server phải đi qua `useSkill`; `SkillEffect` gọi `revealBySkillName` trước `fk.SkillEffect`/callback; route chủ được ưu tiên rồi mới fallback phó; prelight `true` chỉ nhận fake skill của đúng player; `hideGeneral()` re-attach phải phát lại `PrelightSkill=true`; và toàn bộ **607/607** trigger pair non-delay không có custom predicate ungated. Inventory pinned cũng xác nhận các active/ViewAs skill thuộc tướng không bị đánh dấu `cardSkill`, tránh rơi vào nhánh effect của lá bài vốn không mở tướng. Bốn continuation hậu-kích hoạt (`耀武`/`Deathed`, `闺秀`/`GeneralRemoved`, `除害`/`TurnEnd`, `放权`/`TurnEnd`) được allowlist bằng marker state cụ thể, không phải ngoại lệ im lặng. Từ commit `f6598486`, `npm --prefix game/web run build` bắt buộc chạy gate này trước khi tạo artifact, nên đây là build guard tự động chứ không chỉ là kiểm tra thủ công. Đây là **SOURCE contract regression**, không phải 607 effect cases native.

## Hợp đồng runtime Lua native

Đây là lỗi môi trường đã lặp lại và phải khóa ở launcher, không xử lý bằng việc đổi `PATH` thủ công theo từng phiên:

- `freekill-asio` gọi worker bằng tên literal `lua5.4`; `scripts/lua-runtime.sh` chỉ nhận binary `lua5.4`/`lua-5.4`, kiểm tra chính xác `_VERSION == Lua 5.4`, rồi đặt lại `PATH` cho child process.
- Helper đặt `LUA_PATH`/`LUA_CPATH` tới tree Lua 5.4 của runtime và fail-closed nếu không load được `socket` hoặc `lfs`. Vì vậy Lua 5.5 hoặc Lua 5.4 thiếu module không thể mở server rồi mới crash ở room đầu tiên.
- `scripts/run-server.sh` và `scripts/verify-install.sh` dùng cùng helper; vận hành native phải đi qua `run-server.sh`, không gọi binary trực tiếp.
- Bằng chứng local hiện hành: catalog/source scenarios **57/57**, `test:qa-server-contract` **44/44** subtests, launcher preflight PASS, Lua 5.4 + 18 extension; các scenario hidden main/deputy đã có evidence được liệt kê duy nhất ở bảng bên dưới. CP13 Oracle package hiện hành có Chế Man chủ/phó hosted PASS; CP09–CP12 evidence của các skill khác dùng QA revision trước và không bị dùng để suy ra current package. Corpus 51 run cũ được tách khỏi current proof. Full matrix và official LIVE vẫn mở.

Ghi chú môi trường: native local được biên dịch từ commit C++ pin trên macOS. Harness tạm ngoài repository chỉ thay cách kiểm tra tiến trình con (`waitpid`) vì upstream dùng `/proc`, vốn không có trên macOS; patch này không nằm trong source/deploy và không được coi là thay đổi production/Oracle. Kết quả native local chứng minh vòng đời Lua/C++ và bridge của các scenario, không chứng minh binary Linux đang chạy trên VM.

Audit reconnect cũng đã tìm thấy và sửa một lỗi thật ở host boundary: `Client:addSkill(..., true)` giữ fake skill trong `player_skills`, rồi `ClientPlayer:sendDataToUI()` phát lại snapshot qua cả nhánh regular và fake. `hostLua.ts` hiện bọc đúng snapshot path, loại bản regular trùng tên trước khi phân loại fake/regular cho React. Probe dùng chính trạng thái `Client:addSkill` đạt **520/520** và `Client:loseSkill` dọn đúng **520/520** trên toàn bộ skill ID hidden hợp lệ, gồm cả 15 delay-trigger fallback; đây là SOURCE/LOCAL evidence, chưa phải native-live evidence.

Một phép thử native bổ sung đã cố ý ngắt transport khi `AskForSkillInvoke` readiness gate của hidden Di Kế còn pending. FreeKill hủy request khi actor disconnect (`hidden-yiji QA gate was cancelled`), rồi cho phép login lại nhưng không còn pending gate để phục hồi; vì vậy đây là **OPEN/giới hạn semantics reconnect của request đang chờ**, không phải bằng chứng React làm mất Di Kế. Không dùng ca này để nâng mức PASS; reconnect sau state thật và reconnect của các request khác vẫn phải được kiểm riêng theo từng family.

## Luật gốc cần đối chiếu

Nguồn luật chính:

- [`new_hegemony_mode.lua`](../../runtime/packages/hegemony/pkg/gamemodes/new_hegemony_mode.lua): setup, lượt, hidden general, HP, phe, thắng, reward/punishment, mode settings.
- [`hegemony_rule.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/hegemony_rule.lua): GameStart, reveal, Battle Royal trigger, GameOverJudge, GeneralShown và rare treasure.
- [`util.lua`](../../runtime/packages/hegemony/util.lua): so phe, expected kingdom, wild kingdom, founding/build country và Hegemony marks.
- Các skill luật: [`vanguard.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/vanguard.lua), [`companion_skill.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/companion_skill.lua), [`wild_skill.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/wild_skill.lua), [`new_battle_royal.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/new_battle_royal.lua), [`new_battle_royal_event.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/new_battle_royal_event.lua), [`weimu.lua`](../../runtime/packages/hegemony/pkg/standard/skills/weimu.lua).

Các nhóm luật không được bỏ sót trong scope 14 package:

- Chọn hai tướng, ẩn/lộ tướng, tướng chính/phụ, tính HP và các mark.
- Chu kỳ lượt, card/target/response, reward và punishment khi chết.
- Phe thường, wild/ambitious, chọn kingdom và founding/build country.
- Vanguard, Yin-Yang Fish, Companion, Alliance, Rare Treasure, Formation, Command, Lord, dual faction và transformation.
- Battle Royal cũ/mới, bao gồm Peach view-as và các event theo round.
- Winner getter, surrender, lord death, shuffle/conversion và các card/skill của 14 package.

## Case P0 — Quách Gia úp và Di Kế sau khi nhận sát thương

Đây là điều kiện đã kiểm tra riêng, không gộp vào “skill activation” chung.

### Luật nguồn đã xác nhận

- [`new_hegemony_mode.lua:34-44`](../../runtime/packages/hegemony/pkg/gamemodes/new_hegemony_mode.lua:34) ghi rõ tướng úp không có kỹ năng; muốn phát động phải mở tướng. Trigger skill muốn được hỏi ở thời điểm tương ứng phải được **prelight** trước.
- Quách Gia Quốc Chiến là `hs__guojia` và có `hs__yiji` trong [`standard/init.lua:56-62`](../../runtime/packages/hegemony/pkg/standard/init.lua:56). Di Kế lắng nghe `fk.Damaged` trong [`yiji.lua:1-45`](../../runtime/packages/hegemony/pkg/standard/skills/yiji.lua:1).
- `Player:hasSkill` chỉ coi fake skill là có hiệu lực khi skill nằm trong `prelighted_skills` ([`player.lua:1022-1027`](../../runtime/packages/freekill-core/ltk/core/player.lua:1022)).
- `ServerPlayer:prelightSkill` phải giữ projection idempotent: runtime source đã dùng `table.insertIfNeed` cho skill và related skills, khớp với client ([`serverplayer.lua:519-543`](../../runtime/packages/freekill-core/ltk/server/serverplayer.lua:519)); [`Room:handlePrelight`](../../runtime/packages/freekill-core/ltk/server/room.lua:79) chỉ nhận `true` khi skill hiện là fake skill của chính player và chỉ nhận `false` khi server còn giữ lựa chọn prelight đó, nên payload giả mạo không thể prelight skill sẽ xuất hiện về sau hoặc kích hoạt nhánh đăng ký room ngoài ý muốn. Khi `hide/transform/swap` gắn lại một skill đã từng prelight, [`ServerPlayer:addFakeSkill`](../../runtime/packages/freekill-core/ltk/server/serverplayer.lua:494) phát lại `PrelightSkill=true` ngay sau `AddSkill`, đồng bộ live dashboard với state engine và reconnect snapshot. Pipeline native [`install-packages.sh`](../../deploy/freekill-native/scripts/install-packages.sh) áp dụng cả ba hardening vào checkout upstream và [`verify-install.sh`](../../deploy/freekill-native/scripts/verify-install.sh) fail-closed nếu thiếu; pipeline, runtime local và Oracle replacement đều PASS. Old VM chưa được cập nhật và vẫn giữ làm rollback/reference.
- Khi skill được phát động, [`skill.lua:32-36`](../../runtime/packages/freekill-core/ltk/server/events/skill.lua:32) gọi `revealBySkillName` trước effect; hàm này mở đúng chủ tướng/phó tướng chứa skill ([`serverplayer.lua:656-675`](../../runtime/packages/freekill-core/ltk/server/serverplayer.lua:656)).
- `HegLogic:attachSkillToPlayers` chỉ gắn skill hợp lệ cho vị trí: skill có `DeputyPlace` không được gắn vào chủ tướng, skill có `MainPlace` không được gắn vào phó tướng ([`new_hegemony_mode.lua:331-359`](../../runtime/packages/hegemony/pkg/gamemodes/new_hegemony_mode.lua:331)).
- `revealBySkillName` kiểm tra chủ tướng ẩn trước rồi mới kiểm tra phó tướng; vì vậy phải kiểm tra cả hai vị trí, không được suy ra từ một ca chủ tướng duy nhất.

### Invariant vòng đời sau khi lật tướng

Đã đối chiếu cả source vendored và `freekill-core` upstream: `revealGeneral()` gỡ fake skill của slot vừa lật, rồi `changeHero()`/`handleAddLoseSkills()` chuyển nó thành skill thường trước khi `SkillEffect` chạy. Hàm này không xóa riêng phần tử khỏi `prelighted_skills`; đó là state lựa chọn prelight của engine, không đồng nghĩa skill vẫn còn fake. `ClientPlayer:sendDataToUI()` chỉ phát `PrelightSkill` khi `self:isFakeSkill(skill)`, nên sau khi lật React phải thấy fake entry biến mất và regular entry xuất hiện, chứ không được đòi danh sách prelight nội bộ phải rỗng.

Khi một slot đã lật lại được úp bằng luật/skill khác, `hideGeneral()` có thể chuyển skill thường về fake và giữ lựa chọn prelight đã tồn tại. Đây là hành vi của source gốc đang pin; audit không tự ý thêm bước “clear prelight khi reveal”, vì bước đó sẽ thay đổi semantics của các đường `hide/transform/swap` ngoài ca Quách Gia. Runtime đã bổ sung một thông báo đồng bộ sau `AddSkill` khi fake skill được gắn lại, nhưng không thay đổi danh sách prelight nội bộ. Regression đúng cần kiểm: `fake → prelight → SkillEffect → reveal đúng slot → regular`, `regular → hide/transform → fake + PrelightSkill=true`, và không phát lại prelight cho skill đã regular.

Do đó luật đúng là:

| Tình huống | Kết quả đúng |
| --- | --- |
| Quách Gia úp, Di Kế **chưa prelight**, nhận sát thương | Không hỏi Di Kế; không tự mở tướng. |
| Quách Gia úp, Di Kế **đã prelight**, nhận sát thương thật | Hỏi `AskForSkillInvoke`; chọn Kích hoạt sẽ mở Quách Gia rồi chạy Di Kế. |
| Quách Gia đã mở, nhận sát thương | Di Kế xử lý theo trigger thông thường, không còn là ca “mở tướng bằng skill”. |
| Chọn Bỏ qua | Không mở tướng bởi Di Kế và không rút/phân phát 2 lá. |

### Đối chiếu React và phần triển khai hiện tại

React đã triển khai đúng boundary của native client: [`client.lua:737-817`](../../runtime/packages/freekill-core/ltk/client/client.lua:737) phân loại fake trigger/fake active; [`gameStore.ts`](../../game/web/src/store/gameStore.ts) chỉ giữ skill của Self; [`FakeSkillDock.tsx`](../../game/web/src/FakeSkillDock.tsx) gửi prelight; [`RegularSkillDock.tsx`](../../game/web/src/RegularSkillDock.tsx) chỉ hiển thị skill thường ngoài request ở trạng thái khóa; và [`GameplayControls.tsx`](../../game/web/src/GameplayControls.tsx) chỉ cho reply khi Lua đã gửi `SkillButton`. [`connection.ts`](../../game/web/src/engine/connection.ts) giữ wire native `prelight,<skill>,true|false`.

Kết quả **NATIVE-LOCAL bounded PASS 12/12 lõi**, cộng các staged add-on Jizhi/Mingshi/Qianxun, `hs__kongcheng`, `hs__weimu`, Xiaoji, Guanxing, 英姿, Thiên Hương, Đoạn Trường và regression hidden-rehide-yiji main/deputy trên các identity QA riêng: C++/Lua thật, hai browser client và gateway cô lập. Weimu `TargetConfirming` có evidence main [`1792045540754`](../../scratch/evidence/cp08-hidden-weimu-multiplayer-live-1792045540754.json) và deputy [`1792045551855`](../../scratch/evidence/cp08-hidden-weimu-deputy-multiplayer-live-1792045551855.json); `BeforeCardsMove` có evidence main [`1792046419435`](../../scratch/evidence/cp08-hidden-weimu-indulgence-multiplayer-live-1792046419435.json) và deputy [`1792046430676`](../../scratch/evidence/cp08-hidden-weimu-indulgence-deputy-multiplayer-live-1792046430676.json). 英姿 và các ca Đoạn Trường/hidden-rehide-yiji có evidence main/deputy ở bảng dưới. Current Render → Oracle đã bổ sung Lạc Thần và Đoạn Trường main/deputy; không nhập các identity staged thành một ma trận release, đây vẫn là bounded chứ chưa phải official LIVE.

### Case bổ sung — Trương Xuân Hoa úp và Ách Tuyệt trên `fk.DamageCaused`

Luật gốc của [`ejue.lua`](../../runtime/packages/hegemony/pkg/jin_zqdl/skills/ejue.lua) đăng ký `heg__ejue` trên `fk.DamageCaused`. Native chỉ tăng một damage khi người gây sát thương còn `hasSkill(ejue.name)`, lá dùng là `slash`, và phe của mục tiêu vẫn là `unknown`; effect gọi `data:changeDamage(1)`. Vì đây là trigger của tướng ẩn, prelight vẫn là điều kiện để `Player:hasSkill` nhìn thấy fake skill; `SkillEffect` phải mở đúng Trương Xuân Hoa trước callback.

QA fixture giữ Trương Xuân Hoa ở chủ hoặc phó, dùng Sát thật vào mục tiêu Triệu Vân + Trương Phi rồi đánh dấu phe mục tiêu là `unknown` trong director để thỏa đúng predicate của source. Sau khi nhận ra lượt chạy đầu dùng Pháp Chính làm mục tiêu, diagnostic native cho thấy toàn bộ predicate Ách Tuyệt đều đúng nhưng actor mất thêm 1 HP do `ld__enyuan` compulsory chạy sau khi lá Sát đã bị tiêu hao. Đổi **chỉ** deputy của target trong hai catalog `hidden-ejue*` sang Trương Phi đã cô lập được nhiễu fixture; không sửa luật Ách Tuyệt, không sửa runtime combat.

Render → Oracle web/runtime identity với QA revision CP09 đã PASS cả hai vị trí trên C++/Lua thật, hai browser client và gateway:

- **Chủ tướng:** fake Ách Tuyệt xuất hiện trước gate → `AskForSkillInvoke` → `DamageCaused=true` → `SkillEffect=true` → mở đúng chủ tướng → damage thực tế bằng 2; actor không mất HP ngoài ý muốn. Evidence [`cp09-hidden-ejue-multiplayer-live-1792110813862.json`](../../scratch/evidence/cp09-hidden-ejue-multiplayer-live-1792110813862.json).
- **Phó tướng:** cùng chuỗi, mở đúng phó tướng và damage thực tế bằng 2. Evidence [`cp09-hidden-ejue-deputy-multiplayer-live-1792110834017.json`](../../scratch/evidence/cp09-hidden-ejue-deputy-multiplayer-live-1792110834017.json).

Public QA audit của cả hai run ghi `DamageCaused=true; sát thương=2; SkillEffect=true; mở tướng=true` và slot tương ứng. Đây là **hosted bounded evidence** cho một cặp `DamageCaused`, không phải chứng minh toàn bộ 16 cặp `DamageCaused` hay toàn bộ ma trận 607 cặp.

### Case bổ sung — Tư Mã Quýnh úp và Độc Phu trên `fk.DamageCaused`

Luật gốc của [`dufu.lua`](../../runtime/packages/hegemony/pkg/jin_zfxp/skills/dufu.lua) đăng ký `heg__dufu` là `Skill.Compulsory`, với effect trên `fk.DamageCaused`. Callback chỉ hợp lệ khi người gây sát thương còn `hasSkill(dufu.name)` và không có nhân vật khác cùng thế lực; effect gọi `data:changeDamage(1)`. Cùng source skill còn có một effect `fk.DrawNCards` riêng, chưa nằm trong evidence này. Vì đây là kỹ năng bắt buộc của tướng ẩn, không có prompt lựa chọn của người chơi trong luật gốc; QA `AskForSkillInvoke` chỉ là gate deterministic để prelight fixture trước khi phát Sát thật.

QA fixture giữ Tư Mã Quýnh ở chủ hoặc phó, cả hai tướng của actor vẫn úp và actor thuộc Tấn; mục tiêu Triệu Vân + Trương Phi thuộc Thục để thỏa predicate “không có người khác cùng thế lực”. Sau khi prelight, actor dùng Sát thật vào mục tiêu khác thế lực. Native phải nhận `DamageCaused`, mở đúng slot trước `SkillEffect`, tăng damage từ 1 lên 2 và kết thúc sạch.

Render → Oracle web/runtime identity với QA revision CP10 đã PASS cả hai vị trí trên C++/Lua thật, hai browser client và gateway:

- **Chủ tướng:** fake Độc Phu xuất hiện trước gate; sau Sát thật, `DamageCaused=true`, damage tăng từ 1 lên 2 và `SkillEffect` mở đúng chủ tướng. Evidence [`cp10-hidden-dufu-multiplayer-live-1792111636771.json`](../../scratch/evidence/cp10-hidden-dufu-multiplayer-live-1792111636771.json).
- **Phó tướng:** cùng predicate và callback, `SkillEffect` mở đúng phó tướng; damage thực tế bằng 2. Evidence [`cp10-hidden-dufu-deputy-multiplayer-live-1792111621810.json`](../../scratch/evidence/cp10-hidden-dufu-deputy-multiplayer-live-1792111621810.json).

Cả hai run đều ghi public log `Hidden Độc Phu: DamageCaused=true; sát thương=2; SkillEffect=true; mở tướng=true` với slot tương ứng, native QA gate và GameOver/clean disconnect. Đây là **hosted bounded evidence** cho thêm một cặp `DamageCaused`; nó không chứng minh effect `DrawNCards` của Độc Phu hay full rule parity.

### Case bổ sung — Giả Sung úp và Gian Chí trên `fk.DamageCaused`

Luật gốc của [`jianzhi.lua:15-49`](../../runtime/packages/hegemony/pkg/jin_zqdl/skills/jianzhi.lua:15) đăng ký `heg__jianzhi` trên `fk.DamageCaused`. Predicate yêu cầu người gây sát thương chính là chủ skill, damage đủ gây chết mục tiêu (`data.damage >= data.to.hp + data.to.shield`) và người dùng còn ít nhất một lá trên tay. Đây là trigger **tùy chọn**: native mở `AskForSkillInvoke`; nếu chọn kích hoạt, `on_use` bỏ toàn bộ bài trên tay, tăng banner `additional_reward` thêm 2 (để lần giết kế tiếp nhận thưởng 3x), rồi callback `Deathed`/`TurnEnd` reset banner theo luật nguồn.

QA fixture dùng Sát thật có một lá Thiểm làm bài còn lại, mục tiêu Triệu Vân/Trương Phi được đặt 1 HP và bị dọn tay trước khi gây sát thương. Cách này giữ đúng các điều kiện source nhưng loại Peach cứu tự động khỏi fixture. QA readiness gate chỉ chuẩn bị prelight khi Giả Sung còn úp; sau đó request `AskForSkillInvoke` thứ hai là prompt thật của `heg__jianzhi`, không phải một lựa chọn giả từ React. Gói native tự fail trước `GameOver` nếu `DamageCaused`, lethal damage, discard-all-hand, banner thưởng hoặc reveal sai; browser audit đồng thời kiểm chuỗi log công khai, đúng slot và `GameOver`/disconnect của cả hai client.

Render → Oracle web/runtime identity với QA revision CP12 đã PASS cả hai vị trí trên C++/Lua thật, hai browser client và gateway:

- **Chủ tướng:** Gian Chí fake xuất hiện trước gate → prelight → Sát thật chí mạng → `AskForSkillInvoke` thật → bỏ lá Thiểm còn lại → mở Giả Sung ở chủ tướng → mục tiêu chết. Evidence [`cp12-hidden-jianzhi-multiplayer-live-1792112786904.json`](../../scratch/evidence/cp12-hidden-jianzhi-multiplayer-live-1792112786904.json).
- **Phó tướng:** cùng predicate, nhưng native phải mở Giả Sung ở phó tướng; evidence công khai xác nhận hung thủ, discard, lethal damage và reveal slot phó. [`cp12-hidden-jianzhi-deputy-multiplayer-live-1792112874147.json`](../../scratch/evidence/cp12-hidden-jianzhi-deputy-multiplayer-live-1792112874147.json).

Hai evidence CP12 này khớp candidate identity Render (`runtimeMD5=43b6cdad…`, HTML `591c51f1…`) và QA package revision `48725c8a…`; trace owner có hai `AskForSkillInvoke` (readiness gate + prompt source), một `AskForUseActiveSkill`, hai `AddSkillUseHistory`, `GameOver=1` ở cả hai client. Đây là **hosted bounded evidence tại revision QA trước CP13** cho thêm một cặp `DamageCaused` và luật “tướng úp nhưng đã prelight, đủ điều kiện thì được kích hoạt”; không mở rộng thành full rule parity. Chuỗi `[TQS QA]` nội bộ không được UI Render hiển thị, nên evidence không giả vờ coi diagnostic đó là public log; assertion server-side vẫn chạy trước `room:gameOver`.

### Case bổ sung — Ma Tắc úp và Chế Man trên `fk.DamageCaused`

Luật gốc của [`zhiman.lua`](../../runtime/packages/hegemony/pkg/transformation/skills/zhiman.lua) đăng ký `ld__zhiman` trên `fk.DamageCaused`. Khi Ma Tắc gây sát thương lên nhân vật khác và skill đã được prelight, `on_cost` hỏi `AskForSkillInvoke`; nếu chọn kích hoạt, native gọi `data:preventDamage()`, yêu cầu người gây sát thương chọn một lá trong vùng `ej` của mục tiêu rồi `obtainCard`. Sau đó source còn có nhánh cùng thế lực cho mục tiêu tự chọn đổi phó tướng; nhánh đổi phó tướng không nằm trong fixture này.

Điểm kiểm tra chính của user request đã được khóa end-to-end: Ma Tắc vẫn **úp** trước gate, dock chỉ hiển thị fake Chế Man sau prelight; Sát thật tạo `DamageCaused`; prompt thứ hai là invoke thật của `ld__zhiman`, không phải gate QA; `SkillEffect` native mở đúng slot trước effect; damage bị ngăn và trang bị của mục tiêu được lấy. QA observer được đặt ở priority cao hơn vì `preventDamage()` làm `DamageEvent:breakCheck()` dừng observer có priority thấp hơn; observer này chỉ đo event, không can thiệp luật.

Render → Oracle web/runtime identity với QA revision CP13 hiện hành đã PASS cả hai vị trí trên C++/Lua thật, hai browser client và gateway:

- **Chủ tướng:** prelight → Sát thật → invoke Chế Man → lật Ma Tắc ở chủ tướng → chặn damage → lấy Anh Vũ Bôi. Evidence [`cp13-hidden-zhiman-multiplayer-live-1792115111812.json`](../../scratch/evidence/cp13-hidden-zhiman-multiplayer-live-1792115111812.json).
- **Phó tướng:** cùng chuỗi, nhưng native lật Ma Tắc ở phó tướng → chặn damage → lấy Bạch Kỳ Lân. Evidence [`cp13-hidden-zhiman-deputy-multiplayer-live-1792115138764.json`](../../scratch/evidence/cp13-hidden-zhiman-deputy-multiplayer-live-1792115138764.json).

Cả hai evidence đều khớp Render runtime MD5 `43b6cdad…`, HTML `591c51f1…`, QA revision `2b9a9f34…`, package `bc358d3f…`; trace owner có hai `AskForSkillInvoke` (readiness gate + invoke source), một `AskForUseActiveSkill`, một `AskForCardChosen`, `GameOver=1` ở cả hai client. Public audit ghi `DamageCaused=true; ngăn sát thương=true; lấy trang bị=true; SkillEffect=true; mở tướng=true` và đúng slot. Đây là **hosted bounded evidence** cho thêm một cặp `DamageCaused` và xác nhận nghiêm ngặt điều kiện “tướng úp nhưng đã prelight, đủ điều kiện thì được kích hoạt”; không đóng nhánh cùng thế lực/đổi phó tướng hoặc full rule parity.

### Case bổ sung — Tôn Thượng Hương úp và Kiêu Cơ sau khi mất trang bị

Luật gốc trong [`xiaoji.lua:5-20`](../../runtime/packages/hegemony/pkg/standard/skills/xiaoji.lua:5) đăng ký `fk.AfterCardsMove`, chỉ hợp lệ khi `player:hasSkill("hs__xiaoji")` và một move của chính player có `moveInfo.fromArea == Card.PlayerEquip`; effect native rút **1 lá nếu đang là lượt của player, nếu không rút 3 lá**. Vì `hs__xiaoji` là trigger skill của tướng úp, `hasSkill` chỉ đạt khi skill đã được prelight qua bridge; `SkillEffect` native vẫn là nơi reveal đúng slot trước khi callback chạy.

QA native đã kiểm đúng chuỗi này, không giả lập effect bằng React: trước move, Xiaoji là fake và actor vẫn úp cả hai tướng; gate chỉ bật prelight; sau khi equipment thật rời `PlayerEquip`, `AfterCardsMove` gọi `SkillEffect`, lật đúng Sun Shangxiang và chuyển fake → active. Ca chủ tướng rút 3 lá ([`1792047241418`](../../scratch/evidence/cp08-hidden-xiaoji-multiplayer-live-1792047241418.json)); ca phó tướng rút 1 lá ([`1792047253985`](../../scratch/evidence/cp08-hidden-xiaoji-deputy-multiplayer-live-1792047253985.json)). Cả hai chạy qua hai browser client, ghi nhận log công khai và GameOver; bằng chứng này là **NATIVE-LOCAL local/unpinned**, không phải Render/Oracle LIVE.

Hai lần rerun trước [`1792002124241`](../../scratch/evidence/reconnect-failure-1792002124241.json) và [`1792002605900`](../../scratch/evidence/reconnect-failure-1792002605900.json) fail trước cổng QA vì runtime ngoài chưa có package `tqs_qa`; chúng là bằng chứng chẩn đoán boundary package/config, không phải phủ định luật React. Sau khi cài package vào runtime local và lấy manifest thực tế, ma trận đã được chạy lại đầy đủ.

### Case bổ sung — Gia Cát Lượng úp và Quan Tinh ở đầu pha Bắt đầu

Luật gốc trong [`guanxing.lua:16-21`](../../runtime/packages/hegemony/pkg/standard/skills/guanxing.lua:16) đăng ký `fk.EventPhaseStart`, chỉ chạy khi chính player ở `Player.Start` và `player:hasSkill(self)`; effect gọi `room:askToGuanxing`. Đường `askToGuanxing` của core chuyển thành request native `AskForArrangeCards`, lấy số lá bằng số người còn sống nhưng tối đa 5. Vì vậy đây là trigger tùy chọn khác với Di Kế: prelight chỉ làm cho fake skill đủ điều kiện; native event vẫn phải hỏi invoke, mở đúng slot trước `SkillEffect`, rồi chờ dialog sắp xếp thật.

QA native vừa chạy cả hai slot trên cùng runtime local/unpinned: gate gửi prelight khi Gia Cát Lượng còn úp, native `EventPhaseStart` phát `AskForSkillInvoke`, invoke mở đúng chủ/phó, `AskForArrangeCards` nhận hai lá đầu thật và trả chúng về DrawPile, sau đó GameOver/cleanup sạch. Main [`1792047982952`](../../scratch/evidence/cp08-hidden-guanxing-multiplayer-live-1792047982952.json); deputy [`1792047995074`](../../scratch/evidence/cp08-hidden-guanxing-deputy-multiplayer-live-1792047995074.json). Đây là **NATIVE-LOCAL staged**, chưa phải Render/Oracle LIVE.

### Case bổ sung — Chu Du úp và 英姿 trên `fk.DrawNCards`

Luật gốc trong [`yingzi.lua`](../../runtime/packages/standard_ex/pkg/general/skills/yingzi.lua)
đăng ký `ex__yingzi` với `Skill.Compulsory` trên `fk.DrawNCards` và tăng
`data.n` thêm một. `hs__zhouyu` của package `hegemony_standard` thật sự gắn
skill này; vì vậy đây là trigger tự động, không có prompt invoke của 英姿.
Gate `tqs_qa_hidden_yingzi_gate` chỉ giữ room lại để browser gửi prelight khi
Chu Du còn úp, sau đó director chạy cùng chuỗi draw-phase của source:
`EventPhaseStart` → `EventPhaseProceeding` → `DrawNCards` với `n=2` → rút
thật → `AfterDrawNCards`.

Native PASS ở cả hai slot: `SkillEffect` mở đúng Chu Du, `DrawNCards` và
`AfterDrawNCards` quan sát `n=3`, tay actor tăng đúng 3 lá, fake skill chuyển
thành active và không có `AskForArrangeCards`. Evidence main
[`1792055572502`](../../scratch/evidence/cp98-hidden-yingzi-multiplayer-live-1792055572502.json)
và deputy
[`1792055583385`](../../scratch/evidence/cp98-hidden-yingzi-deputy-multiplayer-live-1792055583385.json).
Identity: runtime local/unpinned flist MD5 `e3fa7be9a38d083d09c562dcf1d546d2`,
QA revision `6ed7e3110fb57335d8805fbc70a7a307b099da88`; hash đầy đủ ở bảng
Identity. Đây là **NATIVE-LOCAL staged**, chưa phải Render/Oracle LIVE.

### Case bổ sung — Tiểu Kiều úp và Thiên Hương sau khi nhận sát thương

Luật gốc trong [`tianxiang.lua`](../../runtime/packages/hegemony/pkg/standard/skills/tianxiang.lua) đăng ký `fk.DetermineDamageInflicted`: nếu Tiểu Kiều đã được prelight và còn bài, người chơi phải chọn một lá `heart` trên tay cùng một mục tiêu khác. Sau khi chọn, native `SkillEffect` mở đúng slot trước khi `preventDamage()`, bỏ lá, hỏi nhánh xử lý; nhánh được kiểm là mục tiêu mất 1 HP rồi nhận lại lá từ Draw/DiscardPile.

Điểm dễ review nhầm: vì `on_cost` của Thiên Hương tự gọi `askToChooseCardsAndPlayers`, request `AskForUseActiveSkill` chính là bước invoke của trigger. Source `TriggerSkill:doCost` chỉ phát thêm `AskForSkillInvoke` cho cost kết thúc nhanh; không có prompt invoke thứ hai sau khi chọn bài/mục tiêu. Runner đã được sửa theo semantics này.

QA native chạy bằng C++/Lua thật, hai browser client và runtime cô lập `flist MD5 79ef20f9a8fff39dc92310500269add0`: **main PASS** [`1792050881499`](../../scratch/evidence/cp93-hidden-tianxiang-multiplayer-live-1792050881499.json), **deputy PASS** [`1792050897211`](../../scratch/evidence/cp93-hidden-tianxiang-deputy-multiplayer-live-1792050897211.json). Cả hai evidence đều ghi gate prelight, chọn bài tim + mục tiêu, `SkillEffect`, damage bị chặn, mục tiêu mất HP, trả bài, mở đúng chủ/phó, GameOver/lobby/disconnect sạch. Đây là **NATIVE-LOCAL staged/local-unpinned**, không phải Render/Oracle LIVE.

Hosted probe trước replacement đã fail trước readiness gate — server trả GameOver mà không phát gate `tqs_qa` ([`1792050441784`](../../scratch/evidence/reconnect-failure-1792050441784.json)). Kết luận đó chỉ áp dụng cho endpoint/runtime cũ; không phải lỗi Thiên Hương hay lỗi React. Replacement hiện đã được pin lại và route mới đã có hosted login + Gongqing/Yiji/Jueqing/Jianxiong/Phản Gián/Lạc Thần/Đoạn Trường main/deputy PASS; evidence cũ không được dùng cho release identity hiện hành.

### Case bổ sung — Thái Văn Cơ úp và Đoạn Trường khi chết

Luật gốc trong [`duanchang.lua`](../../runtime/packages/hegemony/pkg/standard/skills/duanchang.lua) đăng ký `fk.Death`, chỉ cho trigger khi người chết còn `hs__duanchang` thật hoặc fake đã prelight (`hasSkill(..., false, true)`) và killer còn sống. Native effect hỏi `AskForChoices` để chọn chủ/phó tướng của killer, ghi mark Đoạn Trường rồi gọi `handleAddLoseSkills`; React không tự chọn slot hay tự gỡ kỹ năng.

QA native giữ Thái Văn Cơ úp cả hai slot, gửi prelight qua fake-skill dock, gọi `room:killPlayer` thật trong room bốn ghế và để FreeKill tự chạy `fk.Death`. Kết quả main và deputy đều: `SkillEffect` thật, người chết được mở đúng cặp slot, chọn Cao Cao ở chủ tướng của killer, `hs__jianxiong` bị gỡ nhưng `fankui` ở phó tướng còn nguyên, sau đó GameOver/result/lobby/disconnect sạch. Runtime `flist MD5 cc9ffae8858f3fff68f4b4f4c3d1bc9b`, QA revision `51bb9d2d…`, package/catalog hash nằm trong evidence; đây là **NATIVE-LOCAL staged**, không phải Render/Oracle LIVE.

Evidence: main [`1792052232281`](../../scratch/evidence/cp08-hidden-duanchang-multiplayer-live-1792052232281.json), deputy [`1792052245231`](../../scratch/evidence/cp08-hidden-duanchang-deputy-multiplayer-live-1792052245231.json).

### Regression lifecycle — Quách Gia úp, Di Kế lật rồi úp lại

Luật nguồn giữ `prelighted_skills` khi `hideGeneral()` chuyển skill thường về
fake: hàm gỡ skill hiện tại, gắn lại fake skill cho đúng slot và
`ServerPlayer:addFakeSkill()` phát lại `PrelightSkill=true` nếu lựa chọn
prelight vẫn còn ([`serverplayer.lua:494-510`](../../runtime/packages/freekill-core/ltk/server/serverplayer.lua:494), [`serverplayer.lua:688-727`](../../runtime/packages/freekill-core/ltk/server/serverplayer.lua:688)). Vì vậy không được xóa prelight chỉ vì một lần reveal trước đó.

QA native gọi damage thật khi Quách Gia còn úp và đã prelight, để FreeKill tự
phát `AskForSkillInvoke`/`SkillEffect`, reveal đúng slot và phân phối 2 lá Di
Kế. Ngay sau effect, QA gọi `hideGeneral()` thật cho slot vừa reveal rồi kiểm
tra selected general đã về `anjiang`, `hs__yiji` là fake, vẫn `isPrelighted`
và `hasSkill`, không còn bản regular trùng tên. Cả main và deputy đều PASS
với hai browser client, GameOver/result/lobby/disconnect sạch:

- Main: [`cp95-hidden-rehide-yiji-multiplayer-live-1792054011035.json`](../../scratch/evidence/cp95-hidden-rehide-yiji-multiplayer-live-1792054011035.json).
- Deputy: [`cp95-hidden-rehide-yiji-deputy-multiplayer-live-1792054024731.json`](../../scratch/evidence/cp95-hidden-rehide-yiji-deputy-multiplayer-live-1792054024731.json).

Identity của ca này: runtime local/unpinned flist MD5
`3966a400db61802cd94b8d87b4cc54d5`, QA revision
`18969850eab0334778a284869de68de07f04a25f`, package/catalog hash nằm ở
bảng Identity và trong evidence. Đây là **NATIVE-LOCAL**, không phải Render,
Oracle hay official release.

| Scenario | Kiểm tra native | Kết quả | Evidence |
| --- | --- | --- | --- |
| `hidden-yiji/negative` | Quách Gia chủ tướng úp, không prelight, nhận damage | Không hỏi Di Kế, không mở tướng, không di chuyển bài | [`1792070481944`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792070481944.json) |
| `hidden-yiji/positive` | Quách Gia chủ tướng úp, prelight và invoke sau damage | `AskForSkillInvoke` → mở chủ tướng Quách Gia → Di Kế chạy, di chuyển 2 lá | [`1792070469723`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792070469723.json) |
| `hidden-yiji/skip` | Quách Gia chủ tướng úp, prelight nhưng bỏ qua | Có request invoke nhưng không mở tướng, không di chuyển bài | [`1792070503295`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792070503295.json) |
| `hidden-yiji-deputy` | Quách Gia phó tướng úp, prelight và invoke sau damage | `SkillEffect` mở đúng **phó tướng** Quách Gia rồi Di Kế chạy, di chuyển 2 lá | [`1792032529464`](../../scratch/evidence/cp08-hidden-yiji-deputy-multiplayer-live-1792032529464.json) |
| `hidden-rehide-yiji` *(lifecycle regression)* | Quách Gia chủ tướng úp, prelight, nhận damage và được úp lại sau Di Kế | Native reveal → Di Kế chuyển 2 lá → `hideGeneral(false)` → fake `hs__yiji` vẫn prelight, không regular duplicate | [`1792054011035`](../../scratch/evidence/cp95-hidden-rehide-yiji-multiplayer-live-1792054011035.json) |
| `hidden-rehide-yiji-deputy` *(lifecycle regression)* | Quách Gia phó tướng úp, cùng chuỗi reveal → effect → úp lại | Cùng invariant trên, nhưng `hideGeneral(true)` giữ đúng phó tướng fake/prelight | [`1792054024731`](../../scratch/evidence/cp95-hidden-rehide-yiji-deputy-multiplayer-live-1792054024731.json) |
| `hidden-xiaoji` *(staged add-on)* | Tôn Thượng Hương chủ tướng úp, prelight, mất equipment thật | `fk.AfterCardsMove` → `SkillEffect` mở chủ tướng → fake→active → rút 3 lá khi không phải lượt actor | [`1792047241418`](../../scratch/evidence/cp08-hidden-xiaoji-multiplayer-live-1792047241418.json) |
| `hidden-xiaoji-deputy` *(staged add-on)* | Tôn Thượng Hương phó tướng úp, prelight, mất equipment thật | `fk.AfterCardsMove` → `SkillEffect` mở phó tướng → fake→active → rút 1 lá trong lượt actor | [`1792047253985`](../../scratch/evidence/cp08-hidden-xiaoji-deputy-multiplayer-live-1792047253985.json) |
| `hidden-guanxing` *(staged add-on)* | Gia Cát Lượng chủ tướng úp, prelight, vào `EventPhaseStart` ở pha Bắt đầu | `AskForSkillInvoke` → `SkillEffect` mở chủ tướng → `AskForArrangeCards` sắp xếp 2 lá native → trả về DrawPile | [`1792047982952`](../../scratch/evidence/cp08-hidden-guanxing-multiplayer-live-1792047982952.json) |
| `hidden-guanxing-deputy` *(staged add-on)* | Gia Cát Lượng phó tướng úp, prelight, vào `EventPhaseStart` ở pha Bắt đầu | `AskForSkillInvoke` → `SkillEffect` mở phó tướng → `AskForArrangeCards` sắp xếp 2 lá native → trả về DrawPile | [`1792047995074`](../../scratch/evidence/cp08-hidden-guanxing-deputy-multiplayer-live-1792047995074.json) |
| `hidden-yingzi` *(staged add-on)* | Chu Du chủ tướng úp, prelight, vào draw phase native | `DrawNCards` `2→3` → rút 3 lá thật → `AfterDrawNCards` → `SkillEffect` mở chủ tướng | [`1792055572502`](../../scratch/evidence/cp98-hidden-yingzi-multiplayer-live-1792055572502.json) |
| `hidden-yingzi-deputy` *(staged add-on)* | Chu Du phó tướng úp, prelight, vào draw phase native | Cùng chuỗi trên, nhưng `SkillEffect` mở đúng phó tướng và giữ chủ tướng úp | [`1792055583385`](../../scratch/evidence/cp98-hidden-yingzi-deputy-multiplayer-live-1792055583385.json) |
| `hidden-tianxiang` *(staged add-on)* | Tiểu Kiều chủ tướng úp, nhận damage sau khi prelight | `DetermineDamageInflicted` → chọn bài tim/mục tiêu → `SkillEffect` mở chủ tướng → chặn damage → mục tiêu mất 1 HP và nhận lại bài | [`1792050881499`](../../scratch/evidence/cp93-hidden-tianxiang-multiplayer-live-1792050881499.json) |
| `hidden-tianxiang-deputy` *(staged add-on)* | Tiểu Kiều phó tướng úp, nhận damage sau khi prelight | Cùng chuỗi trên, mở đúng phó tướng và giữ chủ tướng úp | [`1792050897211`](../../scratch/evidence/cp93-hidden-tianxiang-deputy-multiplayer-live-1792050897211.json) |
| `hidden-duanchang` *(staged add-on)* | Thái Văn Cơ chủ tướng úp, chết bởi Cao Cao/Tư Mã Ý | `fk.Death` → `SkillEffect` mở chủ tướng → `AskForChoices` chọn Cao Cao → gỡ `Gian Hùng`, giữ `Phản Quỹ` | Current Render → Oracle PASS: [`1792091142647`](../../scratch/evidence/cp08-hidden-duanchang-multiplayer-live-1792091142647.json) |
| `hidden-duanchang-deputy` *(staged add-on)* | Thái Văn Cơ phó tướng úp, chết bởi Cao Cao/Tư Mã Ý | Cùng chuỗi trên, mở đúng phó tướng và chỉ gỡ kỹ năng chủ của killer | Current Render → Oracle PASS: [`1792091155661`](../../scratch/evidence/cp08-hidden-duanchang-deputy-multiplayer-live-1792091155661.json) |
| `hidden-jianxiong` | Cao Cao chủ tướng úp, prelight, nhận Sát thật và chọn lấy lá Sát | `AskForSkillInvoke` → `AskForChoices` → mở đúng chủ tướng → lấy lá Sát từ Processing | [`1792032442802`](../../scratch/evidence/cp08-hidden-jianxiong-multiplayer-live-1792032442802.json) |
| `hidden-jianxiong-deputy` | Cao Cao phó tướng úp, prelight, nhận Sát thật và chọn lấy lá Sát | `AskForSkillInvoke` → `AskForChoices` → mở đúng phó tướng → lấy lá Sát từ Processing | [`1792032450414`](../../scratch/evidence/cp08-hidden-jianxiong-deputy-multiplayer-live-1792032450414.json) |
| `hidden-jizhi` *(staged add-on)* | Hoàng Nguyệt Anh chủ tướng úp, prelight, dùng Quyết Đấu thật | `fk.CardUsing` → invoke tùy chọn → mở chủ tướng → rút 1 lá | [`1792041408616`](../../scratch/evidence/cp95-hidden-jizhi-multiplayer-live-1792041408616.json) |
| `hidden-jizhi-deputy` *(staged add-on)* | Hoàng Nguyệt Anh phó tướng úp, prelight, dùng Quyết Đấu thật | `fk.CardUsing` → invoke tùy chọn → mở phó tướng → rút 1 lá | [`1792041446083`](../../scratch/evidence/cp95-hidden-jizhi-deputy-multiplayer-live-1792041446083.json) |
| `hidden-mingshi` *(staged add-on)* | Khổng Dung chủ tướng úp, nguồn gây sát thương cũng đang úp | `fk.DamageInflicted` bắt buộc → mở chủ tướng → sát thương 1 → 0 | [`1792041475538`](../../scratch/evidence/cp95-hidden-mingshi-multiplayer-live-1792041475538.json) |
| `hidden-mingshi-deputy` *(staged add-on)* | Khổng Dung phó tướng úp, nguồn gây sát thương cũng đang úp | `fk.DamageInflicted` bắt buộc → mở phó tướng → sát thương 1 → 0 | [`1792041487421`](../../scratch/evidence/cp95-hidden-mingshi-deputy-multiplayer-live-1792041487421.json) |
| `hidden-qianxun` *(staged add-on)* | Lục Tốn chủ tướng úp, có Peach hợp lệ để Thuận Thủ nhắm tới | `fk.TargetConfirming` → mở chủ tướng → hủy mục tiêu Thuận Thủ, Peach không bị lấy | [`1792042638322`](../../scratch/evidence/cp95-hidden-qianxun-multiplayer-live-1792042638322.json) |
| `hidden-qianxun-deputy` *(staged add-on)* | Lục Tốn phó tướng úp, có Peach hợp lệ để Thuận Thủ nhắm tới | `fk.TargetConfirming` → mở phó tướng → hủy mục tiêu Thuận Thủ, Peach không bị lấy | [`1792042649386`](../../scratch/evidence/cp95-hidden-qianxun-deputy-multiplayer-live-1792042649386.json) |
| `hidden-qianxun-indulgence` *(staged add-on)* | Lục Tốn chủ tướng úp, bị Lạc Bất Tư Thục nhắm tới | `fk.BeforeCardsMove` → mở chủ tướng → không vào vùng phán xét, chuyển lá vào DiscardPile | [`1792043332346`](../../scratch/evidence/cp08-hidden-qianxun-indulgence-multiplayer-live-1792043332346.json) |
| `hidden-qianxun-indulgence-deputy` *(staged add-on)* | Lục Tốn phó tướng úp, bị Lạc Bất Tư Thục nhắm tới | `fk.BeforeCardsMove` → mở phó tướng → không vào vùng phán xét, chuyển lá vào DiscardPile | [`1792043346201`](../../scratch/evidence/cp08-hidden-qianxun-indulgence-deputy-multiplayer-live-1792043346201.json) |
| `hidden-kongcheng` *(staged add-on)* | Gia Cát Lượng chủ tướng úp, tay thật sự rỗng, nhận Quyết Đấu thật | `fk.TargetConfirming` → `SkillEffect` mở chủ tướng → hủy mục tiêu Quyết Đấu; actor vẫn hết bài | [`1792044149912`](../../scratch/evidence/cp08-hidden-kongcheng-multiplayer-live-1792044149912.json) |
| `hidden-kongcheng-deputy` *(staged add-on)* | Gia Cát Lượng phó tướng úp, tay thật sự rỗng, nhận Quyết Đấu thật | `fk.TargetConfirming` → `SkillEffect` mở phó tướng → hủy mục tiêu Quyết Đấu; actor vẫn hết bài | [`1792044169217`](../../scratch/evidence/cp08-hidden-kongcheng-deputy-multiplayer-live-1792044169217.json) |
| `hidden-weimu` *(staged add-on)* | Giả Hủ chủ tướng úp, prelight, bị Quyết Đấu **đen** nhắm tới | `fk.TargetConfirming` → `SkillEffect` mở chủ tướng → `cancelTarget`; Duel vào DiscardPile, damage `0` | [`1792045540754`](../../scratch/evidence/cp08-hidden-weimu-multiplayer-live-1792045540754.json) |
| `hidden-weimu-deputy` *(staged add-on)* | Giả Hủ phó tướng úp, prelight, bị Quyết Đấu **đen** nhắm tới | `fk.TargetConfirming` → `SkillEffect` mở phó tướng → `cancelTarget`; Duel vào DiscardPile, damage `0` | [`1792045551855`](../../scratch/evidence/cp08-hidden-weimu-deputy-multiplayer-live-1792045551855.json) |
| `hidden-weimu-indulgence` *(staged add-on)* | Giả Hủ chủ tướng úp, prelight, bị Lạc Bất Tư Thục **đen** nhắm tới | `fk.BeforeCardsMove` → `SkillEffect` mở chủ tướng → không vào Judge, mirror sang DiscardPile | [`1792046419435`](../../scratch/evidence/cp08-hidden-weimu-indulgence-multiplayer-live-1792046419435.json) |
| `hidden-weimu-indulgence-deputy` *(staged add-on)* | Giả Hủ phó tướng úp, prelight, bị Lạc Bất Tư Thục **đen** nhắm tới | `fk.BeforeCardsMove` → `SkillEffect` mở phó tướng → không vào Judge, mirror sang DiscardPile | [`1792046430676`](../../scratch/evidence/cp08-hidden-weimu-indulgence-deputy-multiplayer-live-1792046430676.json) |
| `hidden-fankui` *(staged add-on)* | Tư Mã Ý chủ tướng úp, prelight, nhận Sát thật | `fk.Damaged` bắt buộc → mở chủ tướng → `AskForCardChosen` → lấy đúng 1 lá từ nguồn | [`1792037298419`](../../scratch/evidence/cp93-hidden-fankui-multiplayer-live-1792037298419.json) |
| `hidden-fankui-deputy` *(staged add-on)* | Tư Mã Ý phó tướng úp, prelight, nhận Sát thật | `fk.Damaged` bắt buộc → mở phó tướng → `AskForCardChosen` → lấy đúng 1 lá từ nguồn | [`1792037309640`](../../scratch/evidence/cp93-hidden-fankui-deputy-multiplayer-live-1792037309640.json) |
| `hidden-luoshen` *(staged add-on)* | 甄姬 chủ tướng úp, prelight, vào đầu pha Bắt đầu | `EventPhaseStart` → `SkillEffect` → mở chủ tướng → phán xét đen/đỏ → lấy đúng 1 lá đen | Current Render → Oracle PASS: [`1792091111699`](../../scratch/evidence/cp08-hidden-luoshen-multiplayer-live-1792091111699.json) |
| `hidden-luoshen-deputy` *(staged add-on)* | 甄姬 phó tướng úp, prelight, vào đầu pha Bắt đầu | `EventPhaseStart` → `SkillEffect` → mở phó tướng → phán xét đen/đỏ → lấy đúng 1 lá đen | Current Render → Oracle PASS: [`1792091126085`](../../scratch/evidence/cp08-hidden-luoshen-deputy-multiplayer-live-1792091126085.json) |
| `hidden-tiandu` *(staged add-on)* | Quách Gia chủ tướng úp, prelight, có Thiên Đố fake | `room:judge` → `fk.FinishJudge` → lá ở `Card.Processing` → `SkillEffect` mở đúng chủ tướng → lấy lá phán xét; không phát sinh `PlayCard` | [`1792070807248`](../../scratch/evidence/cp08-hidden-tiandu-multiplayer-live-1792070807248.json) |
| `hidden-tiandu-deputy` *(staged add-on)* | Quách Gia phó tướng úp, prelight, có Thiên Đố fake | Cùng chuỗi `FinishJudge`, nhưng `SkillEffect` mở đúng **phó tướng** và lấy đúng lá đang phán xét | [`1792070820876`](../../scratch/evidence/cp08-hidden-tiandu-deputy-multiplayer-live-1792070820876.json) |
| `hidden-kuanggu` *(staged add-on)* | Ngụy Diên chủ tướng úp, prelight, dùng Sát ở khoảng cách 1 | `BeforeHpChanged` đánh dấu → `Damage` → `SkillEffect` mở chủ tướng → chọn `draw1` và rút 1 lá | [`1792072481881`](../../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792072481881.json) |
| `hidden-kuanggu-deputy` *(staged add-on)* | Ngụy Diên phó tướng úp, prelight, dùng Sát ở khoảng cách 1 | Cùng chuỗi trên, nhưng `SkillEffect` phải mở đúng **phó tướng** | [`1792072494326`](../../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792072494326.json) |
| `hidden-liegong` *(staged add-on)* | Hoàng Trung chủ tướng úp, prelight, dùng Sát khi HP mục tiêu không thấp hơn người dùng | `fk.TargetSpecified` → `SkillEffect` mở chủ tướng → chọn `damage +1` → Sát gây đúng 2 damage | [`1792073569775`](../../scratch/evidence/cp08-hidden-liegong-multiplayer-live-1792073569775.json) |
| `hidden-liegong-deputy` *(staged add-on)* | Hoàng Trung phó tướng úp, prelight, cùng điều kiện Liệt Cung | Cùng chuỗi trên, nhưng `SkillEffect` phải mở đúng **phó tướng**; cả hai client thấy `sát thương=2` | [`1792073583047`](../../scratch/evidence/cp08-hidden-liegong-deputy-multiplayer-live-1792073583047.json) |
| `hidden-reveal` | Lục Tốn chủ tướng úp dùng `reveal_skill&` | Chọn `revealMain`; mở đúng Lục Tốn, giữ Tôn Quyền úp, request riêng tư đúng chủ sở hữu | Current Render → Oracle PASS: [`1792091332078`](../../scratch/evidence/cp08-hidden-reveal-multiplayer-live-1792091332078.json) |
| `hidden-reveal-deputy` | Lục Tốn phó tướng úp dùng `reveal_skill&` | Chọn `revealDeputy`; mở đúng Lục Tốn, giữ Tôn Quyền chủ tướng úp | Current Render → Oracle PASS: [`1792091343440`](../../scratch/evidence/cp08-hidden-reveal-deputy-multiplayer-live-1792091343440.json) |
| `hidden-active` | Tôn Quyền phó tướng úp dùng Chế Hành trên `PlayCard` | React chiếu Chế Hành thành regular skill; native mở phó tướng Tôn Quyền, giữ Lục Tốn úp và chạy `SkillEffect` | Current Render → Oracle PASS: [`1792091265053`](../../scratch/evidence/cp08-hidden-active-multiplayer-live-1792091265053.json) |
| `hidden-active-main` | Tôn Quyền chủ tướng úp dùng Chế Hành trên `PlayCard` | Native mở chủ tướng Tôn Quyền, giữ Lục Tốn phó tướng úp và chạy `SkillEffect` | Current Render → Oracle PASS: [`1792091276756`](../../scratch/evidence/cp08-hidden-active-main-multiplayer-live-1792091276756.json) |
| `hidden-fanjian` | Chu Du chủ tướng úp dùng Phản Gián trên `PlayCard` | Source `ex__fanjian` yêu cầu 1 lá trên tay + 1 mục tiêu; native phải mở đúng chủ tướng trước `SkillEffect`, tặng Peach và hỏi mục tiêu chọn mất HP | Native-local và current Render → Oracle PASS: mở đúng chủ tướng, tặng Peach, mục tiêu chọn mất 1 máu | [`1792090932936`](../../scratch/evidence/cp08-hidden-fanjian-multiplayer-live-1792090932936.json) |
| `hidden-fanjian-deputy` | Chu Du phó tướng úp dùng Phản Gián trên `PlayCard` | Cùng hợp đồng nhưng phải mở đúng phó tướng; không gộp với case chủ tướng | Native-local và current Render → Oracle PASS: mở đúng phó tướng, tặng Peach, mục tiêu chọn mất 1 máu | [`1792090944332`](../../scratch/evidence/cp08-hidden-fanjian-deputy-multiplayer-live-1792090944332.json) |
| `hidden-view-as` | Triệu Vân phó tướng úp, chọn Thiểm bằng Long Đảm trên `PlayCard` | Native mở đúng phó tướng trước `SkillEffect`, nhận `hs__longdan`, chuyển Thiểm → Sát và chỉ owner nhận request | Current Render → Oracle PASS: [`1792091289038`](../../scratch/evidence/cp08-hidden-view-as-multiplayer-live-1792091289038.json) |
| `hidden-view-as-main` | Triệu Vân chủ tướng úp, chọn Thiểm bằng Long Đảm trên `PlayCard` | Native mở đúng chủ tướng trước `SkillEffect`, nhận `hs__longdan`, chuyển Thiểm → Sát và chỉ owner nhận request | Current Render → Oracle PASS: [`1792091300559`](../../scratch/evidence/cp08-hidden-view-as-main-multiplayer-live-1792091300559.json) |
| `hidden-dual` *(staged add-on)* | Nhan Lương/Văn Sửu còn úp, prelight Song Hùng ở đầu pha Chơi | Trigger bắt buộc chạy; chọn người, tự bỏ lá Jink đỏ duy nhất (`cancelable=false`), rồi `PlayCard` chuyển Sát đen thành Duel | Current Render → Oracle PASS: [`1792091320794`](../../scratch/evidence/cp08-hidden-dual-multiplayer-live-1792091320794.json) |
| `rescue-normal` | Target hấp hối, actor giữ Peach thường ở room 2 chỗ | Native `AskForUseCard` nhận Peach cứu target; không vào Battle Royal | [`1792032587102`](../../scratch/evidence/cp08-rescue-normal-multiplayer-live-1792032587102.json) |
| `rescue-battle` | Vào Battle Royal, target tự cứu bằng Peach | Peach thường bị luật cấm; SpecialSkills `Quyết chiến` chuyển Peach → Analeptic/Wine và native dùng để hồi sinh | [`1792032617789`](../../scratch/evidence/cp08-rescue-battle-multiplayer-live-1792032617789.json) |
| `founding` | Wild general `heg__jiananfeng` được mở trong setup native | Native phát `AskForChoices` chọn kingdom và nhận đúng một reply; GameOver/cleanup sạch | [`1792032750793`](../../scratch/evidence/cp08-founding-multiplayer-live-1792032750793.json) |

`fankui.lua` là trigger bắt buộc trên `fk.Damaged`, không có một `askToSkillInvoke` tùy chọn thứ hai. QA gate `tqs_qa_hidden_fankui_gate` chỉ tạm dừng để browser gửi `PrelightSkill=true`; acceptance thật là Sát gây damage → `SkillEffect` → mở đúng slot → `AskForCardChosen` → `obtainCard`. Hai ca main/deputy đều kiểm tra nguồn có Slash + Peach, lấy đúng một lá Peach về tay actor và kết thúc GameOver. Current Render → Oracle evidence được giữ ở batch index [`1792090374213`](../../scratch/evidence/cp08-hidden-fankui-multiplayer-live-1792090374213.json) và [`1792090389423`](../../scratch/evidence/cp08-hidden-fankui-deputy-multiplayer-live-1792090389423.json).

`fanjian.lua` là **ActiveSkill thật**, không phải trigger damage: `ex__fanjian` chỉ dùng một lần trong `HistoryPhase`, chọn một lá trên tay và một mục tiêu khác, rồi `showCards` → `obtainCard` → hỏi mục tiêu chọn lộ suit hoặc `loseHp`. Vì `SkillEffect` native gọi `revealBySkillName` trước `on_use`, luật đúng khi Chu Du còn úp là `PlayCard` có skill fake hợp lệ → mở đúng slot → chạy toàn bộ effect gốc; React không được tự tặng bài, tự trừ HP hoặc tự mở nhầm slot. Native-local và current Render → Oracle đều đã khóa main/deputy qua đúng chuỗi PlayCard → mở slot → tặng Peach → mục tiêu chọn mất 1 máu; evidence current nằm ở bảng trên. Hai browser client đều thấy `SkillEffect`, gift và lựa chọn mất HP, sau đó GameOver/cleanup sạch. Case này bổ sung cho, không thay thế, case Quách Gia úp → prelight → `fk.Damaged` → Di Kế.

`luoshen.lua` dùng trigger `fk.EventPhaseStart`, gọi `room:judge` ở đầu pha Bắt đầu; nếu phán xét đen thì đưa lá đen đang ở Processing về tay 甄姬 và có thể tiếp tục phán xét cho tới khi gặp lá đỏ. QA gate `tqs_qa_hidden_luoshen_gate` chỉ chuẩn bị prelight, không thay thế trigger hay phán xét thật. Hai ca main/deputy đã quan sát `SkillEffect`, mở đúng slot, lấy đúng một lá đen và dừng chuỗi ở lá đỏ. Đây là `NATIVE-LOCAL staged`, chưa phải Render/Oracle LIVE.

[`tiandu.lua`](../../runtime/packages/freekill-core/standard/pkg/skills/tiandu.lua) đăng ký `fk.FinishJudge`, chỉ trigger khi người sở hữu đã có skill thật sau khi mở tướng và lá phán xét còn ở `Card.Processing`, rồi `obtainCard(player, data.card, ...)`. Hai scenario `hidden-tiandu` và `hidden-tiandu-deputy` đã chạy native local trên cùng identity: route thật là `room:judge` → `FinishJudge` → `SkillEffect` reveal đúng slot → lấy lá phán xét; không có `PlayCard` giả. Evidence local giữ trong phần staged; current Render → Oracle evidence là [`1792090406635`](../../scratch/evidence/cp08-hidden-tiandu-multiplayer-live-1792090406635.json) và [`1792090422883`](../../scratch/evidence/cp08-hidden-tiandu-deputy-multiplayer-live-1792090422883.json). Probe native remote trước khi thay VM là diagnostic cũ, dừng ở `nativeQaGateSeen=false`; không dùng corpus đó làm current proof.

`kuanggu.lua` đăng ký hai effect liên kết: `fk.BeforeHpChanged` chỉ đánh dấu `data.damageEvent.extra_data.kuanggucheck` khi nguồn gây damage ở khoảng cách 1; sau đó `fk.Damage` mới hỏi `draw1` hoặc `recover`. Hai scenario native-local [`1792072481881`](../../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792072481881.json) và [`1792072494326`](../../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792072494326.json) đã chứng minh Ngụy Diên còn úp nhưng đủ điều kiện vẫn mở và rút 1 lá. Current Render → Oracle evidence trong batch là [`1792090466908`](../../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792090466908.json) và [`1792090479394`](../../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792090479394.json); các cặp `Damage`/related source còn lại vẫn mở.

`liegong.lua` đăng ký `fk.TargetSpecified`: sau khi Hoàng Trung dùng `Sát` chỉ định mục tiêu, predicate nguồn yêu cầu mục tiêu có HP không thấp hơn người dùng; native `on_cost` hỏi đúng lựa chọn `hs__liegong_damage`, rồi `on_use` tăng `data.additionalDamage` thêm 1. Hai scenario native-local [`1792073569775`](../../scratch/evidence/cp08-hidden-liegong-multiplayer-live-1792073569775.json) và [`1792073583047`](../../scratch/evidence/cp08-hidden-liegong-deputy-multiplayer-live-1792073583047.json) đã khóa `TargetSpecified → SkillEffect → damage+1` khi tướng còn úp. Current Render → Oracle evidence là [`1792090441906`](../../scratch/evidence/cp08-hidden-liegong-multiplayer-live-1792090441906.json) và [`1792090454554`](../../scratch/evidence/cp08-hidden-liegong-deputy-multiplayer-live-1792090454554.json); 30 cặp `TargetSpecified` còn lại vẫn mở.

[`jizhi.lua:13-21`](../../runtime/packages/hegemony/pkg/standard/skills/jizhi.lua:13) đăng ký `fk.CardUsing` và chỉ cho phép lá Common Trick chưa chuyển hóa; sau khi người chơi invoke, native `SkillEffect` mở slot sở hữu skill rồi rút 1 lá. [`mingshi.lua:15-23`](../../runtime/packages/hegemony/pkg/standard/skills/mingshi.lua:15) đăng ký `fk.DamageInflicted` với `Skill.Compulsory`, chỉ chạy khi nguồn còn một general `anjiang`, rồi `changeDamage(-1)`. [`qianxun.lua:5-55`](../../runtime/packages/hegemony/pkg/standard/skills/qianxun.lua:5) có hai nhánh: `fk.TargetConfirming` hủy mục tiêu `snatch`, và `fk.BeforeCardsMove` lọc `indulgence` đi vào `Card.PlayerJudge`, gọi `cancelMove` rồi mirror sang `Card.DiscardPile`. [`kongcheng.lua`](../../runtime/packages/hegemony/pkg/standard/skills/kongcheng.lua) đăng ký `fk.TargetConfirming`, yêu cầu đúng `player:isKongcheng()` và lá `slash`/`duel`, sau đó gọi `cancelTarget(player)`. [`weimu.lua:1-12`](../../runtime/packages/hegemony/pkg/standard/skills/weimu.lua:1) là `Skill.Compulsory` trên `fk.TargetConfirming`: target phải là chính player, skill phải được prelight, card phải là Trick màu đen, rồi `cancelTarget(player)`; [`weimu.lua:14-56`](../../runtime/packages/hegemony/pkg/standard/skills/weimu.lua:14) lọc delayed Trick đen vào `Card.PlayerJudge`, gọi `cancelMove` và mirror sang `Card.DiscardPile`. Native-local đã khóa đủ predicate/reveal-before-effect; current Render → Oracle batch đã PASS Cơ Trí, Tuần Tầm cả hai nhánh, Không Thành và Vi Mộ cả hai nhánh ở main/deputy; evidence index nằm ở bảng current hosted bên dưới.

Các test LOCAL bổ trợ (reducer **40/40**, connection 28/28, browser E2E 20/20, Wasmoon/React E2E 63/63, catalog/source scenarios **57/57**, `test:qa-server-contract` **40/40** subtests) kiểm privacy, lifecycle, wire payload và gate UI. QA contract khóa trực tiếp luật source của `new_hegemony_mode`, `hs__yiji`, `ex__fanjian`, `hs__tiandu`, `hs__kuanggu`, `hs__liegong`, `heg__ejue`, `hs__xiaoji`, `hs__guanxing`, `ex__yingzi`, `hs__tianxiang`, `hs__duanchang`, `Player:hasSkill`, `TriggerSkill`, thứ tự reveal-before-effect, re-hide/prelight retention, Lua 5.4 module preflight và luật Peach/Analeptic của Battle Royal. Chúng không được dùng thay cho bảng native ở trên. Khi runtime/package identity đổi, phải chạy lại acceptance tương ứng; mỗi nhóm staged giữ identity riêng. Kết quả này không chứng nhận full gameplay hosted CP09, official release hoặc `PLAYABLE_MOBILE`.

### P0 edge-rule source law đã đối chiếu

- `rescue-normal`: `game_rule.lua` cho người cứu bên ngoài dùng pattern `peach`; catalog cố ý đặt Peach ở `actor`, target đang hấp hối. Native QA đã PASS `AskForUseCard` và hồi sinh target.
- `rescue-battle`: `new_battle_royal.lua` chỉ view-as Peach thành `analeptic` và prohibit Peach chưa chuyển hóa. Vì chỉ người đang hấp hối được tự dùng thêm `analeptic` trong `AskForPeaches`, catalog phải đặt Peach ở `target`, không phải actor. Native QA đã PASS SpecialSkills `Quyết chiến` → native Analeptic rescue; event round/thiết lập winner vẫn chưa exhaustive.
- `founding`: QA đặt `heg__jiananfeng` vào wild, gọi đường `GeneralShown` của native mode và đã quan sát `AskForChoices` kingdom thật; state phe sau lựa chọn, reward/punishment và winner transition vẫn mở.

### Audit source toàn bộ mặt skill úp

Lệnh `npm --prefix game/web run audit:hidden-skills` đã chạy trên 14 package pin cùng runtime Wasmoon, dùng chính classifier của `runtime/packages/freekill-core/ltk/client/client.lua` và cùng bộ lọc `MainPlace/DeputyPlace` của `HegLogic`:

| Chỉ số | Kết quả |
| --- | ---: |
| Tướng active / vị trí chủ + phó | 301 / 602 |
| Tham chiếu skill hợp lệ sau lọc vị trí | 1.039 |
| Skill ID duy nhất đã gọi qua `Client:addSkill(..., true)` | 520 |
| Fake trigger usable / regular active-view-as | 403 / 141 |
| Skill có cả hai projection | 24 |
| Skill có native fake-loss nhưng regular fallback lúc add | 15 |
| Tham chiếu Tỏa định kỹ sau lọc vị trí | 217 |
| Tướng active có helper `reveal_skill&` | 105 |
| Skill im lặng vì `visible=false` | 0 |
| Effect surface từ object runtime FreeKill | active 92; ViewAs 31; trigger 418; status 92 |
| Trigger event kinds của skill úp | 57 event kinds; `Damaged` 53, `EventPhaseStart` 111, `AfterCardsMove` 38, `CardUsing` 34, `Damage` 26 |
| Kiểm tra `AddSkill` native classification | 520/520 PASS |
| Kiểm tra `LoseSkill` native lifecycle classification | 520/520 PASS |
| Replay event native `AddSkill/LoseSkill` qua reducer React | 521/521 PASS (`520` skill ID + `reveal_skill&`) |
| Replay privacy theo Self cho Add/Lose | 1.042/1.042 PASS (2 kiểm tra/contract) |
| Kiểm tra helper `reveal_skill&` Add/Lose projection | 105/105 + 105/105 PASS |
| Kiểm tra native `reveal_skill&:canUse` theo slot | 205/205 PASS |
| Kiểm tra source route `revealBySkillName` trên cặp chủ/phó hợp lệ | 155.168/155.168 PASS; 0 conflict |
| Kiểm tra prelight sync qua `ClientPlayer:sendDataToUI` | 403/403 PASS |
| Kiểm tra server prelight idempotency | 1/1 PASS; bật lặp → tắt một lần xoá sạch projection |
| Kiểm tra fake-skill reattach giữ prelight | 1/1 PASS; `AddSkill(fake)` → `PrelightSkill=true` khi engine vẫn giữ prelight |
| Kiểm tra reconnect snapshot fake → native projection qua host boundary | 520/520 PASS trên toàn bộ skill ID hidden hợp lệ; gồm pure trigger, pure Active/ViewAs, dual và delay-fallback |
| Kiểm tra reconnect từ state thật sau `Client:addSkill(..., true)` | Add 520/520, Lose 520/520 PASS; regular, fake trigger, dual và delay-trigger fallback không còn bị phát trùng hoặc treo projection |

Đây là **SOURCE/LOCAL projection + lifecycle + slot-route PASS**, không phải 520 live effect cases: nó chứng minh event `AddSkill/LoseSkill` nguyên bản của `client.lua` được replay qua reducer React cho toàn bộ 520 skill ID và helper `reveal_skill&`, không bị rơi khi tách fake trigger, regular Active/ViewAs, dual projection, loss lifecycle, privacy theo Self, reconnect/prelight sync và route chủ/phó hợp lệ. Audit bổ sung inventory từ chính object runtime: 92 active surface, 31 ViewAs, 418 trigger effect surface và 92 status surface; trigger surface trải trên 57 event kinds. Các số effect surface có thể tính cả related effect của cùng skill ID, nên không cộng thành tổng skill mới. Route audit mô phỏng đúng thứ tự source `revealBySkillName` (kiểm tra chủ tướng ẩn trước, sau đó phó tướng) trên 155.168 cặp skill-slot hợp lệ; không có trường hợp skill chỉ hợp lệ ở phó tướng nhưng bị route nhầm sang chủ tướng. Có 2 anomaly raw-list của `yizhi` giữa `m_heg__jiangwei` và `ld__jiangwei`, nhưng hai tướng cùng `trueName` và bị `Room:makeGeneralPile` loại khỏi cặp hợp lệ khi `disableSameConvert=false`; chúng được báo cáo riêng, không bị biến thành PASS giả. Native source hiện có 15 delay-trigger fallback phát `LoseSkill` theo fake channel dù `AddSkill` là regular; reducer đã xử lý để không treo regular entry sau khi tướng lộ. Helper `reveal_skill&` được native chiếu thành regular active entry, không phải prelight trigger; audit đã kiểm đủ 105 tướng active có Tỏa định kỹ, 205 slot chủ/phó đạt điều kiện `canUse` và 403 fake trigger được khôi phục prelight qua `ClientPlayer:sendDataToUI`. Reconnect probe gọi chính `ClientPlayer:sendDataToUI()` qua `FClient.notifyUI`: host phân loại lại snapshot fake thành trigger/regular/dual đúng classifier native cho **520/520 skill ID hidden hợp lệ**; probe bổ sung dùng chính state sau `Client:addSkill(..., true)` đạt **520/520 Add và 520/520 Lose**, bao gồm delay-trigger fallback, bắt được regression duplicate regular và lifecycle stale projection, còn reducer giữ snapshot sau marker `Reconnect` vì marker đến sau `EnterRoom/StartGame` và snapshot. Hiệu ứng cụ thể, điều kiện từng trigger và request chain vẫn phải dùng native scenario/live evidence. Regression `ChangeSelf` cũng đã được sửa để đổi `ownId` trước khi nhận lại `AddSkill`, tránh lẫn skill riêng tư khi chuyển Self.

Bổ trợ, activation-surface audit LOCAL (`npm --prefix game/web run audit:skill-activation`) đã chạy 2.388 general, 4.207 skill ID và 22.761 predicate/request probes: `failed=0`, `hard failure=0`; 25/1.112 request probes và một phần predicate được đánh dấu `context-required` vì cần state trận cụ thể. Đây chỉ là bằng chứng callable path không rơi trong VM, không phải bằng chứng hiệu ứng đã chạy đúng trên C++.

### Ma trận effect của skill tướng úp — audit tự động

Lệnh `npm --prefix game/web run audit:hidden-effects` tách riêng effect-level evidence khỏi projection/activation:

| Phạm vi | Kết quả | Ý nghĩa |
| --- | ---: | --- |
| Source trigger `skill × event`, không gồm delay effect | **607 cặp / 403 skill ID / 53 event kinds** | Tập effect cần native scenario để chứng minh điều kiện và callback thật. |
| Source inventory gồm delay effect | **672 cặp / 57 event kinds** | Khớp boundary inventory rộng của `audit:hidden-skills`; delay effect không đi qua reveal-before-`SkillEffect` như trigger thường. |
| Native-local effect evidence đã map | **29/607 cặp; 16/53 event kinds (~4,8%)** | Chỉ các scenario đã chạy C++/Lua thật trong runtime cô lập; không phải hosted/Oracle/Render. |
| Nhóm đã có evidence | `AfterCardsMove`, `BeforeCardsMove`, `BeforeHpChanged`, `CardUsing`, `Damaged`, `Damage`, `DamageCaused`, `DamageInflicted`, `Death`, `DetermineDamageInflicted`, `DrawNCards`, `EventPhaseStart`, `FinishJudge`, `TargetConfirming`, `TargetSpecified` | Evidence hiện tập trung vào các case hidden đã được dựng, không đại diện toàn bộ event. |

Trong **inventory native-local** còn trống/rủi ro cao gồm `TargetSpecified` (30 skill ID chưa test), `TargetConfirmed` (22), `Damage` (24 skill ID chưa test), `DamageCaused` (12), `CardUseFinished` (16), `EventPhaseStart` (108 skill ID chưa test), `EnterDying` (10), `AskForPeaches` (5), `AskForRetrial` (4), cùng các event `GeneralHidden/GeneralRevealed`, phase transition, death/round và package-specific hooks. Oracle bounded đã bổ sung các contract current, gồm `TargetConfirmed` của Ân Oán và các cặp `DamageCaused` của Ách Tuyệt, Độc Phu, Gian Chí và Chế Man, nhưng chưa phải exhaustive. Vì vậy kết luận hiện tại là **projection/lifecycle/slot-route đã đạt SOURCE/LOCAL; effect parity của skill tướng úp vẫn OPEN**, không được suy ra từ 29 cặp native-local, các bounded Oracle contract hoặc từ 520/520 lifecycle.

### Oracle QA bounded — replacement VM

Ngày 16/10/2026, replacement `freekill-hegemony-qa` (`161.33.209.212`)
được kiểm tra trực tiếp bằng SSH và đúng runtime đang chạy trên VM. Current
CP09 web identity của runner PASS với runtime MD5
`43b6cdade072b75f93b9d49b3384f08f`, 14 package, web `dist/index.html` SHA-256
`591c51f15482d78267b3db4c48b150d20747d5bf83631f01c335e7799e114012`, QA
revision `2b9a9f34154c6089ae6b05eda4c07abffc2924e3`, package SHA
`bc358d3ff0ba5e71d75b156225ba9e1d530707e8390b36441864423c7f9d22f8` và
catalog SHA `6eaf5a692434162d6d87c540065e5f7b75f935ca8a9546cc6322c78ccc51028e`.
`verify-install.sh`, `verify-qa-package.sh`, Lua 5.4.8 + Socket/FileSystem,
service enabled/active và TCP 9527 đều PASS. QA nằm ở `qa_packages/tqs_qa`,
ngoài public `packages/` và không có row trong `packages.db`. QA manifest
current được giữ ở `scratch/live-web-test/current/qa_packages/tqs_qa/package.manifest.json`;
hosted evidence current giữ riêng ở các JSON CP09–CP13 bên dưới.

Current-identity proof dùng isolated local gateway với `FK_HOST=161.33.209.212`,
hai browser client thật và không ghi credential/allowlist name vào evidence:

- **Yiji chủ tướng:** Quách Gia còn úp → prelight Di Kế → nhận damage → `AskForSkillInvoke` → invoke → mở đúng chủ tướng và chuyển 2 lá. [`cp08-hidden-yiji-multiplayer-live-1792088748424.json`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792088748424.json).
- **Yiji phó tướng:** cùng hợp đồng và mở đúng phó tướng. [`cp08-hidden-yiji-deputy-multiplayer-live-1792088763447.json`](../../scratch/evidence/cp08-hidden-yiji-deputy-multiplayer-live-1792088763447.json).
- **Ân Oán chủ tướng:** tướng ẩn được prelight trước `TargetConfirmed`; source Peach đi qua request riêng tới đúng actor đang úp, sau đó mở Pháp Chính và rút đúng 1 lá. [`cp08-hidden-enyuan-multiplayer-live-1792093200457.json`](../../scratch/evidence/cp08-hidden-enyuan-multiplayer-live-1792093200457.json).
- **Ân Oán phó tướng:** cùng hợp đồng ở slot phó; public audit của cả hai client xác nhận `TargetConfirmed`, reveal Pháp Chính và draw 1. [`cp08-hidden-enyuan-deputy-multiplayer-live-1792093226312.json`](../../scratch/evidence/cp08-hidden-enyuan-deputy-multiplayer-live-1792093226312.json).
- **Jueqing chủ tướng:** tướng ẩn + prelight → `PreDamage` → lật Trương Xuân Hoa ở chủ tướng → mất đúng 1 HP; native log xác nhận `damage_event=false`, `skill_effect=true`, `revealed=true`, `slot=main`. [`cp08-hidden-jueqing-multiplayer-live-1792090046211.json`](../../scratch/evidence/cp08-hidden-jueqing-multiplayer-live-1792090046211.json).
- **Jueqing phó tướng:** cùng hợp đồng ở slot phó; native log xác nhận `damage_event=false`, `skill_effect=true`, `revealed=true`, `slot=deputy`. [`cp08-hidden-jueqing-deputy-multiplayer-live-1792090065108.json`](../../scratch/evidence/cp08-hidden-jueqing-deputy-multiplayer-live-1792090065108.json).
- **Jianxiong chủ tướng:** tướng ẩn + prelight → `Damaged` → lật Tào Tháo ở chủ tướng → chọn và nhận đúng 1 lá sát thương; native log `positive-prelight-invoke-obtain`, `invoked=true`, `revealed=true`, `obtained=1`. [`cp08-hidden-jianxiong-multiplayer-live-1792090284132.json`](../../scratch/evidence/cp08-hidden-jianxiong-multiplayer-live-1792090284132.json).
- **Jianxiong phó tướng:** cùng hợp đồng ở slot phó; native log xác nhận `slot=deputy`, `obtained=1`. [`cp08-hidden-jianxiong-deputy-multiplayer-live-1792090299019.json`](../../scratch/evidence/cp08-hidden-jianxiong-deputy-multiplayer-live-1792090299019.json).
- **Fanjian chủ tướng:** ActiveSkill thật trên `PlayCard`; lật Chu Du ở chủ tướng, tặng Đào và mục tiêu chọn mất 1 HP; evidence [`cp08-hidden-fanjian-multiplayer-live-1792090932936.json`](../../scratch/evidence/cp08-hidden-fanjian-multiplayer-live-1792090932936.json).
- **Fanjian phó tướng:** cùng hợp đồng ở slot phó; evidence [`cp08-hidden-fanjian-deputy-multiplayer-live-1792090944332.json`](../../scratch/evidence/cp08-hidden-fanjian-deputy-multiplayer-live-1792090944332.json).
- **Luoshen chủ tướng:** `EventPhaseStart` thật sau prelight; lật Chân Cơ ở chủ tướng, phán xét tiếp tục tới lá đỏ và lấy đúng lá đen; evidence [`cp08-hidden-luoshen-multiplayer-live-1792091111699.json`](../../scratch/evidence/cp08-hidden-luoshen-multiplayer-live-1792091111699.json).
- **Luoshen phó tướng:** cùng hợp đồng ở slot phó; evidence [`cp08-hidden-luoshen-deputy-multiplayer-live-1792091126085.json`](../../scratch/evidence/cp08-hidden-luoshen-deputy-multiplayer-live-1792091126085.json).
- **Duanchang chủ tướng:** `fk.Death` thật; lật Thái Văn Cơ ở chủ tướng, chọn chủ tướng của killer để gỡ Gian Hùng và giữ kỹ năng phó; evidence [`cp08-hidden-duanchang-multiplayer-live-1792091142647.json`](../../scratch/evidence/cp08-hidden-duanchang-multiplayer-live-1792091142647.json).
- **Duanchang phó tướng:** cùng hợp đồng ở slot phó; evidence [`cp08-hidden-duanchang-deputy-multiplayer-live-1792091155661.json`](../../scratch/evidence/cp08-hidden-duanchang-deputy-multiplayer-live-1792091155661.json).
- **ActiveSkill chủ/phó:** Chế Hành được chiếu thành regular `PlayCard`, mở đúng Tôn Quyền và giữ Lục Tốn úp; evidence [`1792091265053`](../../scratch/evidence/cp08-hidden-active-multiplayer-live-1792091265053.json) / [`1792091276756`](../../scratch/evidence/cp08-hidden-active-main-multiplayer-live-1792091276756.json).
- **ViewAsSkill chủ/phó:** Long Đảm mở đúng Triệu Vân, chuyển Thiểm → Sát và giữ request private cho owner; evidence [`1792091289038`](../../scratch/evidence/cp08-hidden-view-as-multiplayer-live-1792091289038.json) / [`1792091300559`](../../scratch/evidence/cp08-hidden-view-as-main-multiplayer-live-1792091300559.json).
- **Dual + explicit reveal:** Song Hùng mở trigger, bỏ nguồn màu và chuyển Sát → Quyết Đấu; `reveal_skill&` mở đúng Lục Tốn ở cả hai slot. Evidence [`1792091320794`](../../scratch/evidence/cp08-hidden-dual-multiplayer-live-1792091320794.json), [`1792091332078`](../../scratch/evidence/cp08-hidden-reveal-multiplayer-live-1792091332078.json) / [`1792091343440`](../../scratch/evidence/cp08-hidden-reveal-deputy-multiplayer-live-1792091343440.json).

Batch CP08 hosted historical dưới đây đều chạy cùng identity `ae598a4c…` /
`f80d346e…`, mỗi dòng đã PASS ở cả chủ và phó. Bảng này chỉ là index truy vết;
không gộp vào CP09 current proof và không chép lại toàn bộ log public:

| Family / nhánh source | Chủ tướng | Phó tướng |
| --- | --- | --- |
| Phản Quỹ — `Damaged` + `AskForCardChosen` | [`1792090374213`](../../scratch/evidence/cp08-hidden-fankui-multiplayer-live-1792090374213.json) | [`1792090389423`](../../scratch/evidence/cp08-hidden-fankui-deputy-multiplayer-live-1792090389423.json) |
| Thiên Đố — `FinishJudge` | [`1792090406635`](../../scratch/evidence/cp08-hidden-tiandu-multiplayer-live-1792090406635.json) | [`1792090422883`](../../scratch/evidence/cp08-hidden-tiandu-deputy-multiplayer-live-1792090422883.json) |
| Liệt Cung — `TargetSpecified` | [`1792090441906`](../../scratch/evidence/cp08-hidden-liegong-multiplayer-live-1792090441906.json) | [`1792090454554`](../../scratch/evidence/cp08-hidden-liegong-deputy-multiplayer-live-1792090454554.json) |
| Cuồng Cốt — `BeforeHpChanged` + `Damage` | [`1792090466908`](../../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792090466908.json) | [`1792090479394`](../../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792090479394.json) |
| Danh Sĩ — `DamageInflicted` | [`1792090498979`](../../scratch/evidence/cp08-hidden-mingshi-multiplayer-live-1792090498979.json) | [`1792090510599`](../../scratch/evidence/cp08-hidden-mingshi-deputy-multiplayer-live-1792090510599.json) |
| Cơ Trí — `CardUsing` | [`1792090522672`](../../scratch/evidence/cp08-hidden-jizhi-multiplayer-live-1792090522672.json) | [`1792090534386`](../../scratch/evidence/cp08-hidden-jizhi-deputy-multiplayer-live-1792090534386.json) |
| Tuần Tầm — Thuận Thủ, `TargetConfirming` | [`1792090550691`](../../scratch/evidence/cp08-hidden-qianxun-multiplayer-live-1792090550691.json) | [`1792090562154`](../../scratch/evidence/cp08-hidden-qianxun-deputy-multiplayer-live-1792090562154.json) |
| Tuần Tầm — Lạc Bất Tư Thục, `BeforeCardsMove` | [`1792090573781`](../../scratch/evidence/cp08-hidden-qianxun-indulgence-multiplayer-live-1792090573781.json) | [`1792090585341`](../../scratch/evidence/cp08-hidden-qianxun-indulgence-deputy-multiplayer-live-1792090585341.json) |
| Không Thành — tay rỗng + `TargetConfirming` | [`1792090601741`](../../scratch/evidence/cp08-hidden-kongcheng-multiplayer-live-1792090601741.json) | [`1792090613228`](../../scratch/evidence/cp08-hidden-kongcheng-deputy-multiplayer-live-1792090613228.json) |
| Vi Mộ — trick đen, `TargetConfirming` | [`1792090624409`](../../scratch/evidence/cp08-hidden-weimu-multiplayer-live-1792090624409.json) | [`1792090636377`](../../scratch/evidence/cp08-hidden-weimu-deputy-multiplayer-live-1792090636377.json) |
| Vi Mộ — Lạc Bất Tư Thục đen, `BeforeCardsMove` | [`1792090647868`](../../scratch/evidence/cp08-hidden-weimu-indulgence-multiplayer-live-1792090647868.json) | [`1792090659457`](../../scratch/evidence/cp08-hidden-weimu-indulgence-deputy-multiplayer-live-1792090659457.json) |
| Tôn Thượng Hương / Xiaoji — `AfterCardsMove` | [`1792090677591`](../../scratch/evidence/cp08-hidden-xiaoji-multiplayer-live-1792090677591.json) | [`1792090689024`](../../scratch/evidence/cp08-hidden-xiaoji-deputy-multiplayer-live-1792090689024.json) |
| Gia Cát Lượng / Guanxing — `EventPhaseStart` + arrange | [`1792090700438`](../../scratch/evidence/cp08-hidden-guanxing-multiplayer-live-1792090700438.json) | [`1792090712283`](../../scratch/evidence/cp08-hidden-guanxing-deputy-multiplayer-live-1792090712283.json) |
| Chu Du / Anh Tư — `DrawNCards` | [`1792090723490`](../../scratch/evidence/cp08-hidden-yingzi-multiplayer-live-1792090723490.json) | [`1792090734613`](../../scratch/evidence/cp08-hidden-yingzi-deputy-multiplayer-live-1792090734613.json) |
| Tiểu Kiều / Thiên Hương — `DetermineDamageInflicted` | [`1792090746545`](../../scratch/evidence/cp08-hidden-tianxiang-multiplayer-live-1792090746545.json) | [`1792090757959`](../../scratch/evidence/cp08-hidden-tianxiang-deputy-multiplayer-live-1792090757959.json) |
| Chu Du / Phản Gián — ActiveSkill `PlayCard` → gift/lose-HP | [`1792090932936`](../../scratch/evidence/cp08-hidden-fanjian-multiplayer-live-1792090932936.json) | [`1792090944332`](../../scratch/evidence/cp08-hidden-fanjian-deputy-multiplayer-live-1792090944332.json) |

Probe Jueqing đã PASS ở identity CP08 sau khi đồng bộ runtime MD5 và sửa
QA observer để quan sát `PreDamage` trước điểm dừng `DamageEvent:breakCheck()`;
đây là thay đổi harness QA, không thay đổi luật Jueqing trong source. Runner
đã xác nhận cả hai browser client thấy log công khai, mở đúng slot và kết thúc
ván sạch. `damage_event=false` là kết quả mong đợi của source
`jueqing.lua`: skill mất HP rồi gọi `data:preventDamage()`.

Các evidence bên dưới là **historical corpus** của identity trước
(`7787544e…`, runtime `0e2e6585…`, package/catalog cũ). Giữ link để truy vết,
nhưng không dùng 51 run này làm bằng chứng current identity:

- **Positive chủ tướng:** [`cp08-hidden-yiji-multiplayer-live-1792079207247.json`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792079207247.json) — fake Di Kế hiển thị khi Quách Gia còn úp → prelight → nhận damage → `AskForSkillInvoke` → invoke → reveal/effect và chuyển 2 lá.
- **Negative chủ tướng:** [`cp08-hidden-yiji-multiplayer-live-1792079225253.json`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792079225253.json) — có damage nhưng không prelight → không hỏi Di Kế/không reveal/không chuyển bài.
- **Skip chủ tướng:** [`cp08-hidden-yiji-multiplayer-live-1792079235732.json`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792079235732.json) — có prelight và request nhưng bỏ qua → không invoke/effect.
- **Positive phó tướng:** [`cp08-hidden-yiji-deputy-multiplayer-live-1792079252023.json`](../../scratch/evidence/cp08-hidden-yiji-deputy-multiplayer-live-1792079252023.json) — invoke sau damage mở đúng phó tướng và chạy Di Kế.
- **Cuồng Cốt chủ/phó:** [`cp08-hidden-kuanggu-multiplayer-live-1792079528760.json`](../../scratch/evidence/cp08-hidden-kuanggu-multiplayer-live-1792079528760.json) và [`cp08-hidden-kuanggu-deputy-multiplayer-live-1792079541579.json`](../../scratch/evidence/cp08-hidden-kuanggu-deputy-multiplayer-live-1792079541579.json) — `BeforeHpChanged` → `Damage` → mở đúng Ngụy Diên ở chủ/phó → bốc 1 lá.
- **Liệt Cung chủ/phó:** [`cp08-hidden-liegong-multiplayer-live-1792079554098.json`](../../scratch/evidence/cp08-hidden-liegong-multiplayer-live-1792079554098.json) và [`cp08-hidden-liegong-deputy-multiplayer-live-1792079565941.json`](../../scratch/evidence/cp08-hidden-liegong-deputy-multiplayer-live-1792079565941.json) — `TargetSpecified` → mở đúng Hoàng Trung ở chủ/phó → chọn `damage +1` → sát thương thực tế 2.
- **Gian Hùng chủ/phó:** [`cp08-hidden-jianxiong-multiplayer-live-1792079796078.json`](../../scratch/evidence/cp08-hidden-jianxiong-multiplayer-live-1792079796078.json) và [`cp08-hidden-jianxiong-deputy-multiplayer-live-1792079808110.json`](../../scratch/evidence/cp08-hidden-jianxiong-deputy-multiplayer-live-1792079808110.json) — `Damaged` → mở đúng Tào Tháo ở chủ/phó → chọn nhận lá Sát.
- **Phản Quỹ chủ/phó:** [`cp08-hidden-fankui-multiplayer-live-1792079820297.json`](../../scratch/evidence/cp08-hidden-fankui-multiplayer-live-1792079820297.json) và [`cp08-hidden-fankui-deputy-multiplayer-live-1792079832566.json`](../../scratch/evidence/cp08-hidden-fankui-deputy-multiplayer-live-1792079832566.json) — `Damaged` → mở đúng Tư Mã Ý ở chủ/phó → chọn lấy một lá từ nguồn.
- **Danh Sĩ chủ/phó:** [`cp08-hidden-mingshi-multiplayer-live-1792079854889.json`](../../scratch/evidence/cp08-hidden-mingshi-multiplayer-live-1792079854889.json) và [`cp08-hidden-mingshi-deputy-multiplayer-live-1792079866657.json`](../../scratch/evidence/cp08-hidden-mingshi-deputy-multiplayer-live-1792079866657.json) — `DamageInflicted` bắt buộc → mở đúng Khổng Dung ở chủ/phó → sát thương giảm về 0.
- **Thiên Đố chủ/phó:** [`cp08-hidden-tiandu-multiplayer-live-1792079878833.json`](../../scratch/evidence/cp08-hidden-tiandu-multiplayer-live-1792079878833.json) và [`cp08-hidden-tiandu-deputy-multiplayer-live-1792079891480.json`](../../scratch/evidence/cp08-hidden-tiandu-deputy-multiplayer-live-1792079891480.json) — `FinishJudge` → mở đúng Quách Gia ở chủ/phó → lấy lá phán xét từ `Card.Processing`.
- **Cơ Trí chủ/phó:** [`cp08-hidden-jizhi-multiplayer-live-1792080047104.json`](../../scratch/evidence/cp08-hidden-jizhi-multiplayer-live-1792080047104.json) và [`cp08-hidden-jizhi-deputy-multiplayer-live-1792080058607.json`](../../scratch/evidence/cp08-hidden-jizhi-deputy-multiplayer-live-1792080058607.json) — `CardUsing` → mở đúng Hoàng Nguyệt Anh ở chủ/phó → native rút 1 lá sau Quyết Đấu.
- **Tuần Tầm chủ/phó:** [`cp08-hidden-qianxun-multiplayer-live-1792080070161.json`](../../scratch/evidence/cp08-hidden-qianxun-multiplayer-live-1792080070161.json) và [`cp08-hidden-qianxun-deputy-multiplayer-live-1792080081278.json`](../../scratch/evidence/cp08-hidden-qianxun-deputy-multiplayer-live-1792080081278.json) — `TargetConfirming` → mở đúng Lục Tốn ở chủ/phó → hủy mục tiêu Thuận Thủ hợp lệ.
- **Không Thành chủ/phó:** [`cp08-hidden-kongcheng-multiplayer-live-1792080195914.json`](../../scratch/evidence/cp08-hidden-kongcheng-multiplayer-live-1792080195914.json) và [`cp08-hidden-kongcheng-deputy-multiplayer-live-1792080207730.json`](../../scratch/evidence/cp08-hidden-kongcheng-deputy-multiplayer-live-1792080207730.json) — tay rỗng + Quyết Đấu → `TargetConfirming` → mở đúng Gia Cát Lượng → hủy mục tiêu.
- **Vi Mộ chủ/phó:** [`cp08-hidden-weimu-multiplayer-live-1792080219554.json`](../../scratch/evidence/cp08-hidden-weimu-multiplayer-live-1792080219554.json) và [`cp08-hidden-weimu-deputy-multiplayer-live-1792080230284.json`](../../scratch/evidence/cp08-hidden-weimu-deputy-multiplayer-live-1792080230284.json) — Quyết Đấu đen → `TargetConfirming` → mở đúng Giả Hủ → hủy mục tiêu.
- **Tôn Thượng Hương/Xiaoji chủ/phó:** [`cp08-hidden-xiaoji-multiplayer-live-1792080336675.json`](../../scratch/evidence/cp08-hidden-xiaoji-multiplayer-live-1792080336675.json) và [`cp08-hidden-xiaoji-deputy-multiplayer-live-1792080347477.json`](../../scratch/evidence/cp08-hidden-xiaoji-deputy-multiplayer-live-1792080347477.json) — `AfterCardsMove` → mất trang bị thật → mở đúng slot → rút bài.
- **Gia Cát Lượng/Guanxing chủ/phó:** [`cp08-hidden-guanxing-multiplayer-live-1792080359329.json`](../../scratch/evidence/cp08-hidden-guanxing-multiplayer-live-1792080359329.json) và [`cp08-hidden-guanxing-deputy-multiplayer-live-1792080370951.json`](../../scratch/evidence/cp08-hidden-guanxing-deputy-multiplayer-live-1792080370951.json) — `EventPhaseStart` → mở đúng slot → `AskForArrangeCards` hoàn tất.
- **Tiểu Kiều/Thiên Hương chủ/phó:** [`cp08-hidden-tianxiang-multiplayer-live-1792080381670.json`](../../scratch/evidence/cp08-hidden-tianxiang-multiplayer-live-1792080381670.json) và [`cp08-hidden-tianxiang-deputy-multiplayer-live-1792080392476.json`](../../scratch/evidence/cp08-hidden-tianxiang-deputy-multiplayer-live-1792080392476.json) — `DetermineDamageInflicted` → chọn bài tim/mục tiêu → mở đúng slot → chặn damage và trả bài.
- **Thái Văn Cơ/Đoạn Trường chủ/phó:** [`cp08-hidden-duanchang-multiplayer-live-1792080404621.json`](../../scratch/evidence/cp08-hidden-duanchang-multiplayer-live-1792080404621.json) và [`cp08-hidden-duanchang-deputy-multiplayer-live-1792080417358.json`](../../scratch/evidence/cp08-hidden-duanchang-deputy-multiplayer-live-1792080417358.json) — `Death` → mở đúng slot → chọn kỹ năng chủ của killer để gỡ.

Bộ 51 run này trước đây đều ghi `result: PASS` với native gate và hai client
quan sát được audit công khai; tuy nhiên chúng thuộc identity cũ. Đây là
**ORACLE QA BOUNDED — HISTORICAL** cho identity/native rule và browser bridge;
phần CP09–CP13 current identity chỉ lấy các ca Di Kế/Fuyin/Ách Tuyệt/Độc Phu/Gian Chí/Chế Man
nêu ở phần current bên trên.
Không thay thế toàn bộ `607` effect pairs, device acceptance hay official release.

### Render → Oracle replacement — CP09 web identity / CP13 QA package current bounded acceptance

Deployment [`dep-db8j9gei0phs73fs8pcg`](https://dashboard.render.com/web/srv-db63aclckfvc73bvrli0/deploys/dep-db8j9gei0phs73fs8pcg), commit
`798dc2e4`, chạy gateway tới replacement `161.33.209.212:9527`. Current
identity gate PASS: health `200 / ok`, public HTML SHA-256
`591c51f15482d78267b3db4c48b150d20747d5bf83631f01c335e7799e114012`, runtime
MD5 `43b6cdade072b75f93b9d49b3384f08f`, 14 package/5.279 file, QA revision
`2b9a9f34154c6089ae6b05eda4c07abffc2924e3`, package SHA
`bc358d3ff0ba5e71d75b156225ba9e1d530707e8390b36441864423c7f9d22f8` và
catalog SHA `6eaf5a692434162d6d87c540065e5f7b75f935ca8a9546cc6322c78ccc51028e`.

- **Di Kế chủ tướng:** PASS — Quách Gia còn úp, fake skill hiển thị ở pre-gate;
  sau damage, `AskForSkillInvoke` và invoke chạy, mở đúng chủ tướng và chuyển 2
  lá. Evidence [`cp08-hidden-yiji-multiplayer-live-1792097106182.json`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792097106182.json).
- **Di Kế phó tướng:** PASS — cùng hợp đồng và mở đúng phó tướng. Evidence
  [`cp08-hidden-yiji-deputy-multiplayer-live-1792097120803.json`](../../scratch/evidence/cp08-hidden-yiji-deputy-multiplayer-live-1792097120803.json).
- **Fuyin chủ tướng:** PASS — Gia Cát Chiêm còn úp nhưng đã prelight; native
  `TargetConfirmed` nhận Sát, `SkillEffect` mở đúng ô chủ tướng và vô hiệu lá
  Sát. Evidence [`cp08-hidden-fuyin-multiplayer-live-1792096610323.json`](../../scratch/evidence/cp08-hidden-fuyin-multiplayer-live-1792096610323.json).
- **Fuyin phó tướng:** PASS — cùng hợp đồng ở ô phó tướng. Evidence
  [`cp08-hidden-fuyin-deputy-multiplayer-live-1792096811597.json`](../../scratch/evidence/cp08-hidden-fuyin-deputy-multiplayer-live-1792096811597.json).
- **Ách Tuyệt chủ tướng:** PASS — Trương Xuân Hoa còn úp nhưng fake skill đã
  prelight; Sát thật vào mục tiêu phe `unknown` → `AskForSkillInvoke` →
  `DamageCaused` tăng từ 1 lên 2, `SkillEffect` mở đúng chủ tướng. Evidence
  [`cp09-hidden-ejue-multiplayer-live-1792110813862.json`](../../scratch/evidence/cp09-hidden-ejue-multiplayer-live-1792110813862.json).
- **Ách Tuyệt phó tướng:** PASS — cùng predicate và callback, mở đúng phó
  tướng, damage thực tế bằng 2. Evidence
  [`cp09-hidden-ejue-deputy-multiplayer-live-1792110834017.json`](../../scratch/evidence/cp09-hidden-ejue-deputy-multiplayer-live-1792110834017.json).
- **Độc Phu chủ tướng:** PASS — Tư Mã Quýnh còn úp và đã prelight; Sát thật
  vào mục tiêu khác thế lực → `DamageCaused` tăng từ 1 lên 2, `SkillEffect`
  mở đúng chủ tướng. Đây là kỹ năng compulsory; `AskForSkillInvoke` trong
  evidence là gate QA chuẩn bị fixture, không phải lựa chọn của Độc Phu.
  Evidence [`cp10-hidden-dufu-multiplayer-live-1792111636771.json`](../../scratch/evidence/cp10-hidden-dufu-multiplayer-live-1792111636771.json).
- **Độc Phu phó tướng:** PASS — cùng predicate và callback, mở đúng phó tướng,
  damage thực tế bằng 2. Evidence
  [`cp10-hidden-dufu-deputy-multiplayer-live-1792111621810.json`](../../scratch/evidence/cp10-hidden-dufu-deputy-multiplayer-live-1792111621810.json).
- **Gian Chí chủ tướng:** PASS — Giả Sung còn úp, fake skill hiển thị trước
  gate; Sát thật gây lethal `DamageCaused`, prompt invoke thật, bỏ toàn bộ tay,
  đặt banner thưởng 3x và mở đúng chủ tướng. Evidence
  [`cp12-hidden-jianzhi-multiplayer-live-1792112786904.json`](../../scratch/evidence/cp12-hidden-jianzhi-multiplayer-live-1792112786904.json).
- **Gian Chí phó tướng:** PASS — cùng predicate và callback, nhưng phải mở Giả
  Sung đúng slot phó; evidence công khai xác nhận trigger, discard, lethal
  damage, death và reveal phó tướng.
  [`cp12-hidden-jianzhi-deputy-multiplayer-live-1792112874147.json`](../../scratch/evidence/cp12-hidden-jianzhi-deputy-multiplayer-live-1792112874147.json).
- **Chế Man chủ tướng:** PASS — Ma Tắc còn úp nhưng đã prelight; Sát thật →
  invoke Chế Man → `DamageCaused` bị ngăn, mở Ma Tắc ở chủ tướng và lấy Anh Vũ
  Bôi từ vùng trang bị mục tiêu. Evidence
  [`cp13-hidden-zhiman-multiplayer-live-1792115111812.json`](../../scratch/evidence/cp13-hidden-zhiman-multiplayer-live-1792115111812.json).
- **Chế Man phó tướng:** PASS — cùng chuỗi, nhưng native mở Ma Tắc ở phó tướng
  và lấy Bạch Kỳ Lân; cả hai client đều thấy log công khai và `GameOver` sạch.
  Evidence [`cp13-hidden-zhiman-deputy-multiplayer-live-1792115138764.json`](../../scratch/evidence/cp13-hidden-zhiman-deputy-multiplayer-live-1792115138764.json).

Hai run CP13 Chế Man quan sát được native QA gate, đúng reveal slot, GameOver và
clean disconnect. Hai run Ách Tuyệt và hai run Độc Phu ghi public log
`DamageCaused=true; sát thương=2; SkillEffect=true; mở tướng=true`; hai run
Gian Chí ghi chuỗi public trigger/discard/lethal/death/reveal tương ứng, còn
QA package kiểm tra `DamageCaused`, hand-empty và banner thưởng trước
`GameOver`. QA được load từ `qa_packages/tqs_qa`, tách khỏi public flist; các
run CP09–CP12 dùng revision QA trước, còn CP13 dùng revision hiện hành
`2b9a9f34…`. Đây là bounded proof cho điều kiện “tướng úp nhưng đủ điều kiện
vẫn kích hoạt”, chưa là full rule parity. CP11–CP13 không thay public Render
artifact; CP13 chỉ cập nhật observer QA để ghi nhận `DamageCaused` trước
`preventDamage()` và không thay luật gốc.

### CP08 hosted batch — historical identity

Deployment [`dep-db8iptu7bikc73e8p100`](https://dashboard.render.com/web/srv-db63aclckfvc73bvrli0/deploys/dep-db8iptu7bikc73e8p100), commit
`93b9f652`, dùng identity trước: runtime MD5 `ae598a4c…`, QA revision
`f80d346e…`, HTML `fa42af15…`, 14 package/5.279 file. Bảng dưới giữ làm
historical index; không gộp vào CP09 current proof nếu chưa rerun.

- **Gongqing chủ tướng:** PASS — fake trigger xuất hiện trước damage gate;
  nhánh tầm thấp gây 1 damage, nhánh tầm cao gây 2 damage, Phan Tuấn mở đúng
  slot; evidence
  [`cp08-hidden-gongqing-multiplayer-live-1792085727624.json`](../../scratch/evidence/cp08-hidden-gongqing-multiplayer-live-1792085727624.json).
- **Gongqing phó tướng:** PASS — cùng hợp đồng ở slot phó; evidence
  [`cp08-hidden-gongqing-deputy-multiplayer-live-1792085744289.json`](../../scratch/evidence/cp08-hidden-gongqing-deputy-multiplayer-live-1792085744289.json).
- **Yiji chủ tướng:** PASS — prelight → damage → invoke → reveal chủ tướng →
  chuyển 2 lá; evidence [`cp08-hidden-yiji-multiplayer-live-1792088748424.json`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792088748424.json).
- **Yiji phó tướng:** PASS — cùng hợp đồng ở slot phó; evidence [`cp08-hidden-yiji-deputy-multiplayer-live-1792088763447.json`](../../scratch/evidence/cp08-hidden-yiji-deputy-multiplayer-live-1792088763447.json).
- **Ân Oán chủ tướng:** PASS — prelight trước `TargetConfirmed` → request Peach riêng → mở Pháp Chính → draw 1; evidence [`cp08-hidden-enyuan-multiplayer-live-1792093571889.json`](../../scratch/evidence/cp08-hidden-enyuan-multiplayer-live-1792093571889.json).
- **Ân Oán phó tướng:** PASS — cùng hợp đồng ở slot phó; evidence [`cp08-hidden-enyuan-deputy-multiplayer-live-1792093587237.json`](../../scratch/evidence/cp08-hidden-enyuan-deputy-multiplayer-live-1792093587237.json).
- **Jueqing chủ tướng:** PASS — fake trigger trước `PreDamage`; lật Trương Xuân Hoa ở chủ tướng, mất 1 HP và chặn `DamageEvent`; evidence [`cp08-hidden-jueqing-multiplayer-live-1792090046211.json`](../../scratch/evidence/cp08-hidden-jueqing-multiplayer-live-1792090046211.json).
- **Jueqing phó tướng:** PASS — cùng hợp đồng ở slot phó; evidence [`cp08-hidden-jueqing-deputy-multiplayer-live-1792090065108.json`](../../scratch/evidence/cp08-hidden-jueqing-deputy-multiplayer-live-1792090065108.json).

Kết luận CP08 historical: batch trên đã PASS bounded ở identity cũ. Nó không
được dùng làm bằng chứng CP09 nếu chưa rerun; full rule parity và ma trận `607`
cặp vẫn OPEN. Current CP13 acceptance trên QA revision hiện hành là Chế Man
chủ/phó; Di Kế, Fuyin, Ách Tuyệt, Độc Phu và Gian Chí được giữ ở phần bounded
trước với revision QA tương ứng của từng run.

## Mức bao phủ hiện tại

| Tầng | Trạng thái | Bằng chứng / giới hạn |
| --- | --- | --- |
| Server authority | **Đạt** | Luật vẫn ở C++/Lua; React không tự quyết winner/faction/damage. |
| Login/lobby/room/bot | **Đạt candidate** | Hosted browser đã login, tạo room, start game và chạy bot. |
| Core card/target/skill | **Đạt bounded** | Ván bot C++ thật đã đi qua reveal, Vô Giải, Sát/target/OK, Cường Tập và GameOver. |
| GameOver/result/lobby/disconnect | **Đạt bounded** | Có evidence hosted; không suy diễn thành full rule coverage. |
| Privacy/public projection | **Đạt một phần tốt** | Có public/private boundary; Self hidden data và đối thủ hidden data được tách. |
| Native request mapping | **Đạt ở source contract** | 17 request families được ánh xạ; audit không thay thế live matrix. |
| Hidden-skill source projection/lifecycle/slot route | **Đạt SOURCE/LOCAL** | 301 tướng active, 602 vị trí, 1.039 reference, 520 skill ID; native `AddSkill`/`LoseSkill` 520/520, replay event qua React 521/521, privacy Add/Lose 1.042/1.042, helper `reveal_skill&` 105/105, `canUse` theo slot 205/205, route `revealBySkillName` 155.168/155.168 trên cặp hợp lệ, prelight sync 403/403, reconnect projection 520/520 và probe state thật `Client:addSkill`/`Client:loseSkill` đều 520/520; chưa chứng minh effect/live parity. |
| Hidden-trigger/prelight + active reveal | **Đạt RENDER → ORACLE bounded + ORACLE/NATIVE-LOCAL mở rộng** | CP09–CP13 current identity đã PASS Di Kế positive, Fuyin `TargetConfirmed`, Ách Tuyệt, Độc Phu, Gian Chí và Chế Man `DamageCaused` chủ/phó với native gate, prelight/reveal đúng slot, chuyển bài, vô hiệu Sát, damage+1, lethal discard/reward và equipment obtain. Với Độc Phu, gate QA không phải prompt của skill compulsory; với Gian Chí và Chế Man, prompt invoke thứ hai là lựa chọn thật của source skill. Chế Man đã khóa cả `AskForCardChosen`/lấy trang bị; nhánh cùng thế lực đổi phó tướng vẫn chưa test. Batch 32 slot/nhánh và các hosted family khác thuộc identity cũ, phải rerun nếu muốn tái sử dụng. Native-local còn các staged add-on; exhaustive effect matrix vẫn mở. |
| Lua runtime launcher/module ABI | **Đạt RENDER → ORACLE bounded** | Oracle replacement chạy Lua 5.4.8, nạp `socket`/`lfs`; CP09 web artifact và CP13 QA package đi qua runtime MD5 `43b6cd…`; old VM vẫn là rollback/reference. |
| Regular-skill dashboard gate | **Đạt NATIVE-LOCAL bounded** | `AddSkill/LoseSkill` của Self, fake active Chế Hành và fake ViewAs Long Đảm → regular dock → native `PlayCard` đã PASS; Phản Gián main/deputy cũng đã PASS native-local theo chuỗi ActiveSkill đầy đủ; các active/ViewAs skill khác chưa có live matrix và hosted/Oracle chưa được verify. |
| Local dialog/skill/card audits | **Đạt local** | Native dialogs 7/7, cards-and-choice 3/3, card selection 4/4, store 40/40, connection 28/28, gameplay 16/16, browser E2E 20/20, Wasmoon/React E2E 63/63 (bằng chứng trước CP11), catalog/source scenarios 57/57 và `test:qa-server-contract` 44/44 subtests; các fixture/pipeline contract này không thay thế C++ live. |
| Full native dialog coverage | **Chưa đạt** | Còn cancellation/expiry/reconnect và các caller Arrange/AG/Move/CustomDialog/ChooseSkill/ChooseGenerals/CardNames/KnownBoth chưa có live matrix đầy đủ. |
| Rescue ngoài Battle Royal | **Đạt NATIVE-LOCAL bounded** | Room 2 chỗ, actor dùng Peach thường cứu target qua `AskForUseCard`; Battle Royal không được bật. Hosted/Oracle chưa verify lại cùng identity. |
| Battle Royal rescue/view-as | **Đạt NATIVE-LOCAL bounded** | Target tự cứu bằng Peach → SpecialSkills `Quyết chiến` → Analeptic/Wine qua native `AskForUseCard`; event theo round và các biến thể khác chưa exhaustive. |
| Wild/founding/kingdom choice | **Đạt NATIVE-LOCAL bounded cho request** | `heg__jiananfeng` wild đã phát `AskForChoices` kingdom và nhận reply; state phe sau chọn, reward/punishment và winner transition chưa đóng. |
| Luật mở rộng theo package | **Chưa đạt exhaustive** | Rare treasure, Alliance, Formation, Command, Lord, dual faction, transformation và package-specific paths mới có source/local/targeted evidence. |
| CP90/CP91 + CP93/CP94/CP96/CP09 UI trên candidate | **Đạt ở artifact/live probe** | CP09 đã deploy; static health/manifest/HTML byte probe PASS. Người dùng còn cần smoketest gameplay nhiều bước; không suy ra full parity. |
| Device/Safari/physical network | **Deferred/waived** | Người dùng miễn nghiệm thu vật lý trong scope hiện tại; đây không phải PASS. |
| Official operations/release | **Chưa đạt** | Cold-start/quota/rollback/SLA và official sign-off còn mở. |

## Gaps phải xử lý trước khi gọi là full parity

### P0 — luật và interaction

- Rerun normal rescue, Battle Royal rescue/view-as và founding trên Oracle replacement; sau đó nếu cần public smoke thì chạy lại qua Render URL. Không gắn Oracle bounded PASS thành hosted/official PASS.
- Hoàn tất wild/founding sau request: `wildChooseKingdom`/`AskForBuildCountry` → state phe mới → winner/reward.
- Có live evidence cho các native family còn mở: `AskForCardChosen`, `AskForPoxi`, `AskForCardsAndChoice`, ArrangeCards, AG, MoveCardInBoard, SkillInvoke và các CustomDialog whitelist.
- Mỗi family phải có ít nhất một ca thành công, một ca cancel/expiry nếu có semantics tương ứng, và một ca cleanup/reconnect.

### P1 — state/presentation

- Package/deploy CP90/CP91 rồi kiểm tra draw pile, discard pile, processing card, Self hand, skill dock, timer và action row trên bundle live.
- Kiểm tra xích, úp mặt, negative HP, hidden/revealed deputy, equipment lifecycle và semantic marks trong một flow C++ thật.
- Rà lại residual live translation; static translation audit không thay thế kiểm tra text runtime.

## Cách đọc evidence

- `SOURCE`: code/skill/caller tồn tại và source contract hợp lệ.
- `LOCAL`: test hoặc Wasmoon/Chrome fixture pass; không chứng minh server C++.
- `NATIVE-LOCAL`: browser + gateway + FreeKill C++/Lua thật chạy trong runtime cô lập; chứng minh native behavior của scenario, nhưng không tự đại diện cho hosted release identity.
- `LIVE`: browser thật → gateway → FreeKill C++ thật, có evidence sanitized.
- `BOUNDED`: chỉ xác nhận đúng scenario được chạy, không mở rộng thành exhaustive.
- Chỉ đổi `[ ]` thành `[x]` trong plan khi evidence đúng tầng acceptance của ticket; không dùng số file, số skill hoặc smoke test để suy ra phần trăm luật đã hoàn thiện.

## Tiêu chí đóng audit

Chỉ có thể kết luận full parity khi: (1) các P0 trên có live evidence với đúng 14-package identity; (2) không còn request rơi vào fallback unsupported trong các scenario acceptance; (3) state public/private, hidden information và reconnect được kiểm chứng; (4) release chứa CP90/CP91 nếu chúng nằm trong scope; và (5) `CODEX_PLAN.md`, `CODEX_STATE.md`, manifest live cùng trỏ đến một release identity duy nhất.

Chi tiết lịch sử cũ nằm trong Git history và các evidence path được dẫn ở các checkpoint; không sao chép lại vào tài liệu trạng thái hiện hành.
