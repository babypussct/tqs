// Explicit, reproducible source-level delta regression for the selected
// Hegemony snapshot. Native game-room and browser acceptance remain separate.
// Run with TQS_UPSTREAM_CORE_ROOT and TQS_UPSTREAM_HEGEMONY_PKG_ROOT set.
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '../../..');
const coreRoot = process.env.TQS_UPSTREAM_CORE_ROOT;
const pkgRoot = process.env.TQS_UPSTREAM_HEGEMONY_PKG_ROOT;
const mergedHegemonyRoot = process.env.TQS_UPSTREAM_HEGEMONY_RUNTIME_ROOT;
const luaExecutable = process.env.TQS_LUA_BIN ?? 'lua5.4';

assert.ok(coreRoot && pkgRoot,
  'Set TQS_UPSTREAM_CORE_ROOT and TQS_UPSTREAM_HEGEMONY_PKG_ROOT to the exact isolated candidate source roots');
assert.match(path.basename(luaExecutable), /^lua5\.4$/u,
  'TQS_LUA_BIN must point to a Lua 5.4 executable named lua5.4');

const selectedSkills = new Map([
  ['standard/skills/tieqi.lua', 'c35cc7106119aaaef9ada526f07c1ecc9fbdf28c83bb8e31f673f5591f756b38'],
  ['power/skills/tieqi.lua', '15411be129b74a2a76bcc84aca7ae6e3aef76aa95d6c848b1dfa009931b5e409'],
  ['tenyear_heg/skills/zhente.lua', '81e6f97a61c1b067ce530234735155214548d392c84b5dcebe5da2acaf124cc7'],
  ['strategic_advantage/skills/halberd.lua', '7ff4360c47d052a6cbc8465cfe04ad0f1f980e4225427eded577bd53439e5a84'],
  ['mobile_heg/skills/bawei.lua', '66c0bf908140b75698ef884762c107860290cda2306dd9c03622a7ca3e3cd6e4'],
  ['mobile_heg/skills/fengshi.lua', 'c348ca0b3027e1ae0eaca9634a30342515b02310d87a4fcca7f5eda666fd2bfe'],
  ['lord_ex/skills/xishe.lua', '3eb12d23adca3714909b7f39dcac7b9f00434bf3c4a27922dbc22a5ca137c4ea'],
]);

function runLua(script, args) {
  return execFileSync(luaExecutable, [path.join(here, script), ...args], {
    encoding: 'utf8', timeout: 30_000, maxBuffer: 1024 * 1024,
  });
}

test('candidate skill bytes match the frozen Hegemony e8d93acd target', () => {
  for (const [relative, expected] of selectedSkills) {
    const source = fs.readFileSync(path.join(pkgRoot, relative));
    assert.equal(createHash('sha256').update(source).digest('hex'), expected, relative);
  }
  assert.equal(fs.existsSync(path.join(pkgRoot, 'strategic_advantage/skills/halberd_active.lua')),
    false, 'the removed standalone Halberd active skill must not be registered twice');
});

test('candidate SetPlayerState teardown compatibility guard is installed only in the isolated core', () => {
  const guard = path.join(repoRoot, 'scripts/upstream-first-set-player-state-compat-guard.mjs');
  const result = spawnSync(process.execPath, [guard, '--check', coreRoot], {
    encoding: 'utf8', timeout: 30_000,
  });
  assert.ifError(result.error);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /SetPlayerState compatibility guard --check: already applied/u);
  assert.equal(result.stderr, '');
});

test('candidate Hegemony negotiates card wire before preparing the draw pile', () => {
  const hegemonyMode = fs.readFileSync(
    path.join(pkgRoot, 'gamemodes/new_hegemony_mode.lua'), 'utf8');
  const preDraw = hegemonyMode.indexOf(
    'local preDrawHook = self.room.__tqs_qa_beforePrepareDrawPile');
  const prepareDrawPile = hegemonyMode.indexOf('GameLogic.prepareDrawPile(self)');
  assert.ok(preDraw >= 0, 'candidate Hegemony pre-draw callback is missing');
  assert.ok(prepareDrawPile > preDraw,
    'card-wire pre-draw callback must run before physical PrepareDrawPile');

  const qaInit = fs.readFileSync(path.join(here, 'tqs_qa/init.lua'), 'utf8');
  assert.match(qaInit, /config\.cardWireVersion == 1/u,
    'QA card-wire hook must remain explicitly version-gated');
  assert.match(qaInit, /room\.card_wire_negotiated == true then return/u,
    'late GamePrepared hook must not negotiate twice');
});

test('real upstream Tieqi (both variants) and Zhente callbacks pass 22 source cases', () => {
  const output = runLua('tieqi-zhente-source-probe.lua', [coreRoot, pkgRoot]);
  assert.match(output, /PASS tieqi real upstream callbacks: 16 cases \(2 variants\)/u);
  assert.match(output, /PASS zhente real upstream callbacks: 6 cases/u);
  assert.match(output, /PASS total source-level probes: 22; native\/browser NOT RUN/u);
});

test('real upstream Halberd callbacks pass 7 source cases', () => {
  const output = runLua('halberd-source-probe.lua', [coreRoot,
    path.join(pkgRoot, 'strategic_advantage/skills/halberd.lua')]);
  assert.match(output, /PASS halberd real upstream callbacks: 7 cases; native\/browser NOT RUN/u);
});

test('real core helper, Bawei and Fengshi callbacks pass 13 source cases', () => {
  const output = runLua('mobile-heg-disresponsive-probe.lua', [coreRoot,
    path.join(pkgRoot, 'mobile_heg/skills')]);
  assert.match(output, /PASS mobile-heg real core: 3 cases/u);
  assert.match(output, /PASS mobile-heg real upstream skill callbacks: 10 cases/u);
});

test('real upstream Xishe equipment, response and deputy callbacks pass 15 source cases', () => {
  const output = runLua('xishe-source-probe.lua', [coreRoot,
    path.join(pkgRoot, 'lord_ex/skills/xishe.lua')]);
  assert.match(output, /PASS xishe real upstream callbacks and core helper: 15 cases; native\/browser NOT RUN/u);
});

test('merged Hegemony utility preserves hidden-slot ownership and event-based removal', {
  skip: !mergedHegemonyRoot && 'Set TQS_UPSTREAM_HEGEMONY_RUNTIME_ROOT for isolated merged-runtime coverage',
}, () => {
  const output = runLua('hegemony-util-source-probe.lua', [mergedHegemonyRoot]);
  assert.match(output, /PASS Hegemony merged util source: 7 hidden-owner, 2 dispatch, 3 remove-event cases/u);
});

test('candidate Hegemony private wire excludes nonowner and observer metadata', () => {
  const output = runLua('hidden-wire-privacy-source-probe.lua', [coreRoot]);
  assert.match(output, /PASS actual Lua private-wire incremental: 9; property projection: 11; reconnect projection: 10; observe: 8; other-mode: 3; initial setup: 4; fake-skill route: 11; native\/browser NOT RUN/u);
});

test('candidate card marks conceal hand and private special-pile IDs from outsiders and reconnect', () => {
  const output = runLua('card-mark-privacy-source-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate real card-mark source: incremental 9; snapshots 4; other-mode 3; native\/browser NOT RUN/u);
});

test('per-connection opaque card references enforce choice/rekey/reconnect invariants', () => {
  const output = runLua('card-handle-protocol-probe.lua',
    [path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS opaque card-handle contract: physical audiences, choice scope, replay, reveal, rehide, shuffle, reconnect, token collision, printed\/virtual IDs, strict CBOR arrays; multi-recipient atomic commit\/abort\/tombstones, staged choice allowlists, physical reconnect reset; synthetic-only; native\/browser NOT RUN/u);
});

test('client-local card identity hides opaque aliases and rejects stale or anonymous choices', () => {
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-client-refs-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated client alias source --check/u);
  const output = runLua('card-wire-client-refs-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate client-local references: opaque\/local\/reverse, collision, visible fallback, unknown deck, stale\/rekey\/reconnect, no alias recycling; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate count-only deck uses real Client/CardManager callbacks and retires anonymous positions', () => {
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-client-deck-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated count-only client deck --check/u);
  const output = runLua('card-wire-client-deck-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate count-only client deck: real Client\/CardManager callbacks, anonymous aliases, tracker and area retirement, shuffle discard reset, count\/schema\/mode fail-close, zero count and legacy; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate ChangeCardArea preserves public zones and replaces hidden deck state without order', () => {
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-client-area-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated count-only ChangeCardArea client --check/u);
  const output = runLua('card-wire-client-area-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate ChangeCardArea client: public discard\/void refs, draw rekey, anonymous count state, schema\/mode\/legacy fail-close; 5 cases; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate MoveCards and SetPlayerPile localize projected references before CardManager', () => {
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-client-moves-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated Hegemony v1 MoveCards\/SetPlayerPile client bridge --check/u);
  const output = runLua('card-wire-client-moves-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate MoveCards\/SetPlayerPile client: local alias transitions, anonymous draw consumption, public reveal\/rehide, private pile trackers, standing-ref\/source-area rekey, schema\/mode\/legacy fail-close; 10 cases; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate client request bridge localizes opaque choices and reverses one-shot replies', () => {
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-client-request-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated Hegemony client request bridge check/u);
  const output = runLua('card-wire-client-request-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate client request bridge: standing\/local alias localization, AG\/Poxi\/PlayCard\/active payloads, preview\/one-shot reply tokens, anonymous\/stale\/sparse fail-close and legacy; synthetic-only; native\/browser NOT RUN/u);
});

test('browser gameplay replies share the translated Lua card-wire path', () => {
  const repoRoot = path.resolve(here, '../../..');
  const output = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-web-card-wire-reply-guard.mjs'),
      '--check', path.join(repoRoot, 'game/web/src/engine/hostLua.ts')],
    { encoding: 'utf8', timeout: 30_000 });
  assert.match(output, /PASS browser card-wire reply bridge/u);
});

test('candidate client snapshot bridge localizes Reconnect and Observe before deserialize', () => {
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-client-snapshot-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated Hegemony client snapshot bridge check/u);
  const output = runLua('card-wire-client-snapshot-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate client snapshots: count-only deck, public\/opaque player refs, card-mark localization, session reset, malformed\/legacy fail-close; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate client public bridge reconstructs audited ShowVirtualCard and GameLog descriptors', () => {
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-client-public-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated Hegemony client public bridge check/u);
  const output = runLua('card-wire-client-public-probe.lua', [coreRoot,
    path.join(coreRoot, 'ltk/client/card_wire_public.lua'),
    path.join(coreRoot, 'ltk/client/card_wire_refs.lua')]);
  assert.match(output, /PASS candidate public client: ShowVirtualCard\/GameLog descriptor decode, canonical refs, virtual marks\/subcards, unknown and malformed\/opaque\/legacy fail-close; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate client metadata bridge localizes audited card references before callbacks and UI', () => {
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-client-metadata-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated Hegemony client metadata bridge check/u);
  const output = runLua('card-wire-client-metadata-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate card metadata client: actual ClientCallback envelope localization, AG refs, owner\/player mapping, virtual IDs, hidden draw no-op, schema\/legacy fail-close; 11 cases; synthetic-only; native\/browser NOT RUN/u);
});

test('isolated candidate dispatch projects CBOR separately to each physical connection', () => {
  const output = runLua('card-wire-dispatch-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS candidate physical-recipient CBOR dispatcher: independent seat\/observer projection, multi-recipient atomic rollback on projector\/CBOR failure, fail-closed opt-in, physical reconnect, robot\/legacy; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate server and client complete an audited Lua CBOR round trip', () => {
  const output = runLua('card-wire-cbor-integrated-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS integrated candidate Lua CBOR wire: actual ServerPlayerBase physical CBOR isolation\/stability, audited public GameLog decode through ClientCallback; 3 cases; native C\+\+\/browser\/two-account NOT RUN/u);
});

test('candidate deck, area, private-pile and hidden-move notifications use the v1 physical path', () => {
  const output = runLua('card-wire-notification-cbor-integrated-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS integrated candidate notification Lua CBOR wire: actual broadcast\/notify bodies for count-only deck, ChangeCardArea, private pile, hidden MoveCards, card metadata, public AG, GameOver and metadata schemas; 16 cases; native C\+\+\/browser\/two-account NOT RUN/u);
});

test('candidate Request send and reply complete an audited Lua CBOR round trip', () => {
  const output = runLua('card-wire-request-cbor-integrated-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS integrated candidate Request Lua CBOR wire: actual Request send projection\/decode, client local-alias\/reverse-token, canonical resolver reply; 4 cases; native C\+\+\/browser\/two-account NOT RUN/u);
});

test('candidate Reconnect and Observe snapshots complete an audited Lua CBOR round trip', () => {
  const output = runLua('card-wire-snapshot-cbor-integrated-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS integrated candidate snapshot Lua CBOR wire: actual Reconnect\/Observe projection\/decode, count-only deck, owner\/observer private refs and card-mark localization; 4 cases; native C\+\+\/browser\/two-account NOT RUN/u);
});

test('candidate v1 physical privacy covers the twelve legacy exposure categories', () => {
  const output = runLua('card-wire-privacy-v1-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS candidate v1 physical privacy: actual dispatcher\/CBOR prepare, shuffle, sync, ChangeCardArea, peer\/observer MoveCards, private pile, Reconnect and Observe; 12 categories; legacy strict gate remains separate; native C\+\+\/browser\/two-account NOT RUN/u);
});

test('strict negotiated v1 source gate audits all physical CBOR and embedded card marks', () => {
  const result = spawnSync(luaExecutable, [path.join(here, 'card-wire-privacy-v1-source-probe.lua'),
    coreRoot, path.join(here, 'card-handle-protocol.lua'), '--strict'],
    { encoding: 'utf8', timeout: 30_000 });
  assert.ifError(result.error);
  assert.equal(result.status, 0, 'all twelve negotiated v1 source exposures must be absent');
  assert.match(result.stdout, /CARD_WIRE_PRIVACY_V1=PASS; audited_categories=12; entire decoded physical Lua CBOR and nested card marks; synthetic-only; native C\+\+\/browser\/two-account NOT RUN/u);
  assert.equal(result.stderr, '');
});

test('native deck boundary audit rejects legacy identities and supplementary deck fields', () => {
  const output = runLua('card-wire-native-deck-audit-probe.lua',
    [path.join(here, 'card-wire-native-deck-audit.lua')]);
  assert.match(output, /PASS native deck audit regression: 63 cases; synthetic-only/u);
});

test('candidate QA negotiation activates v1 only after a card-free legacy envelope', () => {
  const output = runLua('card-wire-negotiation-source-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate card-wire negotiation: actual QA room helper, legacy CBOR envelope, per-physical dedupe, client capability advertise, wrong version\/protocol\/mode rejection, actual ClientCallback activation, active-v1 no-downgrade and malformed\/legacy fail-closed; 12 cases; native C\+\+\/browser\/two-account NOT RUN/u);
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-capability-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated Hegemony card-wire capability guard --check/u);
});

test('direct Observe snapshots project only for their physical observer and roll back on failure', () => {
  const output = runLua('card-wire-observer-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS candidate direct Observe: physical-only snapshot projection, mode\/version fail-closed, projector\/CBOR rollback, independent observer handles, refresh reset, robot\/legacy; synthetic-only; native\/browser NOT RUN/u);
});

test('owner-only role, concealed general and marks use real physical socket projection', () => {
  const output = runLua('card-wire-private-physical-source-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate direct owner-only physical: role\/general\/mark projected per socket, observer\/opponent isolation, projector\/CBOR abort, fail-closed opt-in, public and legacy paths; synthetic-only; native\/browser NOT RUN/u);
});

test('first reveal publishes only the revealed slot to opponents, observers and snapshots', () => {
  const output = runLua('hegemony-public-general-source-probe.lua', [path.dirname(coreRoot)]);
  for (const wire of ['1', 'legacy']) {
    for (const slot of ['general', 'deputyGeneral']) {
      assert.ok(output.includes(`PASS wire=${wire} first=${slot} owner/opponent/observer/reconnect`));
    }
  }
});

test('concealed physical SetCardMark is projected per owner and fails closed before CBOR delivery', () => {
  const output = runLua('card-wire-card-mark-physical-source-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate physical SetCardMark: owner\/private-pile projection, other socket and observer isolation, deck\/public separation, atomic projector\/CBOR rollback, fail-closed opt-in, robot\/legacy; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate native card-wire runtime uses OS entropy and atomic physical-audience batches', () => {
  const output = runLua('card-wire-secure-runtime-source-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate native card-wire entropy: OS CSPRNG, per-physical audience, replay, reconnect, abort, entropy failure, guarded opt-in; synthetic IDs; native\/browser NOT RUN/u);
  const mint = fs.readFileSync(path.join(here, 'card-wire-secure-mint.lua'), 'utf8');
  assert.match(mint, /cardWireEntropyFailureAfter/u);
  assert.match(mint, /card_wire_entropy_rejected mode=controlled kind=%s/u);
  assert.match(mint, /card wire v1 requires OS CSPRNG: controlled QA failure/u);
});

test('candidate card-wire P6 measures bounded projection, CBOR, mapping and cleanup metadata', () => {
  const output = runLua('card-wire-performance-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /CARD_WIRE_PERFORMANCE=PASS;cases=\d+;audiences=3;iterations=12;project_p95_us=\d+;serialize_p95_us=\d+;max_wire_bytes=\d+;max_active_refs=\d+;cleanup_us=\d+;cleanup_active_refs=0;foreign_rejects=1;replay_rejects=1;stale_rejects=1;retired_tombstones=\d+;synthetic-only;native\/browser NOT RUN/u);
  assert.match(output, /^CARD_WIRE_MAPPING_HEAP=OBSERVED;active_delta_bytes=-?\d+;disconnect_delta_bytes=-?\d+;release_delta_bytes=-?\d+;retired_tombstones=240$/mu);
});

test('human Request packets and replies use physical, request-scoped card references', () => {
  const output = runLua('card-wire-request-source-probe.lua',
    [coreRoot, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS candidate Request source: per-physical projection, CBOR preflight, canonical reply, forged\/replay\/expired\/invalid-CBOR rejection, wrong-physical rejection, atomic redraw replacement, timeout cleanup, no downgrade and legacy; synthetic-only; native\/browser NOT RUN/u);
});

test('candidate Request projector removes card IDs before transport and resolves opaque replies', () => {
  const output = runLua('card-wire-request-projector-source-probe.lua',
    [coreRoot, path.join(here, 'card-wire-request.lua'), path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS candidate physical request projector: card-chosen opaque scope, Poxi\/AG\/PlayCard projection, active-skill reply resolution, CustomDialog exact schemas, scalar choices, malformed\/unaudited fail-close; 21 cases; synthetic-only; native\/browser NOT RUN/u);
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-request-projector-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated Hegemony request projector check/u);
});

test('candidate projector redacts upstream Card objects and rekeys hidden deck for physical viewers', () => {
  const installed = path.join(coreRoot, 'lua/server/card_wire_projection.lua');
  assert.equal(fs.readFileSync(installed, 'utf8'),
    fs.readFileSync(path.join(here, 'card-wire-projection.lua'), 'utf8'));
  const output = runLua('card-wire-projection-source-probe.lua',
    [installed, path.join(here, 'card-handle-protocol.lua')]);
  assert.match(output, /PASS audited card-wire projection: 36 synthetic physical\/privacy\/schema cases; native\/browser NOT RUN/u);
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-projection-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated card-wire projector --check/u);
});

test('candidate MoveCards preserves numeric and player-object viewer lists before per-socket projection', () => {
  const output = runLua('card-wire-visible-players-source-probe.lua', [coreRoot]);
  assert.match(output, /PASS candidate MoveCards viewer ID conversion: numeric arrays, player arrays, single player, absent; native\/browser NOT RUN/u);
  const repoRoot = path.resolve(here, '../../..');
  const guard = execFileSync(process.execPath,
    [path.join(repoRoot, 'scripts/upstream-first-card-wire-visible-players-guard.mjs'),
      '--check', coreRoot], { encoding: 'utf8', timeout: 30_000 });
  assert.match(guard, /PASS isolated Hegemony MoveCards viewer IDs --check/u);
});

test('candidate wire dispatch, physical reconnect, Observe and owner-only sends match reviewed guards', () => {
  const repoRoot = path.resolve(here, '../../..');
  for (const script of [
    'upstream-first-card-wire-dispatch-guard.mjs',
    'upstream-first-card-wire-reconnect-guard.mjs',
    'upstream-first-card-wire-observer-guard.mjs',
    'upstream-first-card-wire-private-physical-guard.mjs',
    'upstream-first-card-wire-runtime-guard.mjs',
    'upstream-first-card-wire-card-mark-physical-guard.mjs',
    'upstream-first-card-wire-client-moves-guard.mjs',
    'upstream-first-card-wire-request-guard.mjs',
    'upstream-first-card-wire-client-request-guard.mjs',
    'upstream-first-card-wire-client-snapshot-guard.mjs',
    'upstream-first-card-wire-client-public-guard.mjs',
    'upstream-first-card-wire-request-projector-guard.mjs',
    'upstream-first-card-wire-capability-guard.mjs',
    'upstream-first-card-mark-owner-guard.mjs',
    'upstream-first-card-mark-guard.mjs',
    'upstream-first-private-wire-guard.mjs',
  ]) {
    const output = execFileSync(process.execPath,
      [path.join(repoRoot, 'scripts', script), '--check', coreRoot],
      { encoding: 'utf8', timeout: 30_000 });
    assert.match(output, /PASS isolated Hegemony/u, script);
  }
});

test('diagnostic: candidate card wire still exposes concealed IDs (privacy release gate OPEN)', () => {
  // A source diagnostic PASS means the known leak was reproduced. The separate
  // --strict invocation is the security gate and currently exits nonzero.
  const output = runLua('card-wire-exposure-source-probe.lua', [coreRoot]);
  assert.match(output, /CARD_WIRE_PRIVACY=OPEN; exposure_categories=/u);
  for (const category of [
    'prepare_order', 'shuffle_order', 'sync_order', 'change_area_order', 'hidden_move_id',
    'observe_hidden_move_id', 'special_pile_id', 'reconnect_deck',
    'reconnect_hand', 'reconnect_special', 'observe_deck', 'observe_hand',
  ]) {
    assert.match(output, new RegExp(`(?:=|,)${category}(?:,|;)`, 'u'));
  }
  assert.match(output, /synthetic-only; native\/browser NOT RUN/u);
});

test('strict card-wire privacy release gate fails closed on current candidate', () => {
  const result = spawnSync(luaExecutable, [path.join(here, 'card-wire-exposure-source-probe.lua'),
    coreRoot, '--strict'], { encoding: 'utf8', timeout: 30_000 });
  assert.ifError(result.error);
  assert.equal(result.status, 2, 'the privacy gate must reject exposed card identifiers');
  assert.match(result.stdout, /CARD_WIRE_PRIVACY=OPEN; exposure_categories=/u);
  assert.equal(result.stderr, '');
});
