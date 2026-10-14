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
