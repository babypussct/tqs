# Audit luật Quốc Chiến: source gốc và React đang deploy

> Audit cập nhật 15/10/2026 19:23 (giờ Việt Nam). Đây là tài liệu canonical cho câu hỏi “đã chơi được đến đâu”, không phải danh sách mọi commit lịch sử.

## Kết luận

React hiện tại là client của FreeKill, không phải một bản port luật sang TypeScript. Luật vẫn được thực thi bởi FreeKill C++ và Lua package đã pin. Vì vậy cần tách hai câu hỏi:

1. Server còn chạy luật gốc không? — Có, trong phạm vi runtime/package đang được bundle.
2. React có render và trả lời được mọi state/request do luật gốc phát sinh không? — Chưa.

Bản candidate hiện đạt **MVP browser có server thật**, nhưng chưa đạt **full rule parity**, chưa đóng `PLAYABLE_MOBILE` và chưa phải official release.

## Identity đang kiểm tra

| Hạng mục | Giá trị |
| --- | --- |
| URL | `https://tqs-mobile-candidate.onrender.com` |
| Live health | `200 / ok` |
| Runtime package | 14 package |
| Live bundle | 5.279 file |
| Runtime MD5 | `c4704cd70bfbce3375c4c123a2443a3f` |
| Bundle hash | `0183516d94e2865f` |
| Release candidate | CP96 UI hotfix trên runtime CP92, UI artifact commit `0cc0d346`; latest redeploy từ HEAD `74a7b30e` |
| Release status | Candidate để test, chưa official |
| NATIVE-LOCAL runtime vừa dùng cho Xiaoji | C++ source pin `b8a2ad48305aea7b55ccca325fcbeb100cb8a01a`, runtime **flist MD5** `0cc149d0fb6b8bd68ae640e9bd7c281e`, 14 package pin + `tqs_qa`, browser artifact SHA-256 `d432f717a938665fab8ae81a6a903aa11f1cfeaa84d5cc0fd62f07572e436893`; `RELEASE.json` không pin đúng flist này nên chỉ ghi nhận là local/unpinned |
| NATIVE-LOCAL QA package vừa dùng cho Xiaoji | QA source `ec6d35ae043a1e5ceda54e333e66661193feb5ec`; manifest SHA-256 `073b25f3f3e1331a1012c87f764c4f35fe19c7a0dbf1064352e91043c433c65d`, package SHA-256 `f95c1b9d0f69db951b8e529064cc9fea08fb8b9ab5dd4589ffd484717fa4fd66`, catalog SHA-256 `d11617ab98a54607aed71cf03546da2c0b1a01458caa9d4d6b4fc319b4c7e9f9`; chứng minh `hs__xiaoji` `AfterCardsMove` ở cả main/deputy |
| NATIVE-LOCAL runtime vừa dùng cho Guanxing | Runtime/flist MD5 `ee6cc20fcb8ac9785939ec222efd8ea0`, 14 package pin + `tqs_qa`, browser artifact SHA-256 `d432f717a938665fab8ae81a6a903aa11f1cfeaa84d5cc0fd62f07572e436893`; runtime không khớp `RELEASE.json`, chỉ là local/unpinned |
| NATIVE-LOCAL QA package vừa dùng cho Guanxing | QA source `e7ae42109cfa3987c35e4ed6966b39500031e4ed`; manifest SHA-256 `520da2f06a76c447679ca850a1d2c39f1dc29c5faf0c4eaef1ca04ef89b34b79`, package SHA-256 `2ea3f192e1c592faf3cd7cfc9a9e05b0e53fe3d74852db53869c22a129fdccfa`, catalog SHA-256 `3574c42ac681444dd0e0e8a6f1c38f37769519122f0b841bf3578a2b8edf9b45`; chứng minh `hs__guanxing` `EventPhaseStart` + `AskForArrangeCards` ở cả main/deputy |
| NATIVE-LOCAL QA package vừa dùng cho hidden-rehide-yiji | Runtime flist MD5 `3966a400db61802cd94b8d87b4cc54d5`, QA source `18969850eab0334778a284869de68de07f04a25f`; manifest SHA-256 `624d6d3d49432ac02e2014bd3f184219d80fb1fa074d700308cf2e107db9d805`, package SHA-256 `11d6e9119a5abe631cb2d6cfb8c784713900a8acc64137f15f142fbbdb610dce`, catalog SHA-256 `81c330c4edc8d5a1ec4388b5c9ca7d485d5c808d6c72a7b7a5a78a8762c4a159`; chứng minh reveal → Di Kế → `hideGeneral()` giữ fake/prelight ở cả main/deputy |
| NATIVE-LOCAL runtime vừa dùng cho hidden-yingzi | Runtime flist MD5 `e3fa7be9a38d083d09c562dcf1d546d2`, 14 package pin + `tqs_qa`, `dist/index.html` SHA-256 `4e7ab8fb6305ef969ec820d6fda7a1944c2d8b0b89169ff433200e48be1f5566`; local/unpinned, không phải Render/Oracle |
| NATIVE-LOCAL QA package vừa dùng cho hidden-yingzi | QA source `6ed7e3110fb57335d8805fbc70a7a307b099da88`; manifest SHA-256 `f28a981e870f91a015d2b17eb40f80a1a26bfed44889cccbbbab9f465f88ef30`, package SHA-256 `14289054acf17a7abf5b5e55bb48bb84901beaa9cde69e25d1e6d71039cecb81`, catalog SHA-256 `cf309a243947843a2a25996f479b502fce0f2cd2d74f8663d37f4a355470ac5f`; chứng minh `ex__yingzi` `DrawNCards` ở cả main/deputy |
| QA package hiện hành cho Phản Gián/Thiên Đố | Source commit hiện hành, catalog `53` scenario, package/catalog hash được installer ghi và `verify-qa-package.sh` xác nhận trong scratch; browser QA main/deputy PASS cho cả hai nhóm. Phản Gián probe C++ remote dừng trước gate vì host không phát `tqs_qa`; Thiên Đố mới có source contract + local prelight gate, **chưa có native gameplay evidence** |
| Probe native remote mới nhất cho Thiên Đố | Candidate identity đã PASS (`runtime MD5 c4704cd70bfbce3375c4c123a2443a3f`, `dist/index.html` SHA-256 `4e7ab8fb6305ef969ec820d6fda7a1944c2d8b0b89169ff433200e48be1f5566`); hai tài khoản vào được phòng QA nhưng `nativeQaGateSeen=false`, không có fake Thiên Đố và server trả cặp tướng ngẫu nhiên. Evidence [`1792066870927`](../../scratch/evidence/reconnect-failure-1792066870927.json). Đây là **BLOCKED trước gameplay**, không phải PASS/FAIL của `FinishJudge`; package/config remote vẫn chưa xác định |
| NATIVE-LOCAL staged identities trước đó | Weimu, Kongcheng, Qianxun và các add-on khác; hash gốc được giữ trong từng evidence JSON, không gộp vào identity Xiaoji |
| Cài đặt native local | Lua 5.4 + `luasocket`/`luafilesystem` và package QA; ca Thiên Hương dùng runtime cô lập `flist MD5 79ef20f9a8fff39dc92310500269add0`, ca Đoạn Trường dùng `flist MD5 cc9ffae8858f3fff68f4b4f4c3d1bc9b`; chỉ phục vụ kiểm thử cục bộ, **không phải Oracle/production** |
| Oracle VM package identity | **Chưa xác định / chưa chứng minh đã deploy source hiện hành**; service và cổng 9527 từng reachable nhưng chưa đọc được manifest/hash trong guest |
| CP92 UI/runtime hotfix | Runtime/package baseline: Web 1.739 file; `RELEASE.json` v2 verify PASS (16.522 file); runtime MD5 `c4704cd70bfbce3375c4c123a2443a3f`; root `dist/` đã dọn và đồng bộ từ `game/web/dist` |
| CP96 UI hotfix | UI artifact commit `0cc0d346`; latest redeploy `dep-db89kson74is73eakr6g` từ HEAD `74a7b30e` Live; HEAD chỉ thêm QA/docs/harness, không đổi `game/web/src`, `dist`, `gateway` hoặc `runtime`; HTML `index-B7bZuyxk.js`/`index-7DaeryPw.css`; HTML/JS/CSS byte probes PASS |

`CP90` (pile/tay bài), `CP91` (skill dock/time bar/action row/sorter), CP93, CP94 và CP96 UI đã được đưa vào artifact candidate và được Render deploy.

Probe public sau latest redeploy `dep-db89kson74is73eakr6g` (15/10/2026 16:20 GMT+7) trả `healthz=ok`, manifest `fileCount=5279`, runtime MD5 `c4704cd70bfbce3375c4c123a2443a3f`, bundle hash `0183516d94e2865f`, HTML trỏ `index-B7bZuyxk.js` và `index-7DaeryPw.css`; HTML SHA-256 `4e7ab8fb6305ef969ec820d6fda7a1944c2d8b0b89169ff433200e48be1f5566`, JS `7d8ddd939fe409748aea0f1f51ce1f96a31c9131aceb639041f4c994e6c40638`, CSS `34aa37b8e49449193553c24de4b34392617e5e95e05556d112605407d63b6b75`; asset probes PASS. Đây là bằng chứng **LIVE candidate identity**; redeploy này không mở thêm phạm vi luật, không phải full gameplay acceptance hoặc official release.

Re-validation local/native sau CP96 UI: mốc lịch sử trước commit Phản Gián là catalog/source `49/49` và `test:qa-server-contract` `30/30`; mốc hiện hành sau QA Thiên Đố là catalog/source `53/53`, `test:qa-server-contract` `32/32`, Wasmoon/React Lua E2E `63/63`, hidden-skill lifecycle `520/520`, slot-route `155.168/155.168`, skill activation `0` hard failure. Browser QA đã thêm `hidden-fanjian`/`hidden-fanjian-deputy` và `hidden-tiandu`/`hidden-tiandu-deputy`; probe remote mới nhất đã vượt identity gate nhưng dừng trước readiness gate (`nativeQaGateSeen=false`), xác nhận host chưa cung cấp deterministic `tqs_qa` scenario. Vì vậy Phản Gián và Thiên Đố đều không tính vào PASS native. Các ca NATIVE-LOCAL staged trước đó vẫn giữ identity riêng; không nâng candidate thành Oracle/hosted LIVE.

Runtime source hiện có hardening ở `ServerPlayer:prelightSkill`, `ServerPlayer:addFakeSkill` và `Room:handlePrelight`. `install-packages.sh` đã áp dụng chúng vào runtime native local; `verify-install.sh` và `verify-qa-package.sh` PASS trước các ca hiện hành. Candidate hosted và Oracle VM chưa được package/deploy lại nên không được gắn evidence này cho LIVE.

Regression source-law gate `npm --prefix game/web run test:hidden-rule-contract` hiện **7/7 PASS**. Gate này khóa đúng thứ tự và ownership của luật gốc: fake skill phải prelight mới qua `Player:hasSkill`; trigger phải vào `room:useSkill`; `SkillEffect` gọi `revealBySkillName` trước `fk.SkillEffect`/callback; route chủ được ưu tiên rồi mới fallback phó; prelight `true` chỉ nhận fake skill của đúng player; `hideGeneral()` re-attach phải phát lại `PrelightSkill=true`; và toàn bộ **607/607** trigger pair non-delay không có custom predicate ungated. Bốn continuation hậu-kích hoạt (`耀武`/`Deathed`, `闺秀`/`GeneralRemoved`, `除害`/`TurnEnd`, `放权`/`TurnEnd`) được allowlist bằng marker state cụ thể, không phải ngoại lệ im lặng. Đây là **SOURCE contract regression**, không phải 607 effect cases native.

## Hợp đồng runtime Lua native

Đây là lỗi môi trường đã lặp lại và phải khóa ở launcher, không xử lý bằng việc đổi `PATH` thủ công theo từng phiên:

- `freekill-asio` gọi worker bằng tên literal `lua5.4`; `scripts/lua-runtime.sh` chỉ nhận binary `lua5.4`/`lua-5.4`, kiểm tra chính xác `_VERSION == Lua 5.4`, rồi đặt lại `PATH` cho child process.
- Helper đặt `LUA_PATH`/`LUA_CPATH` tới tree Lua 5.4 của runtime và fail-closed nếu không load được `socket` hoặc `lfs`. Vì vậy Lua 5.5 hoặc Lua 5.4 thiếu module không thể mở server rồi mới crash ở room đầu tiên.
- `scripts/run-server.sh` và `scripts/verify-install.sh` dùng cùng helper; vận hành native phải đi qua `run-server.sh`, không gọi binary trực tiếp.
- Bằng chứng local hiện hành: catalog/source scenarios **53/53**, `test:qa-server-contract` **32/32** subtests, launcher preflight PASS, server thực chạy chọn Lua 5.4 và nạp 18 extension; `hs__xiaoji`, `hs__guanxing`, `ex__yingzi`, `hs__tianxiang`, `hs__duanchang` và regression `hs__yiji` re-hide đã PASS native theo slot. Thiên Hương kiểm cả `DetermineDamageInflicted` → `AskForUseActiveSkill` → `AskForChoices` → `SkillEffect`; 英姿 kiểm `EventPhaseStart`/`EventPhaseProceeding` → `DrawNCards` → rút thật → `AfterDrawNCards`; Đoạn Trường kiểm `fk.Death` → reveal người chết → `AskForChoices` chọn slot kỹ năng của killer; re-hide kiểm `SkillEffect` → `hideGeneral()` → fake/prelight retention. `hidden-fanjian` mới chỉ PASS source/browser contract; `hidden-tiandu` main/deputy mới PASS source contract + local prelight gate, chưa chạy C++ `room:judge`/`FinishJudge`. Probe remote Phản Gián thiếu `tqs_qa`. Đây là `NATIVE-LOCAL STAGED` cho các case đã có evidence; Oracle/hosted chưa được package hiện hành.

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
- `ServerPlayer:prelightSkill` phải giữ projection idempotent: runtime source đã dùng `table.insertIfNeed` cho skill và related skills, khớp với client ([`serverplayer.lua:519-543`](../../runtime/packages/freekill-core/ltk/server/serverplayer.lua:519)); [`Room:handlePrelight`](../../runtime/packages/freekill-core/ltk/server/room.lua:79) chỉ nhận `true` khi skill hiện là fake skill của chính player và chỉ nhận `false` khi server còn giữ lựa chọn prelight đó, nên payload giả mạo không thể prelight skill sẽ xuất hiện về sau hoặc kích hoạt nhánh đăng ký room ngoài ý muốn. Khi `hide/transform/swap` gắn lại một skill đã từng prelight, [`ServerPlayer:addFakeSkill`](../../runtime/packages/freekill-core/ltk/server/serverplayer.lua:494) phát lại `PrelightSkill=true` ngay sau `AddSkill`, đồng bộ live dashboard với state engine và reconnect snapshot. Pipeline native [`install-packages.sh`](../../deploy/freekill-native/scripts/install-packages.sh) áp dụng cả ba hardening vào checkout upstream và [`verify-install.sh`](../../deploy/freekill-native/scripts/verify-install.sh) fail-closed nếu thiếu; pipeline và runtime local hiện hành đều PASS. Oracle VM chưa được cập nhật.
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

Kết quả **NATIVE-LOCAL bounded PASS 12/12 lõi**, cộng các staged add-on Jizhi/Mingshi/Qianxun, `hs__kongcheng`, `hs__weimu`, Xiaoji, Guanxing, 英姿, Thiên Hương, Đoạn Trường và regression hidden-rehide-yiji main/deputy trên các identity QA riêng: C++/Lua thật, hai browser client và gateway cô lập. Weimu `TargetConfirming` có evidence main [`1792045540754`](../../scratch/evidence/cp08-hidden-weimu-multiplayer-live-1792045540754.json) và deputy [`1792045551855`](../../scratch/evidence/cp08-hidden-weimu-deputy-multiplayer-live-1792045551855.json); `BeforeCardsMove` có evidence main [`1792046419435`](../../scratch/evidence/cp08-hidden-weimu-indulgence-multiplayer-live-1792046419435.json) và deputy [`1792046430676`](../../scratch/evidence/cp08-hidden-weimu-indulgence-deputy-multiplayer-live-1792046430676.json). 英姿 và các ca Đoạn Trường/hidden-rehide-yiji có evidence main/deputy ở bảng dưới. Không nhập các identity staged thành một ma trận release; đây là bằng chứng native local, không phải hosted/official LIVE.

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

Hosted probe trên Oracle endpoint đã fail trước readiness gate — server trả GameOver mà không phát gate `tqs_qa` ([`1792050441784`](../../scratch/evidence/reconnect-failure-1792050441784.json)). Kết luận hiện tại là **package/config native trên hosted target chưa được chứng minh**, không phải lỗi Thiên Hương hay lỗi React; Oracle vẫn cần guest access để cài/verify package hiện hành.

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
| `hidden-yiji/negative` | Quách Gia chủ tướng úp, không prelight, nhận damage | Không hỏi Di Kế, không mở tướng, không di chuyển bài | [`1792032515033`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792032515033.json) |
| `hidden-yiji/positive` | Quách Gia chủ tướng úp, prelight và invoke sau damage | `AskForSkillInvoke` → mở chủ tướng Quách Gia → Di Kế chạy, di chuyển 2 lá | [`1792033610302`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792033610302.json) |
| `hidden-yiji/skip` | Quách Gia chủ tướng úp, prelight nhưng bỏ qua | Có request invoke nhưng không mở tướng, không di chuyển bài | [`1792032508016`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792032508016.json) |
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
| `hidden-duanchang` *(staged add-on)* | Thái Văn Cơ chủ tướng úp, chết bởi Cao Cao/Tư Mã Ý | `fk.Death` → `SkillEffect` mở chủ tướng → `AskForChoices` chọn Cao Cao → gỡ `Gian Hùng`, giữ `Phản Quỹ` | [`1792052232281`](../../scratch/evidence/cp08-hidden-duanchang-multiplayer-live-1792052232281.json) |
| `hidden-duanchang-deputy` *(staged add-on)* | Thái Văn Cơ phó tướng úp, chết bởi Cao Cao/Tư Mã Ý | Cùng chuỗi trên, mở đúng phó tướng và chỉ gỡ kỹ năng chủ của killer | [`1792052245231`](../../scratch/evidence/cp08-hidden-duanchang-deputy-multiplayer-live-1792052245231.json) |
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
| `hidden-luoshen` *(staged add-on)* | 甄姬 chủ tướng úp, prelight, vào đầu pha Bắt đầu | `EventPhaseStart` → `SkillEffect` → mở chủ tướng → phán xét đen/đỏ → lấy đúng 1 lá đen | [`1792038457902`](../../scratch/evidence/cp94-hidden-luoshen-multiplayer-live-1792038457902.json) |
| `hidden-luoshen-deputy` *(staged add-on)* | 甄姬 phó tướng úp, prelight, vào đầu pha Bắt đầu | `EventPhaseStart` → `SkillEffect` → mở phó tướng → phán xét đen/đỏ → lấy đúng 1 lá đen | [`1792038470764`](../../scratch/evidence/cp94-hidden-luoshen-deputy-multiplayer-live-1792038470764.json) |
| `hidden-tiandu` *(contract/browser only)* | Quách Gia chủ tướng úp, prelight, có Thiên Đố fake | Source `fk.FinishJudge` → `room:judge` đưa lá vào `Card.Processing` → mở đúng chủ tướng → lấy lá phán xét; local gate kiểm đúng slot, native C++ chưa chạy | Source/catalog + browser/Lua contract PASS; chưa có native gameplay evidence |
| `hidden-tiandu-deputy` *(contract/browser only)* | Quách Gia phó tướng úp, prelight, có Thiên Đố fake | Cùng chuỗi `FinishJudge`, nhưng phải mở đúng phó tướng và lấy đúng lá đang phán xét | Source/catalog + browser/Lua contract PASS; chưa có native gameplay evidence |
| `hidden-reveal` | Lục Tốn chủ tướng úp dùng `reveal_skill&` | Chọn `revealMain`; mở đúng Lục Tốn, giữ Tôn Quyền úp, request riêng tư đúng chủ sở hữu | [`1792032457447`](../../scratch/evidence/cp08-hidden-reveal-multiplayer-live-1792032457447.json) |
| `hidden-reveal-deputy` | Lục Tốn phó tướng úp dùng `reveal_skill&` | Chọn `revealDeputy`; mở đúng Lục Tốn, giữ Tôn Quyền chủ tướng úp | [`1792032464264`](../../scratch/evidence/cp08-hidden-reveal-deputy-multiplayer-live-1792032464264.json) |
| `hidden-active` | Tôn Quyền phó tướng úp dùng Chế Hành trên `PlayCard` | React chiếu Chế Hành thành regular skill; native mở phó tướng Tôn Quyền, giữ Lục Tốn úp và chạy `SkillEffect` | [`1792032471349`](../../scratch/evidence/cp08-hidden-active-multiplayer-live-1792032471349.json) |
| `hidden-active-main` | Tôn Quyền chủ tướng úp dùng Chế Hành trên `PlayCard` | Native mở chủ tướng Tôn Quyền, giữ Lục Tốn phó tướng úp và chạy `SkillEffect` | [`1792032478551`](../../scratch/evidence/cp08-hidden-active-main-multiplayer-live-1792032478551.json) |
| `hidden-fanjian` | Chu Du chủ tướng úp dùng Phản Gián trên `PlayCard` | Source `ex__fanjian` yêu cầu 1 lá trên tay + 1 mục tiêu; native phải mở đúng chủ tướng trước `SkillEffect`, tặng Peach và hỏi mục tiêu chọn mất HP | Browser/Lua contract PASS; native remote **BLOCKED trước gate** vì host chưa có `tqs_qa` |
| `hidden-fanjian-deputy` | Chu Du phó tướng úp dùng Phản Gián trên `PlayCard` | Cùng hợp đồng nhưng phải mở đúng phó tướng; không gộp với case chủ tướng | Browser/Lua contract PASS; native remote **BLOCKED trước gate** vì host chưa có `tqs_qa` |
| `hidden-view-as` | Triệu Vân phó tướng úp, chọn Thiểm bằng Long Đảm trên `PlayCard` | Native mở đúng phó tướng trước `SkillEffect`, nhận `hs__longdan`, chuyển Thiểm → Sát và chỉ owner nhận request | [`1792032486413`](../../scratch/evidence/cp08-hidden-view-as-multiplayer-live-1792032486413.json) |
| `hidden-view-as-main` | Triệu Vân chủ tướng úp, chọn Thiểm bằng Long Đảm trên `PlayCard` | Native mở đúng chủ tướng trước `SkillEffect`, nhận `hs__longdan`, chuyển Thiểm → Sát và chỉ owner nhận request | [`1792032493900`](../../scratch/evidence/cp08-hidden-view-as-main-multiplayer-live-1792032493900.json) |
| `hidden-dual` *(staged add-on)* | Nhan Lương/Văn Sửu còn úp, prelight Song Hùng ở đầu pha Chơi | Trigger bắt buộc chạy; chọn người, tự bỏ lá Jink đỏ duy nhất (`cancelable=false`), rồi `PlayCard` chuyển Sát đen thành Duel | [`1792035658085`](../../scratch/evidence/cp08-hidden-dual-multiplayer-live-1792035658085.json) |
| `rescue-normal` | Target hấp hối, actor giữ Peach thường ở room 2 chỗ | Native `AskForUseCard` nhận Peach cứu target; không vào Battle Royal | [`1792032587102`](../../scratch/evidence/cp08-rescue-normal-multiplayer-live-1792032587102.json) |
| `rescue-battle` | Vào Battle Royal, target tự cứu bằng Peach | Peach thường bị luật cấm; SpecialSkills `Quyết chiến` chuyển Peach → Analeptic/Wine và native dùng để hồi sinh | [`1792032617789`](../../scratch/evidence/cp08-rescue-battle-multiplayer-live-1792032617789.json) |
| `founding` | Wild general `heg__jiananfeng` được mở trong setup native | Native phát `AskForChoices` chọn kingdom và nhận đúng một reply; GameOver/cleanup sạch | [`1792032750793`](../../scratch/evidence/cp08-founding-multiplayer-live-1792032750793.json) |

`fankui.lua` là trigger bắt buộc trên `fk.Damaged`, không có một `askToSkillInvoke` tùy chọn thứ hai. QA gate `tqs_qa_hidden_fankui_gate` chỉ tạm dừng để browser gửi `PrelightSkill=true`; acceptance thật là Sát gây damage → `SkillEffect` → mở đúng slot → `AskForCardChosen` → `obtainCard`. Hai ca main/deputy đều kiểm tra nguồn có Slash + Peach, lấy đúng một lá Peach về tay actor và kết thúc GameOver. Đây là `NATIVE-LOCAL staged`, chưa phải Render/Oracle LIVE.

`fanjian.lua` là **ActiveSkill thật**, không phải trigger damage: `ex__fanjian` chỉ dùng một lần trong `HistoryPhase`, chọn một lá trên tay và một mục tiêu khác, rồi `showCards` → `obtainCard` → hỏi mục tiêu chọn lộ suit hoặc `loseHp`. Vì `SkillEffect` native gọi `revealBySkillName` trước `on_use`, luật đúng khi Chu Du còn úp là `PlayCard` có skill fake hợp lệ → mở đúng slot → chạy toàn bộ effect gốc; React không được tự tặng bài, tự trừ HP hoặc tự mở nhầm slot. Contract/browser QA đã khóa main/deputy và kiểm wire `skill=ex__fanjian`, Peach, target; native remote probe hiện **BLOCKED** trước gate `tqs_qa`, nên chưa gọi đây là native PASS. Case này bổ sung cho, không thay thế, case Quách Gia úp → prelight → `fk.Damaged` → Di Kế.

`luoshen.lua` dùng trigger `fk.EventPhaseStart`, gọi `room:judge` ở đầu pha Bắt đầu; nếu phán xét đen thì đưa lá đen đang ở Processing về tay 甄姬 và có thể tiếp tục phán xét cho tới khi gặp lá đỏ. QA gate `tqs_qa_hidden_luoshen_gate` chỉ chuẩn bị prelight, không thay thế trigger hay phán xét thật. Hai ca main/deputy đã quan sát `SkillEffect`, mở đúng slot, lấy đúng một lá đen và dừng chuỗi ở lá đỏ. Đây là `NATIVE-LOCAL staged`, chưa phải Render/Oracle LIVE.

[`tiandu.lua`](../../runtime/packages/freekill-core/standard/pkg/skills/tiandu.lua) đăng ký `fk.FinishJudge`, chỉ trigger khi người sở hữu đã có skill thật sau khi mở tướng và lá phán xét còn ở `Card.Processing`, rồi `obtainCard(player, data.card, ...)`. Hai scenario `hidden-tiandu` và `hidden-tiandu-deputy` khóa đúng luật source ở tầng catalog/QA và local Wasmoon/React chỉ xác nhận cổng prelight cho đúng slot. Probe native remote ngày 15/10/2026 đã vượt identity của web/runtime và vào được phòng, nhưng không nhận `tqs_qa` deterministic gate (`nativeQaGateSeen=false`, không fake Thiên Đố); route `room:judge` → `FinishJudge` → reveal → lấy lá phán xét **chưa được chạy C++**, nên Thiên Đố không được cộng vào bằng chứng native `18/607`.

[`jizhi.lua:13-21`](../../runtime/packages/hegemony/pkg/standard/skills/jizhi.lua:13) đăng ký `fk.CardUsing` và chỉ cho phép lá Common Trick chưa chuyển hóa; sau khi người chơi invoke, native `SkillEffect` mở slot sở hữu skill rồi rút 1 lá. [`mingshi.lua:15-23`](../../runtime/packages/hegemony/pkg/standard/skills/mingshi.lua:15) đăng ký `fk.DamageInflicted` với `Skill.Compulsory`, chỉ chạy khi nguồn còn một general `anjiang`, rồi `changeDamage(-1)`. [`qianxun.lua:5-55`](../../runtime/packages/hegemony/pkg/standard/skills/qianxun.lua:5) có hai nhánh: `fk.TargetConfirming` hủy mục tiêu `snatch`, và `fk.BeforeCardsMove` lọc `indulgence` đi vào `Card.PlayerJudge`, gọi `cancelMove` rồi mirror sang `Card.DiscardPile`. [`kongcheng.lua`](../../runtime/packages/hegemony/pkg/standard/skills/kongcheng.lua) đăng ký `fk.TargetConfirming`, yêu cầu đúng `player:isKongcheng()` và lá `slash`/`duel`, sau đó gọi `cancelTarget(player)`. [`weimu.lua:1-12`](../../runtime/packages/hegemony/pkg/standard/skills/weimu.lua:1) là `Skill.Compulsory` trên `fk.TargetConfirming`: target phải là chính player, skill phải được prelight, card phải là Trick màu đen, rồi `cancelTarget(player)`; [`weimu.lua:14-56`](../../runtime/packages/hegemony/pkg/standard/skills/weimu.lua:14) lọc delayed Trick đen vào `Card.PlayerJudge`, gọi `cancelMove` và mirror sang `Card.DiscardPile`. Bốn scenario Weimu đã khóa đủ hai predicate, reveal-before-effect, chuyển fake→active và đúng slot main/deputy. Tất cả các ca trên vẫn là `NATIVE-LOCAL`, chưa phải Render/Oracle LIVE.

Các test LOCAL bổ trợ (reducer **40/40**, connection 28/28, browser E2E 20/20, Wasmoon/React E2E 63/63, catalog/source scenarios **53/53**, `test:qa-server-contract` **32/32** subtests) kiểm privacy, lifecycle, wire payload và gate UI. QA contract khóa trực tiếp luật source của `new_hegemony_mode`, `hs__yiji`, `ex__fanjian`, `hs__tiandu`, `hs__xiaoji`, `hs__guanxing`, `ex__yingzi`, `hs__tianxiang`, `hs__duanchang`, `Player:hasSkill`, `TriggerSkill`, thứ tự reveal-before-effect, re-hide/prelight retention, Lua 5.4 module preflight và luật Peach/Analeptic của Battle Royal. Chúng không được dùng thay cho bảng native ở trên. Khi runtime/package identity đổi, phải chạy lại acceptance tương ứng; mỗi nhóm staged giữ identity riêng. Kết quả này không chứng nhận full gameplay hosted CP96, official release hoặc `PLAYABLE_MOBILE`.

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
| Native-local effect evidence đã map | **18/607 cặp; 10/53 event kinds (~3%)** | Chỉ các scenario đã chạy C++/Lua thật trong runtime cô lập; không phải hosted/Oracle/Render. |
| Nhóm đã có evidence | `AfterCardsMove`, `BeforeCardsMove`, `CardUsing`, `Damaged`, `DamageInflicted`, `Death`, `DetermineDamageInflicted`, `DrawNCards`, `EventPhaseStart`, `TargetConfirming` | Evidence hiện tập trung vào các case hidden đã được dựng, không đại diện toàn bộ event. |

Các nhóm còn trống/rủi ro cao gồm `TargetSpecified` (31 skill ID), `TargetConfirmed` (22), `Damage` (25), `DamageCaused` (16), `CardUseFinished` (16), `EventPhaseStart` (108 skill ID chưa test), `EnterDying` (10), `AskForPeaches` (5), `AskForRetrial` (4), cùng các event `GeneralHidden/GeneralRevealed`, phase transition, death/round và package-specific hooks. Vì vậy kết luận hiện tại là **projection/lifecycle/slot-route đã đạt SOURCE/LOCAL; effect parity của skill tướng úp vẫn OPEN**, không được suy ra từ 18 cặp native-local hoặc từ 520/520 lifecycle.

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
| Hidden-trigger/prelight + active reveal | **Đạt NATIVE-LOCAL bounded; Phản Gián/Thiên Đố còn mở** | 12/12 ca lõi C++/Lua thật; staged add-on gồm `hidden-fankui`, `hidden-dual`, `hidden-luoshen`, `hidden-jizhi`, `hidden-mingshi`, hai nhánh Qianxun, `hidden-kongcheng`, bốn scenario Weimu, Xiaoji 2/2, Guanxing 2/2, 英姿 2/2, Thiên Hương 2/2 và Đoạn Trường 2/2, đều có reveal đúng slot/effect native tương ứng. `hidden-fanjian` main/deputy mới đạt source contract + browser/Lua QA; `hidden-tiandu` main/deputy mới đạt source contract + local prelight gate. Phản Gián probe C++ remote dừng trước `tqs_qa`; Thiên Đố chưa chạy C++ `FinishJudge`. Chưa phải hosted/official hoặc exhaustive effect matrix. |
| Lua runtime launcher/module ABI | **Đạt NATIVE-LOCAL staged** | Launcher chọn đúng Lua 5.4, nạp `socket`/`lfs`, fail-closed trước port nếu sai version/module; hosted/Oracle chưa rerun. |
| Regular-skill dashboard gate | **Đạt NATIVE-LOCAL bounded** | `AddSkill/LoseSkill` của Self, fake active Chế Hành và fake ViewAs Long Đảm → regular dock → native `PlayCard` đã PASS; Phản Gián đã khóa contract/UI PlayCard nhưng chưa có native C++ evidence trên host; các active/ViewAs skill khác chưa có live matrix. |
| Local dialog/skill/card audits | **Đạt local** | Native dialogs 7/7, cards-and-choice 3/3, card selection 4/4, store 40/40, connection 28/28, gameplay 16/16, browser E2E 20/20, Wasmoon/React E2E 63/63, catalog/source scenarios 53/53 và `test:qa-server-contract` 32/32 subtests; gồm Thiên Đố prelight gate chủ/phó nhưng fixture/pipeline contract không phải C++ live. |
| Full native dialog coverage | **Chưa đạt** | Còn cancellation/expiry/reconnect và các caller Arrange/AG/Move/CustomDialog/ChooseSkill/ChooseGenerals/CardNames/KnownBoth chưa có live matrix đầy đủ. |
| Rescue ngoài Battle Royal | **Đạt NATIVE-LOCAL bounded** | Room 2 chỗ, actor dùng Peach thường cứu target qua `AskForUseCard`; Battle Royal không được bật. Hosted/Oracle chưa verify lại cùng identity. |
| Battle Royal rescue/view-as | **Đạt NATIVE-LOCAL bounded** | Target tự cứu bằng Peach → SpecialSkills `Quyết chiến` → Analeptic/Wine qua native `AskForUseCard`; event theo round và các biến thể khác chưa exhaustive. |
| Wild/founding/kingdom choice | **Đạt NATIVE-LOCAL bounded cho request** | `heg__jiananfeng` wild đã phát `AskForChoices` kingdom và nhận reply; state phe sau chọn, reward/punishment và winner transition chưa đóng. |
| Luật mở rộng theo package | **Chưa đạt exhaustive** | Rare treasure, Alliance, Formation, Command, Lord, dual faction, transformation và package-specific paths mới có source/local/targeted evidence. |
| CP90/CP91 + CP93/CP94/CP96 UI trên candidate | **Đạt ở artifact/live probe** | CP96 đã deploy; static health/manifest/HTML/JS/CSS byte probe PASS. Người dùng còn cần smoketest gameplay nhiều bước; không suy ra full parity. |
| Device/Safari/physical network | **Deferred/waived** | Người dùng miễn nghiệm thu vật lý trong scope hiện tại; đây không phải PASS. |
| Official operations/release | **Chưa đạt** | Cold-start/quota/rollback/SLA và official sign-off còn mở. |

## Gaps phải xử lý trước khi gọi là full parity

### P0 — luật và interaction

- Rerun normal rescue, Battle Royal rescue/view-as và founding trên hosted/Oracle sau khi guest package identity được xác minh; không gắn NATIVE-LOCAL PASS vào LIVE.
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
