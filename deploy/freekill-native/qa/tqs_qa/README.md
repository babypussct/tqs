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
