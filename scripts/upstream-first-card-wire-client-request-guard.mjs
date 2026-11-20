// Install the candidate-only client request envelope/reply bridge.
// It is a no-op in legacy mode and never negotiates v1. Usage:
//   node ... --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { updateRequestVisibility } from '../deploy/freekill-native/scripts/card-wire-request-runtime.mjs';

const [mode, input] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && input,
  'usage: --apply|--check <candidate-core>');
const root = fs.realpathSync(input);
assert.match(root, /(?:\/scratch\/evidence\/[^/]+\/candidate-runtime|\/private\/tmp\/tqs-cardwire-qa-20261103-[^/]+)\/packages\/freekill-core$/u,
  'client request bridge is restricted to the isolated candidate');
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
updateRequestVisibility(root, mode);

const moduleRel = 'ltk/client/card_wire_requests.lua';
const moduleTarget = path.join(root, moduleRel);
const moduleExpected = fs.readFileSync(
  path.join(repoRoot, 'deploy/freekill-native/qa/card-wire-client-requests.lua'), 'utf8');
if (mode === '--apply' && (!fs.existsSync(moduleTarget) ||
    fs.readFileSync(moduleTarget, 'utf8') !== moduleExpected)) {
  fs.writeFileSync(moduleTarget, moduleExpected);
}
assert.equal(fs.readFileSync(moduleTarget, 'utf8'), moduleExpected,
  'candidate client request module drifted from reviewed source');

function ensure(rel, anchor, inserted) {
  const target = path.join(root, rel);
  assert.equal(fs.realpathSync(target), target, `${rel} must not be a symlink`);
  let source = fs.readFileSync(target, 'utf8');
  if (!source.includes(inserted)) {
    assert.equal(mode, '--apply', `${rel} is missing the guarded request bridge`);
    assert.equal(source.split(anchor).length, 2, `${rel} request bridge anchor changed`);
    source = source.replace(anchor, inserted + anchor);
    fs.writeFileSync(target, source);
  }
  assert.equal(source.split(inserted).length, 2, `${rel} request bridge must appear once`);
}

ensure('lua/client/client.lua',
  `  if table.contains(pattern_refresh_commands, command) then\n`,
  `  -- TQS_HEG_CARD_WIRE_CLIENT_REQUEST: unwrap only an explicit v1 request\n  -- envelope. A missing/legacy payload is never silently interpreted as v1.\n  if self.card_wire_version == 1 and type(data) == "table" and\n      data.cardWireVersion == 1 then\n    data = require("ltk.client.card_wire_requests").receive(self, command, data)\n  end\n\n`);

ensure('standard/aux_skills_dir/ex__choose_skill.lua',
  '    if self.will_throw and player:prohibitDiscard(card) then\n',
  `    -- TQS_HEG_CARD_WIRE_CHOOSER: the v1 request can offer a newly drawn\n    -- card whose local alias has no physical Fk.cards record.  Only the\n    -- active request's exact positive-ID matcher can authorize that alias.\n    if not card and ClientInstance and ClientInstance.card_wire_version == 1 then\n      return require("ltk.client.card_wire_requests")\n        .matchesOfferedIdOnlyPattern(ClientInstance, self, to_select)\n    end\n\n`);

ensure('lua/client/client_util.lua',
  'local requestUIUpdating = false\n',
  `-- TQS_HEG_CARD_WIRE_CLIENT_REPLY: all QML replies pass through Lua so a\n-- request-local local alias can be converted to its one-shot wire token.\nfunction ReplyToServer(data)\n  local self = ClientInstance\n  if self.card_wire_version == 1 then\n    data = require("ltk.client.card_wire_requests").encodeReply(self, data)\n  end\n  assert(self.client and type(self.client.replyToServer) == "function",\n    "client reply transport is missing")\n  self.client:replyToServer("", cbor.encode(data))\nend\n\n`);

ensure('Fk/Base/LuaUtil.qml',
  '  function getPlayersAndObservers() {\n',
  `  function replyToServer(data) {\n    return call("ReplyToServer", data);\n  }\n\n`);

function visit(directory, files = []) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) visit(target, files);
    else if (entry.isFile() && target.endsWith('.qml')) files.push(target);
  }
  return files;
}

const qmlRoot = path.join(root, '..');
for (const target of visit(qmlRoot)) {
  if (target.includes(`${path.sep}test${path.sep}`)) continue;
  const source = fs.readFileSync(target, 'utf8');
  const replaced = source.replaceAll('ClientInstance.replyToServer("",', 'Lua.replyToServer(');
  if (replaced !== source) {
    assert.equal(mode, '--apply', `QML reply bypass remains in ${path.relative(root, target)}`);
    fs.writeFileSync(target, replaced);
  }
}
for (const target of visit(qmlRoot)) {
  if (target.includes(`${path.sep}test${path.sep}`)) continue;
  const source = fs.readFileSync(target, 'utf8');
  assert.equal(source.includes('ClientInstance.replyToServer("",'), false,
    `QML reply bypass remains in ${path.relative(root, target)}`);
}

console.log(`PASS isolated Hegemony client request bridge ${mode.slice(2)}: envelope localization, Lua reply translation, legacy QML preserved; v1 disabled`);
