// Install the candidate-only card-wire capability handshake in an isolated
// upstream checkout. Production/current remains legacy-only.
// Usage: node scripts/upstream-first-card-wire-capability-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'expected --apply|--check <candidate-core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'card-wire capability guard is restricted to the isolated candidate');
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function read(rel) {
  const target = path.join(root, rel);
  assert.equal(fs.realpathSync(target), target, `candidate target must not be a symlink: ${rel}`);
  return { target, source: fs.readFileSync(target, 'utf8') };
}

function replaceOnce(rel, before, after, label) {
  const { target, source } = read(rel);
  if (source.includes(after)) return source;
  assert.equal(mode, '--apply', `${label} is missing`);
  assert.equal(source.split(before).length, 2, `${label} source anchor drifted`);
  const next = source.replace(before, after);
  fs.writeFileSync(target, next);
  return next;
}

function replaceFirst(rel, before, after, label) {
  const { target, source } = read(rel);
  if (source.includes(after)) return source;
  assert.equal(mode, '--apply', `${label} is missing`);
  const index = source.indexOf(before);
  assert.ok(index >= 0, `${label} source anchor drifted`);
  const next = source.slice(0, index) + after + source.slice(index + before.length);
  fs.writeFileSync(target, next);
  return next;
}

function replaceAfter(rel, anchor, before, after, label) {
  const { target, source } = read(rel);
  if (source.includes(after)) return source;
  assert.equal(mode, '--apply', `${label} is missing`);
  const anchorIndex = source.indexOf(anchor);
  assert.ok(anchorIndex >= 0, `${label} function anchor drifted`);
  const index = source.indexOf(before, anchorIndex);
  assert.ok(index >= 0, `${label} source anchor drifted`);
  const next = source.slice(0, index) + after + source.slice(index + before.length);
  fs.writeFileSync(target, next);
  return next;
}

function removeOnce(rel, text, label) {
  const { target, source } = read(rel);
  if (!source.includes(text)) return source;
  assert.equal(mode, '--apply', `${label} is still installed`);
  assert.equal(source.split(text).length, 2, `${label} source anchor drifted`);
  const next = source.replace(text, '');
  fs.writeFileSync(target, next);
  return next;
}

const expectedClientModule = fs.readFileSync(
  path.join(repoRoot, 'deploy/freekill-native/qa/card-wire-client-negotiation.lua'), 'utf8');
const clientModule = read('ltk/client/card_wire_negotiation.lua');
if (clientModule.source !== expectedClientModule) {
  assert.equal(mode, '--apply', 'candidate client negotiation module drifted');
  assert.ok(clientModule.source.includes('function Negotiation.receive'),
    'refusing to replace an unrelated candidate negotiation module');
  fs.writeFileSync(clientModule.target, expectedClientModule);
}

const clientEnterCapability = `  if data.gameMode == "new_heg_mode" then\n` +
  `    require("ltk.client.card_wire_negotiation").advertise(self, data.gameMode)\n` +
  `  end\n`;
removeOnce('lua/client/clientbase.lua', clientEnterCapability,
  'early candidate client capability advertisement');
const clientStartCapability = `  -- The candidate capability is sent after ArrangeSeats, not at StartGame:\n` +
  `  -- the server has then materialized the physical seat map and can record the\n` +
  `  -- per-connection opt-in before the pre-draw boundary.\n` +
  `  if self:getSettings("gameMode") == "new_heg_mode" then\n` +
  `    require("ltk.client.card_wire_negotiation").advertise(self, "new_heg_mode")\n` +
  `  end\n` +
  `\n`;
removeOnce('lua/client/clientbase.lua',
  `  -- The server-side game room owns the physical seat map only after StartGame.\n` +
  `  -- Advertise here so the candidate pre-draw boundary can record it while\n` +
  `  -- EnterRoom remains legacy-safe.\n` +
  `  if self:getSettings("gameMode") == "new_heg_mode" then\n` +
  `    require("ltk.client.card_wire_negotiation").advertise(self, "new_heg_mode")\n` +
  `  end\n`, 'early StartGame capability advertisement');
replaceAfter('lua/client/clientbase.lua',
  'function ClientBase:arrangeSeats(player_circle)',
  `  self.players = players\n\n`,
  `  self.players = players\n\n${clientStartCapability}`,
  'candidate client capability advertisement after ArrangeSeats');

// The native game room is recreated for a rematch in the same physical room.
// Reset only after recording and the final GameOver UI callback have completed.
const clientGameOverBefore = `  self.gameStarted = false\n  self:notifyUI("GameOver", jsonData)\nend\n`;
const clientGameOverAfter = `  self.gameStarted = false\n  self:notifyUI("GameOver", jsonData)\n` +
  `  if self:getSettings("gameMode") == "new_heg_mode" then\n` +
  `    require("ltk.client.card_wire_negotiation").endMatch(self)\n` +
  `  end\nend\n`;
replaceAfter('lua/client/clientbase.lua', 'function ClientBase:gameOver(jsonData)',
  clientGameOverBefore, clientGameOverAfter,
  'candidate match-end card-wire capability lifecycle reset');

const callbackBefore = `  self:addCallback("Chat", self.handleChat)\n`;
const callbackAfter = `${callbackBefore}  self:addCallback("card_wire_capability", self.handleCardWireCapability)\n`;
replaceOnce('lua/server/roombase.lua', callbackBefore, callbackAfter,
  'candidate server capability callback');

const capabilityAnchor = `-- TQS_HEG_CARD_WIRE_NEGOTIATION: QA-only ordered opt-in. The capability\n`;
const capabilityBody = `-- TQS_HEG_CARD_WIRE_CAPABILITY: a card-free, per-physical capability\n` +
  `-- announcement gates the QA-only v1 room. Invalid or missing capability\n` +
  `-- never becomes a legacy/v1 mixed session.\n` +
  `function ServerRoomBase:cardWirePhysicalForId(id)\n` +
  `  local seat = self:getPlayerById(id)\n` +
  `  if seat and seat._splayer then return seat._splayer end\n` +
  `  if self.room and type(self.room.getObservers) == "function" then\n` +
  `    for _, physical in fk.qlist(self.room:getObservers()) do\n` +
  `      if physical:getId() == id then return physical end\n` +
  `    end\n` +
  `  end\n` +
  `  for _, item in ipairs(self.observers or {}) do\n` +
  `    local physical = item[2]\n` +
  `    if physical and physical:getId() == id then return physical end\n` +
  `  end\n` +
  `  return nil\n` +
  `end\n\n` +
  `function ServerRoomBase:handleCardWireCapability(id, reqlist)\n` +
  `  if not self._cardWireCapabilities then\n` +
  `    self._cardWireCapabilities = setmetatable({}, { __mode = "k" })\n` +
  `  end\n` +
  `  local physical = self:cardWirePhysicalForId(id)\n` +
  `  local valid = physical and physical:getState() ~= fk.Player_Robot and\n` +
  `    type(reqlist) == "table" and reqlist[3] == "1" and\n` +
  `    reqlist[4] == "TQS_HEG_CARD_WIRE" and reqlist[5] == "new_heg_mode" and\n` +
  `    reqlist[6] == nil\n` +
  `  if valid then\n` +
  `    self._cardWireCapabilities[physical] = true\n` +
  `  elseif physical then\n` +
  `    self._cardWireCapabilities[physical] = nil\n` +
  `  end\n` +
  `end\n\n` +
  `function ServerRoomBase:hasCardWireCapability(physical)\n` +
  `  return type(self._cardWireCapabilities) == "table" and\n` +
  `    self._cardWireCapabilities[physical] == true\n` +
  `end\n\n` +
  `function ServerRoomBase:hasAllCardWireCapabilities(players)\n` +
  `  local seen = {}\n` +
  `  for _, seat in ipairs(players or self.players) do\n` +
  `    local physical = seat._splayer\n` +
  `    if physical and physical:getState() ~= fk.Player_Robot and not seen[physical] then\n` +
  `      seen[physical] = true\n` +
  `      if not self:hasCardWireCapability(physical) then return false end\n` +
  `    end\n` +
  `  end\n` +
  `  return true\n` +
  `end\n\n`;
const installedRoom = read('lua/server/roombase.lua').source;
if (!installedRoom.includes('function ServerRoomBase:handleCardWireCapability')) {
  replaceOnce('lua/server/roombase.lua', capabilityAnchor,
    `${capabilityBody}${capabilityAnchor}`, 'candidate server capability methods');
}

const negotiationPlayersBefore = `  players = players or self.players\n`;
const negotiationPlayersAfter = `${negotiationPlayersBefore}  assert(self:hasAllCardWireCapabilities(players),\n` +
  `    "card wire negotiation requires every physical client capability")\n`;
replaceAfter('lua/server/roombase.lua',
  'function ServerRoomBase:negotiateCardWireV1(players)',
  negotiationPlayersBefore, negotiationPlayersAfter,
  'candidate all-client capability gate');

const observerGateBefore = `  if self.card_wire_version == 1 then\n    assert(self:getSettings("gameMode") == "new_heg_mode" and\n`;
const observerGateAfter = `  if self.card_wire_version == 1 then\n` +
  `    if not self:hasCardWireCapability(player) then\n` +
  `      player:doNotify("ErrorMsg", "card wire capability required")\n` +
  `      if self.room and type(self.room.removeObserver) == "function" then\n` +
  `        self.room:removeObserver(player)\n` +
  `      end\n` +
  `      return false\n` +
  `    end\n` +
  `    assert(self:getSettings("gameMode") == "new_heg_mode" and\n`;
replaceOnce('lua/server/roombase.lua', observerGateBefore, observerGateAfter,
  'candidate observer capability rejection');

const observerAddBefore = `      self:tellRoomToObserver(p)\n`;
const observerAddAfter = `      local accepted = self:tellRoomToObserver(p)\n` +
  `      if accepted == false then return end\n`;
replaceAfter('lua/server/roombase.lua', 'function ServerRoomBase:addObserver(id)',
  observerAddBefore, observerAddAfter,
  'candidate observer add rejection');

const observerReturnBefore = `  table.insert(self.observers, { observee.id, player, player:getId() })\nend\n\nfunction ServerRoomBase:addObserver(id)\n`;
const observerReturnAfter = `  table.insert(self.observers, { observee.id, player, player:getId() })\n  return true\nend\n\nfunction ServerRoomBase:addObserver(id)\n`;
replaceOnce('lua/server/roombase.lua', observerReturnBefore, observerReturnAfter,
  'candidate observer success marker');

const stageBefore = `    if privateWire then\n      local projected = room:projectCardWire(self, physical, command, data, batch)\n`;
const stageAfter = `    if privateWire then\n      assert(type(room.hasCardWireCapability) == "function" and\n` +
  `        room:hasCardWireCapability(physical),\n` +
  `        "card wire v1 refuses an unnegotiated physical connection")\n` +
  `      local projected = room:projectCardWire(self, physical, command, data, batch)\n`;
replaceOnce('lua/server/serverplayer_base.lua', stageBefore, stageAfter,
  'candidate physical dispatch capability gate');

const reconnectBefore = `  if physical:getState() == fk.Player_Robot then return end\n  assert(type(room.beginCardWireBatch) == "function",\n`;
const reconnectAfter = `  if physical:getState() == fk.Player_Robot then return end\n  assert(type(room.hasCardWireCapability) == "function" and\n` +
  `    room:hasCardWireCapability(physical),\n` +
  `    "card wire v1 Reconnect refuses an unnegotiated physical connection")\n` +
  `  assert(type(room.beginCardWireBatch) == "function",\n`;
replaceOnce('lua/server/serverplayer_base.lua', reconnectBefore, reconnectAfter,
  'candidate reconnect capability gate');

// The observer/capability gate is deliberately checked against the installed
// source rather than a loose substring, so future candidate drift fails shut.
const finalRoom = read('lua/server/roombase.lua').source;
const finalPlayer = read('lua/server/serverplayer_base.lua').source;
const finalClient = read('lua/client/clientbase.lua').source;
assert.equal(finalRoom.split('function ServerRoomBase:handleCardWireCapability').length, 2);
assert.equal(finalRoom.split('function ServerRoomBase:hasAllCardWireCapabilities').length, 2);
assert.match(finalRoom, /card wire negotiation requires every physical client capability/u);
assert.match(finalPlayer, /unnegotiated physical connection/u);
assert.equal(finalClient.split('card_wire_negotiation").endMatch(self)').length, 2);
console.log(`PASS isolated Hegemony card-wire capability guard ${mode}: per-match advertise/reset, all-client gate, observer/reconnect fail-closed`);
