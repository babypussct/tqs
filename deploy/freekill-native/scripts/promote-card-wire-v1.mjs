#!/usr/bin/env node

// Promote the reviewed card-wire runtime from the isolated candidate into an
// immutable native release root. This is deliberately an artifact transform:
// it never writes the repository runtime and refuses QA-only packages or
// symlinked package trees.

import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { updatePublicGeneralSource } from './hegemony-public-general.mjs';
import { updateRequestVisibility } from './card-wire-request-runtime.mjs';

const args = Object.fromEntries(process.argv.slice(2).map((arg) => {
  const separator = arg.indexOf('=');
  if (!arg.startsWith('--') || separator < 3) throw new Error(`Expected --key=value, got ${arg}`);
  return [arg.slice(2, separator), arg.slice(separator + 1)];
}));
assert.ok(args.root, 'Usage: promote-card-wire-v1.mjs --root=/isolated/native-release-root');

const root = path.resolve(args.root);
const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const repositoryRuntime = path.join(repositoryRoot, 'runtime');
assert.notEqual(root, repositoryRuntime, 'Refusing to promote directly into repository runtime');
assert.ok(fs.existsSync(path.join(root, 'packages')), `Missing native release packages: ${root}`);

const packages = path.join(root, 'packages');
const core = path.join(packages, 'freekill-core');
const hegemony = path.join(packages, 'hegemony');
for (const target of [core, hegemony]) {
  assert.ok(fs.existsSync(target), `Missing package: ${target}`);
  assert.equal(fs.lstatSync(target).isSymbolicLink(), false, `Symlinked package is not promotable: ${target}`);
}
assert.equal(fs.existsSync(path.join(packages, 'tqs_qa')), false,
  'QA-only tqs_qa package cannot enter the production release');
assert.equal(fs.existsSync(path.join(core, 'qa_packages')), false,
  'QA-only qa_packages tree cannot enter the production release');

function editOnce(file, before, after, label) {
  const source = fs.readFileSync(file, 'utf8');
  if (source.includes(after)) return source;
  assert.equal(source.split(before).length, 2, `${label}: source anchor drifted`);
  const next = source.replace(before, after);
  fs.writeFileSync(file, next);
  return next;
}

const roomFile = path.join(core, 'lua/server/roombase.lua');
const qaOnlyGate = [
  '  assert(type(ServerConfig) == "table" and type(ServerConfig.tqsQa) == "table" and',
  '    ServerConfig.tqsQa.enabled == true and ServerConfig.tqsQa.cardWireVersion == 1,',
  '    "card wire negotiation is QA opt-in only")',
].join('\n');
const productionGate = [
  '  local qaConfig = type(ServerConfig) == "table" and ServerConfig.tqsQa or nil',
  '  local productionConfig = type(ServerConfig) == "table" and ServerConfig.tqsCardWire or nil',
  '  local qaEnabled = type(qaConfig) == "table" and qaConfig.enabled == true and',
  '    qaConfig.cardWireVersion == 1',
  '  local productionEnabled = type(productionConfig) == "table" and',
  '    productionConfig.enabled == true and productionConfig.version == 1 and',
  '    productionConfig.admission ~= "legacy"',
  '  assert(qaEnabled or productionEnabled,',
  '    "card wire negotiation is not enabled for this release")',
].join('\n');
let roomSource = editOnce(roomFile, qaOnlyGate, productionGate,
  'production card-wire negotiation gate');
roomSource = roomSource.replace(
  '-- TQS_HEG_CARD_WIRE_NEGOTIATION: QA-only ordered opt-in. The capability\n',
  '-- TQS_HEG_CARD_WIRE_NEGOTIATION: ordered production/QA opt-in. The capability\n',
);
roomSource = roomSource.replace(
  '-- is inert unless the isolated QA config explicitly sets cardWireVersion=1;\n' +
  '-- production/current configs do not contain that field.\n',
  '-- is inert unless the exact release config explicitly enables version 1.\n',
);
fs.writeFileSync(roomFile, roomSource);

const modeFile = path.join(hegemony, 'pkg/gamemodes/new_hegemony_mode.lua');
const qaHook = [
  '  local preDrawHook = self.room.__tqs_qa_beforePrepareDrawPile',
  '  if type(preDrawHook) == "function" then',
  '    preDrawHook(self.room)',
  '  end',
].join('\n');
const productionHook = [
  '  -- The negotiation marker must precede PrepareDrawPile and every card-bearing',
  '  -- notification. A capability mismatch selects one whole-room legacy',
  '  -- session; it never creates a mixed v1/legacy room.',
  '  local productionConfig = type(ServerConfig) == "table" and ServerConfig.tqsCardWire or nil',
  '  if type(productionConfig) == "table" and productionConfig.enabled == true and',
  '      productionConfig.version == 1 and productionConfig.admission ~= "legacy" then',
  '    assert(type(self.room.negotiateCardWireV1) == "function" and',
  '      type(self.room.hasAllCardWireCapabilities) == "function",',
  '      "card wire v1 production seam is missing")',
  '    if self.room:hasAllCardWireCapabilities() then',
  '      self.room:negotiateCardWireV1()',
  '      self.room.card_wire_negotiation_state = "v1"',
  '    else',
  '      self.room.card_wire_negotiation_state = "legacy"',
  '      self.room.card_wire_protocol = "legacy"',
  '    end',
  '  end',
  '',
  ...qaHook.split('\n'),
].join('\n');
editOnce(modeFile, qaHook, productionHook, 'production pre-draw negotiation boundary');

updatePublicGeneralSource(core, '--apply');
updateRequestVisibility(core, '--apply');
const wireModules = [
  ['lua/server/card_wire_projection.lua', 'card-wire-projection.lua',
    'ec4410704892385bb151bfc5781ea0f24a798c00f606ea0e2a3890ece1392dfe'],
  ['lua/server/card_wire_request.lua', 'card-wire-request.lua',
    '779b3bc22a99e737005a89170bca3d7bb2f7acbc9828b34258edf6bce4e931e1'],
  ['ltk/client/card_wire_requests.lua', 'card-wire-client-requests.lua',
    '63c412fefb35eb3d3c344543dd787375e406bc782d69da322379faab3fa04e71'],
];
for (const [relative, reviewedFile, previousHash] of wireModules) {
  const target = path.join(core, relative);
  assert.equal(fs.realpathSync(target), target, `Symlinked module is not promotable: ${relative}`);
  const installed = fs.readFileSync(target);
  const reviewed = fs.readFileSync(path.join(repositoryRoot, 'deploy/freekill-native/qa', reviewedFile));
  if (!installed.equals(reviewed)) {
    assert.equal(createHash('sha256').update(installed).digest('hex'), previousHash,
      `Previous production module bytes drifted: ${relative}`);
    fs.writeFileSync(target, reviewed);
  }
}

const configFile = path.join(root, 'freekill.server.config.json');
let config = {};
if (fs.existsSync(configFile)) {
  config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
} else {
  const templateFile = path.join(repositoryRoot, 'deploy/freekill-native/server/freekill.server.config.json');
  config = JSON.parse(fs.readFileSync(templateFile, 'utf8'));
}
config.tqsCardWire = { enabled: true, version: 1, admission: 'v1' };
fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + '\n');

console.log(JSON.stringify({
  root,
  production: { cardWireVersion: 1, admission: 'v1' },
  changed: [
    'packages/freekill-core/lua/server/roombase.lua',
    ...wireModules.map(([relative]) => `packages/freekill-core/${relative}`),
    'packages/freekill-core/ltk/core/card_wire_request_visibility.lua',
    'packages/freekill-core/ltk/core/engine.lua',
    'packages/freekill-core/ltk/server/serverplayer.lua',
    'packages/hegemony/pkg/gamemodes/new_hegemony_mode.lua',
    'freekill.server.config.json',
  ],
}));
