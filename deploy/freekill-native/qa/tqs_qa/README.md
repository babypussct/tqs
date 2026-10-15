# `tqs_qa` native QA package

`tqs_qa` is a server-only FreeKill package for deterministic scenario tests. It
is deliberately kept outside `runtime/packages` in the repository so that it
cannot be included in a normal mobile/web release by accident.

The package is inert unless the QA installer writes
`ServerConfig.tqsQa.enabled = true` and a verified `package.manifest.json`.
When enabled, a room name selects one catalog entry using this exact form:

```text
TQSQA/<scenario-id>/<seed>
```

For example:

```text
TQSQA/card-chosen/0x2c9f4a17
```

The package then uses the native `GamePrepared`, `DrawInitialCards`,
`GameStart`, `RoundStart`, and `GameFinished` events. It reserves real cards
from the native draw pile, fixes the initial-card event, attaches the selected
general's real skills, and starts the rescue/founding flows through the normal
FreeKill request APIs. It does not add a client cheat command and it never
changes production room behavior when disabled.

## Install a QA runtime

Run the installer from a clean, checked-out repository revision:

```bash
deploy/freekill-native/scripts/install-qa-package.sh \
  --source deploy/freekill-native/qa/tqs_qa \
  --runtime /srv/tqs-qa/runtime \
  --allow-user qa-player-a,qa-player-b \
  --expected-revision "$(git rev-parse HEAD)"
```

Then verify the exact runtime before starting the server:

```bash
deploy/freekill-native/scripts/verify-qa-package.sh \
  --source deploy/freekill-native/qa/tqs_qa \
  --runtime /srv/tqs-qa/runtime \
  --expected-revision "$(git rev-parse HEAD)"
```

The installer and verifier compare the catalog hash, package tree hash,
source revision, allowlist, and config. They also reject symlinks and reject a
`tqs_qa` row in `packages.db`; the package remains server-only. A normal
production runtime must not be modified by this workflow.

## Operational contract

- The default server config has QA disabled.
- The allowlist must be explicit; an empty allowlist is rejected.
- The scenario id and seed must both be present and must match the catalog.
- The room is limited by the QA player count, active-room quota, run quota,
  and configured room prefix.
- QA metadata contains only scenario, seed, package revision, and native
  player ids. Card ids and account names are not written to the QA log.
- A server process restart clears the in-memory active-room quota. The native
  room lifecycle releases a slot on `GameFinished`; `RoundStart` also enforces
  the configured duration cap.

The package is not a deployment artifact for the public gateway. The browser
runner must first verify the release manifest and hosted gateway identity; a
stale or unpinned hosted candidate is a hard failure before any login or room
creation.

## `rescue-*` and `founding`: source-law fixtures

The catalog owners are intentional and must not be swapped to make a UI test
convenient:

- `rescue-normal` puts an ordinary Peach in `actor`'s hand. `target` is put in
  Dying and the native `game_rule.lua` asks other players for pattern `peach`.
- `rescue-battle` enters New Battle Royal before Dying. The Peach belongs to
  `target`, because only the dying player receives the extra `analeptic`
  option; `new_battle_royal.lua` converts Peach to Analeptic/Wine and prohibits
  an unconverted Peach.
- `founding` marks `heg__jiananfeng` as wild, reveals it through the native
  GeneralShown path, and expects the real kingdom `AskForChoices` request.

These fixtures exercise the normal FreeKill request APIs; they do not inject a
client reply or replace the server's rescue/founding state machine. Current
native evidence and the exact runtime/package identity belong in the canonical
audit, [`QUOC_CHIEN_RULE_AUDIT.md`](../../../../docs/web-client/QUOC_CHIEN_RULE_AUDIT.md),
not in this README.

## `fazheng-enyuan`: three Slashes and a Longdan counterattack

The two-seat roster is fixed: Wei Quách Gia + Tư Mã Ý (`hs__guojia` +
`hs__simayi`) versus Shu Triệu Vân + Pháp Chính (`hs__zhaoyun` + `ld__fazheng`).
Seed: `0x6e9a2026`. The native director requests actual hand-card use and runs
normal `room:useCard` resolution; it does not inject `room:damage` to simulate
a successful attack.

Wei starts with three Slashes and one Peach to give. Shu starts with a Slash
for defense, a Jink for the counterattack, and a Peach available to steal.
The QA requests allow three extra Slashes without installing an equipment or
changing an upstream skill. Each result is independently checked against
native card-use, Damaged, SkillEffect, hand movement, and HP observations:

| Step | Explicit player choice | Required native outcome |
| --- | --- | --- |
| 1 | Wei uses Slash; Shu selects Longdan and its Slash as Jink | Dodge, zero damage/HP loss, no Enyuan |
| 2 | Wei uses Slash; Shu declines Jink; Wei gives the reserved Peach | Shu loses exactly 1 HP; Enyuan transfers exactly 1 hand card; Wei loses no HP |
| 3 | Wei uses its last Slash; Shu declines Jink | Shu loses exactly 1 HP; empty-handed Wei loses exactly 1 HP to Enyuan; this HP loss triggers neither Yiji nor Fankui |
| 4 | Shu selects Longdan and uses its Jink as Slash; Wei explicitly invokes Yiji and Fankui | Wei loses exactly 1 HP; Yiji gives 2 cards to Wei itself; Fankui transfers exactly 1 card from Shu |

**Yiji and Fankui are both optional.** They remain in `optionalSkills` and
are never declared mandatory damage reactions. `expectedInvokedSkills`
selects the positive test branch; declining either skill is valid gameplay
but does not satisfy this particular branch's acceptance criteria. The local
browser suite also tests Invoke and Skip for each skill. Native negative
coverage must separately observe that skipping Yiji/Fankui causes no draw or
transfer; a browser reply alone is not that evidence.

Run the positive native acceptance path using two manually controlled seats:

```bash
TQS_LIVE_SCENARIO=fazheng-enyuan \
TQS_LIVE_NATIVE_QA=1 \
TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual
```

`--manual` drives both real UIs; neither seat is delegated to Trust/AI in this
scenario. The source package must be installed and verified for the exact
source revision, and the release/native-QA identity gate must pass before
login/room creation. Running an old installed package cannot test this new
catalog. GameOver is requested only after all four results pass; both clients
must see the public outcome summary and each request must receive one reply.
QA summary templates are transmitted as literal log text because the
server-only package's translations are absent from the public client bundle.

Local checks:

```bash
npm --prefix game/web run test:e2e:qa
npm --prefix game/web run test:qa-server-contract
```

The first executes Chrome + actual FreeKill client Lua/Wasmoon with a socket
fixture. It verifies both Longdan replies, optional Invoke/Skip, Yiji selecting
two cards for self, Fankui choosing a hidden source card, and the first native
attack request shape. The second checks catalog/installer contracts and
executes Lua startup validation with JSON/engine registration stubs. Neither
command proves native C++ damage or live card-transfer outcomes.

## `hidden-yiji`: Quách Gia úp, prelight, sát thương và mở tướng

This is the dedicated native acceptance scenario for the hidden-trigger rule.
The director fixes the actor as Quách Gia + Tư Mã Ý and the source as Triệu Vân
+ Pháp Chính, keeps the actor's two generals hidden, and pauses on a normal
`AskForSkillInvoke` QA gate. While that gate is pending, the real browser must
use the fake-skill dock to send the native `PushRequest("prelight,hs__yiji,true")`.
The director then calls native `room:damage`; it does not inject an
`AskForSkillInvoke` or reveal the general itself.

Run one branch per clean room, with an explicit branch label in the evidence:

```bash
TQS_LIVE_SCENARIO=hidden-yiji \
TQS_LIVE_HIDDEN_YIJI_MODE=negative \
TQS_LIVE_NATIVE_QA=1 \
TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual

TQS_LIVE_SCENARIO=hidden-yiji \
TQS_LIVE_HIDDEN_YIJI_MODE=positive \
TQS_LIVE_NATIVE_QA=1 \
TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual

TQS_LIVE_SCENARIO=hidden-yiji \
TQS_LIVE_HIDDEN_YIJI_MODE=skip \
TQS_LIVE_NATIVE_QA=1 \
TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual
```

Expected native outcomes:

| Branch | Client action | Required native result |
| --- | --- | --- |
| `negative` | Do not prelight; accept the QA gate | No Yiji request, no reveal, no Yiji card movement |
| `positive` | Prelight, accept the gate, then Invoke Di Kế | `AskForSkillInvoke` → Quách Gia reveal → Yiji distributes two cards |
| `skip` | Prelight, accept the gate, then Skip Di Kế | `AskForSkillInvoke`, but no reveal and no card movement |

The multiplayer runner treats this readiness gate as a hard boundary. For
hidden native scenarios it fails after 45 seconds by default (override with
`TQS_LIVE_NATIVE_QA_GATE_TIMEOUT_MS`, bounded to 10–180 seconds), or
immediately when `GameOver` arrives before the gate. A missing gate is a
server-only `tqs_qa` package/config failure diagnosis, not a React gameplay
PASS or FAIL; the evidence records `nativeQaGateSeen` and the observed command.

`hidden-yiji-deputy` dùng cùng gate/positive branch nhưng đổi roster thành Tư
Mã Ý + Quách Gia, để xác nhận `revealBySkillName` mở phó tướng khi Di Kế nằm
ở phó tướng.

## `hidden-jianxiong`: trigger úp đi qua Invoke + Choices

Ca này giữ Cao Cao úp, prelight `hs__jianxiong`, rồi để đối thủ dùng đúng một
lá Sát thật. Browser phải trả `AskForSkillInvoke`, sau đó chọn
`hs__jianxiong-obtain` trong `AskForChoices`. Native director kiểm tra Cao Cao
được mở đúng chủ/phó tướng trước `SkillEffect` và lá Sát đang ở Processing
được chuyển vào tay Cao Cao. `hidden-jianxiong-deputy` lặp lại cùng hiệu ứng với
Cao Cao ở phó tướng; hai ca này bổ sung cho Di Kế bằng một trigger có choice,
không thay thế ma trận Di Kế.

The catalog, seed and expected command are checked against the browser QA
catalog. A native package must be installed and verified again after this
scenario changes; the source `package.manifest.json` in this checkout is
deliberately `status: source` and is not evidence by itself. On 2026-10-15,
the two Jianxiong slot branches were run through two browser clients, a local
gateway and a real C++/Lua runtime after the installer wrote a verified
server-only manifest. The sanitized evidence files are linked from
`docs/web-client/QUOC_CHIEN_RULE_AUDIT.md`; this local result does not certify
the hosted CP89 candidate or an official release.

## `hidden-fankui`: trigger `Damaged` khi Tư Mã Ý còn úp

`fankui.lua` uses a compulsory `fk.Damaged` effect. The QA gate only pauses the
room so the browser can send `PrelightSkill=true`; it is not a second gameplay
invoke. The real path is:

```text
prelight → real Slash damage → SkillEffect → reveal the owning slot
→ AskForCardChosen → obtain one card from the source
```

Both `hidden-fankui` and `hidden-fankui-deputy` reserve a target Slash and
Peach, then require Tư Mã Ý to reveal in the correct main/deputy slot and obtain
exactly one card. Run each branch on a clean room:

```bash
TQS_LIVE_SCENARIO=hidden-fankui \
TQS_LIVE_NATIVE_QA=1 TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual

TQS_LIVE_SCENARIO=hidden-fankui-deputy \
TQS_LIVE_NATIVE_QA=1 TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual
```

Current native-local evidence and package identity are kept only in
[`QUOC_CHIEN_RULE_AUDIT.md`](../../../../docs/web-client/QUOC_CHIEN_RULE_AUDIT.md);
this README intentionally does not duplicate hashes or logs.

## `hidden-luoshen`: EventPhaseStart và phán xét khi 甄姬 còn úp

`luoshen.lua` uses the real `fk.EventPhaseStart` trigger. The QA gate only
pauses before the phase event so the browser can send `PrelightSkill=true`; it
does not replace the native trigger, judge, reveal or obtain path. The observed
sequence is:

```text
prelight → Player.Start / EventPhaseStart → SkillEffect → reveal owning slot
→ judge black → obtain the black card → judge red → stop
```

Both `hidden-luoshen` and `hidden-luoshen-deputy` verify that 甄姬 is revealed
in the correct main/deputy slot and obtains exactly one black judgment card.
Run each branch on a clean room:

```bash
TQS_LIVE_SCENARIO=hidden-luoshen \
TQS_LIVE_NATIVE_QA=1 TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual

TQS_LIVE_SCENARIO=hidden-luoshen-deputy \
TQS_LIVE_NATIVE_QA=1 TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual
```

Evidence, package hashes and the NATIVE-LOCAL scope remain centralized in
[`QUOC_CHIEN_RULE_AUDIT.md`](../../../../docs/web-client/QUOC_CHIEN_RULE_AUDIT.md).

## `hidden-reveal`: active reveal helper for a hidden compulsory skill

This companion scenario keeps Lục Tốn + Tôn Quyền hidden, exposes the fake
`hs__qianxun` trigger and asks the real native `reveal_skill&` helper. The owner
must select the Lua interaction `revealMain:::hs__luxun`; the server then reveals
Lục Tốn, leaves the deputy hidden and activates Tỏa định. The opponent receives
only the public log, not the private active-skill request.

```bash
TQS_LIVE_SCENARIO=hidden-reveal \
TQS_LIVE_NATIVE_QA=1 \
TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual
```

This proves the active reveal/projection path and privacy boundary; it does not
replace the three `hidden-yiji` branches above. The paired
`hidden-reveal-deputy` scenario selects `revealDeputy:::hs__luxun` and checks
the same rule when Lục Tốn is the deputy. Current native evidence is
linked from [`QUOC_CHIEN_RULE_AUDIT.md`](../../../../docs/web-client/QUOC_CHIEN_RULE_AUDIT.md).

## `hidden-active`: active skill of a hidden deputy

This scenario checks the separate rule that a hidden general may have an active
skill available when its activation condition is satisfied. The actor is
Lục Tốn + Tôn Quyền with both generals hidden and one reserved Slash. The
native client must project fake `hs__zhiheng` as a regular skill button (not as
a prelight trigger), then the browser selects that skill and the Slash in a
real `PlayCard` request.

```bash
TQS_LIVE_SCENARIO=hidden-active \
TQS_LIVE_NATIVE_QA=1 \
TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual
```

The native director verifies the full result: Chế Hành receives exactly one
card, reveals Tôn Quyền before `SkillEffect`, keeps Lục Tốn hidden, discards
the reserved Slash and draws one replacement. The opponent sees only the
public log and never receives the private `PlayCard` request. This scenario is
also linked from [`QUOC_CHIEN_RULE_AUDIT.md`](../../../../docs/web-client/QUOC_CHIEN_RULE_AUDIT.md).

## `hidden-view-as`: ViewAs skill of a hidden general

This companion scenario keeps Triệu Vân hidden, projects fake `hs__longdan` as
a regular skill, and reserves one Jink. The browser must select Longdan and
the Jink in a native `PlayCard` request. FreeKill then reveals Triệu Vân in the
slot that owns the skill before `SkillEffect`, converts Jink to Slash, and keeps
the private request on the owner client. `hidden-view-as-main` repeats the same
check with Triệu Vân in the main slot; `hidden-view-as` uses the deputy slot.

## `hidden-dual`: trigger bắt buộc + ViewAs khi tướng còn úp

Ca này giữ Nhan Lương/Văn Sửu + Viên Thiệu úp, prelight `hs__shuangxiong`,
rồi phát động đúng `EventPhaseStart` ở pha Chơi. Song Hùng là trigger bắt buộc
trong source gốc, nên sau gate chuẩn bị **không có** một `AskForSkillInvoke`
thứ hai. Chuỗi native cần quan sát là:

```text
AskForSkillInvoke (QA gate) → AskForUseActiveSkill (chọn người)
→ askToDiscard(cancelable=false) → PlayCard (ViewAs Duel)
```

Fixture đặt đúng một Jink đỏ ở tay mục tiêu và một Sát đen ở tay actor. Vì
`askToDiscard` không cancel được và mục tiêu chỉ có một lá hợp lệ, native tự bỏ
Jink trước khi gửi `PlayCard`; browser runner ghi nhận đây là `auto-discard`,
không chờ một request UI thứ hai. Native director vẫn kiểm tra mark màu, hand
movement, `hs__shuangxiong`, subcard và Duel thật trước khi kết thúc room.

Chạy acceptance:

```bash
TQS_LIVE_SCENARIO=hidden-dual \
TQS_LIVE_NATIVE_QA=1 \
TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 \
npm run test:e2e:multiplayer -- --manual
```

Đây là scenario bổ sung cho ma trận Di Kế/hidden-trigger; evidence và identity
không chép lại ở README mà giữ tập trung trong
[`QUOC_CHIEN_RULE_AUDIT.md`](../../../../docs/web-client/QUOC_CHIEN_RULE_AUDIT.md).

### Slot mirror checks

The same native director also runs the position mirrors below. They are kept
as separate scenario IDs so the evidence cannot silently pass by opening the
wrong slot:

| Scenario | Mirror being proved |
| --- | --- |
| `hidden-yiji-deputy` | Quách Gia is the deputy; positive Di Kế opens the deputy. |
| `hidden-jianxiong-deputy` | Cao Cao is the deputy; Jianxiong opens the deputy and obtains the damage card. |
| `hidden-reveal-deputy` | Lục Tốn is the deputy; `revealDeputy` opens only the deputy. |
| `hidden-active-main` | Tôn Quyền is the main; Chế Hành opens only the main. |
| `hidden-view-as-main` | Triệu Vân is the main; Longdan opens only the main and converts Jink to Slash. |
| `hidden-luoshen` | 甄姬 is the main; `EventPhaseStart` opens only the main and obtains the black judgment card. |
| `hidden-luoshen-deputy` | 甄姬 is the deputy; `EventPhaseStart` opens only the deputy and obtains the black judgment card. |

The current 12-case core NATIVE-LOCAL matrix is: `hidden-yiji` negative/positive/skip,
`hidden-yiji-deputy`, `hidden-jianxiong` and `hidden-jianxiong-deputy`,
`hidden-reveal` and `hidden-reveal-deputy`, `hidden-active` and
`hidden-active-main`, plus `hidden-view-as` and `hidden-view-as-main`. The
staged `hidden-dual`, `hidden-fankui` and `hidden-luoshen` add-ons are tracked
separately because they use newer QA package identities. The canonical evidence table and package identities remain in
[`QUOC_CHIEN_RULE_AUDIT.md`](../../../../docs/web-client/QUOC_CHIEN_RULE_AUDIT.md);
this README intentionally does not duplicate the full logs or hashes.
