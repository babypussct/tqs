# Audit luật Quốc Chiến: source gốc và React đang deploy

> Audit cập nhật 15/10/2026 11:00 (giờ Việt Nam). Đây là tài liệu canonical cho câu hỏi “đã chơi được đến đâu”, không phải danh sách mọi commit lịch sử.

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
| Release candidate | CP92, source commit `c40e36a7` |
| Release status | Candidate để test, chưa official |
| NATIVE-LOCAL runtime hiện hành | C++ source `b8a2ad48305aea7b55ccca325fcbeb100cb8a01a`, runtime MD5 `eb8ca9dc66aa247ab8f9b83118168960`, 14 package pin + `tqs_qa`, browser artifact SHA-256 `d432f717a938665fab8ae81a6a903aa11f1cfeaa84d5cc0fd62f07572e436893` |
| NATIVE-LOCAL QA package hiện hành | QA source `5dcd7266a993b36bde8c8480507aaa7306ccdcfe`, manifest SHA-256 `7bcb3c4af96fc73a1866c517a0bc928d00a1341ffee68a4277f2884d17248791`, package SHA-256 `5ce1d5ec4ae407a3181dc0a96c86e936606a8dbe9001d3a7931f43d14ff78f47`, catalog SHA-256 `20de2e7ccd017ebb123c229c60f30b701784ebae22111b4e8afea9189645e574` |
| NATIVE-LOCAL staged add-on | `hidden-dual` + Lua 5.4 launcher; runtime MD5 `cf6e10887c7513df25c07d0bd5c20744`, QA revision `ee71594d4826b6126f4609ccfd283976cc0c0235`, package SHA-256 `1c7ba7b22a4608e1f2ef26ce33e03a378d46c03d817ec1cdf335ff72cab469d1`, catalog SHA-256 `66f7afd8530e12ca098422f91eae6c5a3a5c1de4ee84e6c39e626c45ef3e45da`, browser artifact SHA-256 `d432f717a938665fab8ae81a6a903aa11f1cfeaa84d5cc0fd62f07572e436893` |
| Cài đặt native local | Lua 5.4 + `luasocket`/`luafilesystem` và package QA nằm trong runtime tạm `/tmp/tqs-native-runtime.a6bMIc`; chỉ phục vụ kiểm thử cục bộ, **không phải Oracle/production** |
| Oracle VM package identity | **Chưa xác định / chưa chứng minh đã deploy source hiện hành**; service và cổng 9527 từng reachable nhưng chưa đọc được manifest/hash trong guest |
| CP92 UI/runtime hotfix | Web 1.739 file; `RELEASE.json` v2 verify PASS (16.522 file); runtime MD5 `c4704cd70bfbce3375c4c123a2443a3f`; root `dist/` đã dọn và đồng bộ từ `game/web/dist`; commit `f039e228` + `c40e36a7` đã push và deploy |

`CP90` (pile/tay bài) và `CP91` (skill dock/time bar/action row/sorter) đã được đưa vào artifact CP92 hotfix và đã được Render deploy.

Probe public sau deployment `dep-db84u7avcj2c7387q6dg` (15/10/2026 10:58 GMT+7) trả `healthz=ok`, manifest `fileCount=5279`, runtime MD5 `c4704cd70bfbce3375c4c123a2443a3f`, bundle hash `0183516d94e2865f`, HTML trỏ `index-DUN9EqW6.js` và `index-B2V66FPQ.css`. Đây là bằng chứng **LIVE candidate identity**, không phải full gameplay acceptance hoặc official release.

Runtime source hiện có hardening ở `ServerPlayer:prelightSkill`, `ServerPlayer:addFakeSkill` và `Room:handlePrelight`. `install-packages.sh` đã áp dụng chúng vào runtime native local; `verify-install.sh` và `verify-qa-package.sh` PASS trước các ca hiện hành. Candidate hosted và Oracle VM chưa được package/deploy lại nên không được gắn evidence này cho LIVE.

## Hợp đồng runtime Lua native

Đây là lỗi môi trường đã lặp lại và phải khóa ở launcher, không xử lý bằng việc đổi `PATH` thủ công theo từng phiên:

- `freekill-asio` gọi worker bằng tên literal `lua5.4`; `scripts/lua-runtime.sh` chỉ nhận binary `lua5.4`/`lua-5.4`, kiểm tra chính xác `_VERSION == Lua 5.4`, rồi đặt lại `PATH` cho child process.
- Helper đặt `LUA_PATH`/`LUA_CPATH` tới tree Lua 5.4 của runtime và fail-closed nếu không load được `socket` hoặc `lfs`. Vì vậy Lua 5.5 hoặc Lua 5.4 thiếu module không thể mở server rồi mới crash ở room đầu tiên.
- `scripts/run-server.sh` và `scripts/verify-install.sh` dùng cùng helper; vận hành native phải đi qua `run-server.sh`, không gọi binary trực tiếp.
- Bằng chứng local: QA contract **15/15**, launcher preflight PASS, server thực chạy chọn `/tmp/.../bin/lua5.4`, nạp 18 extension và `hidden-dual` PASS. Đây là `NATIVE-LOCAL STAGED`; Oracle/hosted chưa được xác minh bằng launcher mới.

Ghi chú môi trường: native local được biên dịch từ commit C++ pin trên macOS. Harness tạm ngoài repository chỉ thay cách kiểm tra tiến trình con (`waitpid`) vì upstream dùng `/proc`, vốn không có trên macOS; patch này không nằm trong source/deploy và không được coi là thay đổi production/Oracle. Kết quả native local chứng minh vòng đời Lua/C++ và bridge của các scenario, không chứng minh binary Linux đang chạy trên VM.

Audit reconnect cũng đã tìm thấy và sửa một lỗi thật ở host boundary: `Client:addSkill(..., true)` giữ fake skill trong `player_skills`, rồi `ClientPlayer:sendDataToUI()` phát lại snapshot qua cả nhánh regular và fake. `hostLua.ts` hiện bọc đúng snapshot path, loại bản regular trùng tên trước khi phân loại fake/regular cho React. Probe dùng chính trạng thái `Client:addSkill` đạt **520/520** và `Client:loseSkill` dọn đúng **520/520** trên toàn bộ skill ID hidden hợp lệ, gồm cả 15 delay-trigger fallback; đây là SOURCE/LOCAL evidence, chưa phải native-live evidence.

Một phép thử native bổ sung đã cố ý ngắt transport khi `AskForSkillInvoke` readiness gate của hidden Di Kế còn pending. FreeKill hủy request khi actor disconnect (`hidden-yiji QA gate was cancelled`), rồi cho phép login lại nhưng không còn pending gate để phục hồi; vì vậy đây là **OPEN/giới hạn semantics reconnect của request đang chờ**, không phải bằng chứng React làm mất Di Kế. Không dùng ca này để nâng mức PASS; reconnect sau state thật và reconnect của các request khác vẫn phải được kiểm riêng theo từng family.

## Luật gốc cần đối chiếu

Nguồn luật chính:

- [`new_hegemony_mode.lua`](../../runtime/packages/hegemony/pkg/gamemodes/new_hegemony_mode.lua): setup, lượt, hidden general, HP, phe, thắng, reward/punishment, mode settings.
- [`hegemony_rule.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/hegemony_rule.lua): GameStart, reveal, Battle Royal trigger, GameOverJudge, GeneralShown và rare treasure.
- [`util.lua`](../../runtime/packages/hegemony/util.lua): so phe, expected kingdom, wild kingdom, founding/build country và Hegemony marks.
- Các skill luật: [`vanguard.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/vanguard.lua), [`companion_skill.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/companion_skill.lua), [`wild_skill.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/wild_skill.lua), [`new_battle_royal.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/new_battle_royal.lua), [`new_battle_royal_event.lua`](../../runtime/packages/hegemony/pkg/gamemodes/skills/new_battle_royal_event.lua).

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

Kết quả **NATIVE-LOCAL bounded PASS 12/12 trên cùng identity**: C++/Lua thật, hai browser client, gateway cô lập, QA revision `5dcd…` và browser artifact `d432…`. Có thêm một ca `hidden-dual` ở identity staged mới; không nhập hai identity thành một ma trận release. Mỗi evidence JSON tự ghi `runtimeMD5`, `distIndexSha256` và `qaPackageIdentity`; đây là bằng chứng native local, không phải hosted/official LIVE.

Hai lần rerun trước [`1792002124241`](../../scratch/evidence/reconnect-failure-1792002124241.json) và [`1792002605900`](../../scratch/evidence/reconnect-failure-1792002605900.json) fail trước cổng QA vì runtime ngoài chưa có package `tqs_qa`; chúng là bằng chứng chẩn đoán boundary package/config, không phải phủ định luật React. Sau khi cài package vào runtime local và lấy manifest thực tế, ma trận đã được chạy lại đầy đủ.

| Scenario | Kiểm tra native | Kết quả | Evidence |
| --- | --- | --- | --- |
| `hidden-yiji/negative` | Quách Gia chủ tướng úp, không prelight, nhận damage | Không hỏi Di Kế, không mở tướng, không di chuyển bài | [`1792032515033`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792032515033.json) |
| `hidden-yiji/positive` | Quách Gia chủ tướng úp, prelight và invoke sau damage | `AskForSkillInvoke` → mở chủ tướng Quách Gia → Di Kế chạy, di chuyển 2 lá | [`1792033610302`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792033610302.json) |
| `hidden-yiji/skip` | Quách Gia chủ tướng úp, prelight nhưng bỏ qua | Có request invoke nhưng không mở tướng, không di chuyển bài | [`1792032508016`](../../scratch/evidence/cp08-hidden-yiji-multiplayer-live-1792032508016.json) |
| `hidden-yiji-deputy` | Quách Gia phó tướng úp, prelight và invoke sau damage | `SkillEffect` mở đúng **phó tướng** Quách Gia rồi Di Kế chạy, di chuyển 2 lá | [`1792032529464`](../../scratch/evidence/cp08-hidden-yiji-deputy-multiplayer-live-1792032529464.json) |
| `hidden-jianxiong` | Cao Cao chủ tướng úp, prelight, nhận Sát thật và chọn lấy lá Sát | `AskForSkillInvoke` → `AskForChoices` → mở đúng chủ tướng → lấy lá Sát từ Processing | [`1792032442802`](../../scratch/evidence/cp08-hidden-jianxiong-multiplayer-live-1792032442802.json) |
| `hidden-jianxiong-deputy` | Cao Cao phó tướng úp, prelight, nhận Sát thật và chọn lấy lá Sát | `AskForSkillInvoke` → `AskForChoices` → mở đúng phó tướng → lấy lá Sát từ Processing | [`1792032450414`](../../scratch/evidence/cp08-hidden-jianxiong-deputy-multiplayer-live-1792032450414.json) |
| `hidden-reveal` | Lục Tốn chủ tướng úp dùng `reveal_skill&` | Chọn `revealMain`; mở đúng Lục Tốn, giữ Tôn Quyền úp, request riêng tư đúng chủ sở hữu | [`1792032457447`](../../scratch/evidence/cp08-hidden-reveal-multiplayer-live-1792032457447.json) |
| `hidden-reveal-deputy` | Lục Tốn phó tướng úp dùng `reveal_skill&` | Chọn `revealDeputy`; mở đúng Lục Tốn, giữ Tôn Quyền chủ tướng úp | [`1792032464264`](../../scratch/evidence/cp08-hidden-reveal-deputy-multiplayer-live-1792032464264.json) |
| `hidden-active` | Tôn Quyền phó tướng úp dùng Chế Hành trên `PlayCard` | React chiếu Chế Hành thành regular skill; native mở phó tướng Tôn Quyền, giữ Lục Tốn úp và chạy `SkillEffect` | [`1792032471349`](../../scratch/evidence/cp08-hidden-active-multiplayer-live-1792032471349.json) |
| `hidden-active-main` | Tôn Quyền chủ tướng úp dùng Chế Hành trên `PlayCard` | Native mở chủ tướng Tôn Quyền, giữ Lục Tốn phó tướng úp và chạy `SkillEffect` | [`1792032478551`](../../scratch/evidence/cp08-hidden-active-main-multiplayer-live-1792032478551.json) |
| `hidden-view-as` | Triệu Vân phó tướng úp, chọn Thiểm bằng Long Đảm trên `PlayCard` | Native mở đúng phó tướng trước `SkillEffect`, nhận `hs__longdan`, chuyển Thiểm → Sát và chỉ owner nhận request | [`1792032486413`](../../scratch/evidence/cp08-hidden-view-as-multiplayer-live-1792032486413.json) |
| `hidden-view-as-main` | Triệu Vân chủ tướng úp, chọn Thiểm bằng Long Đảm trên `PlayCard` | Native mở đúng chủ tướng trước `SkillEffect`, nhận `hs__longdan`, chuyển Thiểm → Sát và chỉ owner nhận request | [`1792032493900`](../../scratch/evidence/cp08-hidden-view-as-main-multiplayer-live-1792032493900.json) |
| `hidden-dual` *(staged add-on)* | Nhan Lương/Văn Sửu còn úp, prelight Song Hùng ở đầu pha Chơi | Trigger bắt buộc chạy; chọn người, tự bỏ lá Jink đỏ duy nhất (`cancelable=false`), rồi `PlayCard` chuyển Sát đen thành Duel | [`1792035658085`](../../scratch/evidence/cp08-hidden-dual-multiplayer-live-1792035658085.json) |
| `rescue-normal` | Target hấp hối, actor giữ Peach thường ở room 2 chỗ | Native `AskForUseCard` nhận Peach cứu target; không vào Battle Royal | [`1792032587102`](../../scratch/evidence/cp08-rescue-normal-multiplayer-live-1792032587102.json) |
| `rescue-battle` | Vào Battle Royal, target tự cứu bằng Peach | Peach thường bị luật cấm; SpecialSkills `Quyết chiến` chuyển Peach → Analeptic/Wine và native dùng để hồi sinh | [`1792032617789`](../../scratch/evidence/cp08-rescue-battle-multiplayer-live-1792032617789.json) |
| `founding` | Wild general `heg__jiananfeng` được mở trong setup native | Native phát `AskForChoices` chọn kingdom và nhận đúng một reply; GameOver/cleanup sạch | [`1792032750793`](../../scratch/evidence/cp08-founding-multiplayer-live-1792032750793.json) |

Các test LOCAL bổ trợ (reducer 38/38, connection 28/28, browser E2E 20/20, Wasmoon/React E2E 63/63, QA contract **15/15**) kiểm privacy, lifecycle, wire payload và gate UI. QA contract khóa trực tiếp luật source của `new_hegemony_mode`, `hs__yiji`, `Player:hasSkill`, `TriggerSkill`, thứ tự reveal-before-effect, Lua 5.4 module preflight và luật Peach/Analeptic của Battle Royal. Trong đó có regression âm Quách Gia úp → nhận damage khi chưa prelight thì không có request/không lộ tướng, regression dương Quách Gia úp → prelight Di Kế → giảm HP → `AskForSkillInvoke` → Kích hoạt → chuyển projection fake sang skill thường, và reconnect serialize/deserialize thật khôi phục Di Kế fake đã prelight cùng Chế Hành regular. Probe snapshot bằng chính trạng thái `Client:addSkill` đạt 520/520 Add và 520/520 Lose sau khi sửa duplicate regular. Chúng không được dùng thay cho bảng native ở trên. Khi runtime/package identity đổi, phải chạy lại acceptance tương ứng; 12 ca hidden lõi và 3 edge case cũ dùng identity ổn định, còn `hidden-dual` dùng staged identity riêng. Kết quả này không chứng nhận hosted CP89, official release hoặc `PLAYABLE_MOBILE`.

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
| Hidden-trigger/prelight + active reveal | **Đạt NATIVE-LOCAL bounded** | 12/12 ca lõi C++/Lua thật trên cùng identity; thêm `hidden-dual` staged với trigger bắt buộc, auto-discard và ViewAs Duel. Chưa phải hosted/official hoặc exhaustive effect matrix. |
| Lua runtime launcher/module ABI | **Đạt NATIVE-LOCAL staged** | Launcher chọn đúng Lua 5.4, nạp `socket`/`lfs`, fail-closed trước port nếu sai version/module; hosted/Oracle chưa rerun. |
| Regular-skill dashboard gate | **Đạt NATIVE-LOCAL bounded** | `AddSkill/LoseSkill` của Self, fake active Chế Hành và fake ViewAs Long Đảm → regular dock → native `PlayCard` đã PASS; các active/ViewAs skill khác chưa có live matrix. |
| Local dialog/skill/card audits | **Đạt local** | Native dialogs 7/7, cards-and-choice 3/3, card selection 4/4, store 38/38, connection 28/28, gameplay 16/16, browser E2E 20/20, Wasmoon/React E2E 63/63, QA contract 15/15; có cả regression Quách Gia không prelight và prelight → damage → invoke → reveal, server prelight idempotency fixture, Lua 5.4 launcher preflight và contract install/verify native; fixture/pipeline contract không phải C++ live. |
| Full native dialog coverage | **Chưa đạt** | Còn cancellation/expiry/reconnect và các caller Arrange/AG/Move/CustomDialog/ChooseSkill/ChooseGenerals/CardNames/KnownBoth chưa có live matrix đầy đủ. |
| Rescue ngoài Battle Royal | **Đạt NATIVE-LOCAL bounded** | Room 2 chỗ, actor dùng Peach thường cứu target qua `AskForUseCard`; Battle Royal không được bật. Hosted/Oracle chưa verify lại cùng identity. |
| Battle Royal rescue/view-as | **Đạt NATIVE-LOCAL bounded** | Target tự cứu bằng Peach → SpecialSkills `Quyết chiến` → Analeptic/Wine qua native `AskForUseCard`; event theo round và các biến thể khác chưa exhaustive. |
| Wild/founding/kingdom choice | **Đạt NATIVE-LOCAL bounded cho request** | `heg__jiananfeng` wild đã phát `AskForChoices` kingdom và nhận reply; state phe sau chọn, reward/punishment và winner transition chưa đóng. |
| Luật mở rộng theo package | **Chưa đạt exhaustive** | Rare treasure, Alliance, Formation, Command, Lord, dual faction, transformation và package-specific paths mới có source/local/targeted evidence. |
| CP90/CP91 trên candidate | **Đạt ở artifact/live probe** | CP92 đã deploy; static health/manifest/asset probe PASS. Người dùng còn cần smoketest gameplay nhiều bước; không suy ra full parity. |
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
