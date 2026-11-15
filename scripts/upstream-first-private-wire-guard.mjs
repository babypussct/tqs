// Explicitly apply the Hegemony wire-privacy guard to an isolated candidate.
// Usage: node scripts/upstream-first-private-wire-guard.mjs --apply <candidate-core-root>
//        node scripts/upstream-first-private-wire-guard.mjs --check <candidate-core-root>
// The integration gate still requires native/browser privacy and reconnect QA.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'usage: --apply|--check <isolated-candidate-core-root>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'write/check is restricted to a scratch evidence candidate core');

const patches = [
  {
    file: 'ltk/server/room.lua',
    before: `function Room:serialize(player)
  local o = ServerRoomBase.serialize(self, player)
  o.round_count = self:getBanner("RoundCount") or 0
  return o
end`,
    after: `function Room:serialize(player, observer)
  -- TQS_HEG_PRIVATE_WIRE: preserve observer status across subclass override.
  local o = ServerRoomBase.serialize(self, player, observer)
  o.round_count = self:getBanner("RoundCount") or 0
  return o
end`,
  },
  {
    file: 'ltk/server/serverplayer.lua',
    before: `function ServerPlayer:syncFakeSkills()
  for _, s in ipairs(self._manually_fake_skills) do
    self:doNotify("AddSkill", { self.id, s.name, true })
    if table.contains(self.prelighted_skills, s) then
      self:doNotify("PrelightSkill", { s.name, true })
    end
  end
end

function ServerPlayer:syncFakeSkillsTo(observer)
  for _, s in ipairs(self._manually_fake_skills) do
    observer:doNotify("AddSkill", cbor.encode { self.id, s.name, true })
    if table.contains(self.prelighted_skills, s) then
      observer:doNotify("PrelightSkill", cbor.encode { s.name, true })
    end
  end
end`,
    after: `-- TQS_HEG_PRIVATE_WIRE: fake/prelighted skills can identify concealed
-- generals. ServerPlayerBase:doNotify forwards to attached spectators, so
-- deliver owner-only skill metadata to the physical seat connection.
-- Keep the default forwarding semantics for other game modes.
function ServerPlayer:notifyConcealedSkillOwner(command, data)
  if self.room:getSettings("gameMode") == "new_heg_mode" then
    local realOwner = self._splayer
    if realOwner and realOwner:getState() ~= fk.Player_Robot then
      realOwner:doNotify(command, cbor.encode(data))
    end
    return
  end
  self:doNotify(command, data)
end

function ServerPlayer:syncFakeSkills()
  for _, s in ipairs(self._manually_fake_skills) do
    self:notifyConcealedSkillOwner("AddSkill", { self.id, s.name, true })
    if table.contains(self.prelighted_skills, s) then
      self:notifyConcealedSkillOwner("PrelightSkill", { s.name, true })
    end
  end
end

function ServerPlayer:syncFakeSkillsTo(observer)
  -- Spectator views never inherit the owner's hidden general skill list.
  if self.room:getSettings("gameMode") == "new_heg_mode" then return end
  for _, s in ipairs(self._manually_fake_skills) do
    observer:doNotify("AddSkill", cbor.encode { self.id, s.name, true })
    if table.contains(self.prelighted_skills, s) then
      observer:doNotify("PrelightSkill", cbor.encode { s.name, true })
    end
  end
end`,
  },
  {
    file: 'ltk/server/serverplayer.lua',
    before: `  -- TODO
  self:doNotify("AddSkill", { self.id, skill.name, true })
  -- A hidden/replaced general can retain a prelighted skill when it becomes
  -- fake again.
  if table.contains(self.prelighted_skills, skill) then
    self:doNotify("PrelightSkill", { skill.name, true })
  end`,
    after: `  -- TQS_HEG_PRIVATE_WIRE: Hegemony fake skills belong to this seat only.
  self:notifyConcealedSkillOwner("AddSkill", { self.id, skill.name, true })
  -- A hidden/replaced general can retain a prelighted skill when it becomes
  -- fake again.
  if table.contains(self.prelighted_skills, skill) then
    self:notifyConcealedSkillOwner("PrelightSkill", { skill.name, true })
  end`,
  },
  {
    file: 'ltk/server/serverplayer.lua',
    before: `  -- TODO
  self:doNotify("LoseSkill", { self.id, skill.name, true })`,
    after: `  -- TQS_HEG_PRIVATE_WIRE: do not reveal a hidden skill through observers.
  self:notifyConcealedSkillOwner("LoseSkill", { self.id, skill.name, true })`,
  },
  {
    file: 'ltk/server/serverplayer.lua',
    before: `  self:doNotify("PrelightSkill", { skill.name, isPrelight })`,
    after: `  self:notifyConcealedSkillOwner("PrelightSkill", { skill.name, isPrelight }) -- TQS_HEG_PRIVATE_WIRE`,
  },
  {
    file: 'ltk/server/room.lua',
    before: `  self:notifyProperty(player, player, "general")
  self:broadcastProperty(player, "gender")

  if changeKingdom then`,
    after: `  self:notifyProperty(player, player, "general")
  -- TQS_HEG_PRIVATE_WIRE: the caller may be installing a concealed general.
  -- Respect noBroadcast for gender as already done for kingdom below.
  if noBroadcast then
    self:notifyProperty(player, player, "gender")
  else
    self:broadcastProperty(player, "gender")
  end

  if changeKingdom then`,
  },
  {
    file: '../hegemony/pkg/gamemodes/new_hegemony_mode.lua',
    before: '    room:setPlayerGeneral(player, general, true)\n    room:setDeputyGeneral(player, deputy)',
    after: '    room:setPlayerGeneral(player, general, true, true) -- TQS_HEG_PRIVATE_WIRE: real identity owner-only\n    room:setDeputyGeneral(player, deputy)',
  },
  {
    file: 'lua/server/roombase.lua',
    before: `function ServerRoomBase:notifyProperty(p, player, property)
  p:doNotify("PropertyUpdate", {
    player.id,
    property,
    player[property],
  })
end`,
    legacy: {
      before: `function ServerRoomBase:notifyProperty(p, player, property)
  if self:getSettings("gameMode") == "new_heg_mode" then
    -- TQS_HEG_PRIVATE_WIRE: role contains server-side faction even when
    -- role_shown is set. Hegemony's setPrivateRole sends it to its owner.
    -- All other clients and observers receive only the public role token.
    if property == "role" and not self.game_finished then
      if p == player then
        local realOwner = p._splayer
        if realOwner and realOwner:getState() ~= fk.Player_Robot then
          self:notifyPrivatePhysical(p, realOwner, "PropertyUpdate", { player.id, property, player.role })
        end
      else
        p:doNotify("PropertyUpdate", { player.id, property, "hidden" })
      end
      return
    end
    -- A concealed pair must never use the normal seat notification path:
    -- ServerPlayerBase:doNotify also forwards to attached spectators. The
    -- owner gets the real metadata; every other recipient gets the same
    -- public placeholder used by reconnect snapshots.
    if not player.role_shown and
        (property == "general" or property == "deputyGeneral"
          or property == "kingdom" or property == "gender") then
      if p == player then
        local realOwner = p._splayer
        if realOwner and realOwner:getState() ~= fk.Player_Robot then
          self:notifyPrivatePhysical(p, realOwner, "PropertyUpdate", { player.id, property, player[property] })
        end
      else
        local publicValue = player[property]
        if property == "general" or property == "deputyGeneral" then
          publicValue = "anjiang"
        elseif property == "kingdom" then
          publicValue = "unknown"
        elseif property == "gender" then
          publicValue = Fk.generals.anjiang.gender
        end
        p:doNotify("PropertyUpdate", { player.id, property, publicValue })
      end
      return
    end
  end
  p:doNotify("PropertyUpdate", {
    player.id,
    property,
    player[property],
  })
end`,
    },
    after: `function ServerRoomBase:notifyProperty(p, player, property)
  if self:getSettings("gameMode") == "new_heg_mode" then
    -- TQS_HEG_PRIVATE_WIRE: role contains server-side faction even when
    -- role_shown is set. Hegemony's setPrivateRole sends it to its owner.
    -- All other clients and observers receive only the public role token.
    if property == "role" and not self.game_finished then
      if p == player then
        local realOwner = p._splayer
        if realOwner and realOwner:getState() ~= fk.Player_Robot then
          realOwner:doNotify("PropertyUpdate", cbor.encode({ player.id, property, player.role }))
        end
      else
        p:doNotify("PropertyUpdate", { player.id, property, "hidden" })
      end
      return
    end
    -- A concealed pair must never use the normal seat notification path:
    -- ServerPlayerBase:doNotify also forwards to attached spectators. The
    -- owner gets the real metadata; every other recipient gets the same
    -- public placeholder used by reconnect snapshots.
    local concealed = not player.role_shown and
      (property == "general" or property == "deputyGeneral"
        or property == "kingdom" or property == "gender")
    if concealed then
      local privateValue =
        (property == "general" and player.general ~= "anjiang")
          or (property == "deputyGeneral" and player.deputyGeneral ~= "anjiang")
          or (property == "kingdom" and player.kingdom ~= "unknown")
          or (property == "gender" and player.gender ~= Fk.generals.anjiang.gender)
      if p == player and privateValue then
        local realOwner = p._splayer
        if realOwner and realOwner:getState() ~= fk.Player_Robot then
          realOwner:doNotify("PropertyUpdate", cbor.encode({ player.id, property, player[property] }))
        end
        return
      elseif p ~= player then
        local publicValue = player[property]
        if property == "general" or property == "deputyGeneral" then
          publicValue = "anjiang"
        elseif property == "kingdom" then
          publicValue = "unknown"
        elseif property == "gender" then
          publicValue = Fk.generals.anjiang.gender
        end
        p:doNotify("PropertyUpdate", { player.id, property, publicValue })
        return
      end
    end
  end
  p:doNotify("PropertyUpdate", {
    player.id,
    property,
    player[property],
  })
end`,
  },
  {
    file: 'lua/server/roombase.lua',
    before: `function ServerRoomBase:setPlayerMark(player, mark, value)
  player:setMark(mark, value)
  self:doBroadcastNotify("SetPlayerMark", {
    player.id,
    mark,
    value
  })
end`,
    after: `function ServerRoomBase:setPlayerMark(player, mark, value)
  player:setMark(mark, value)
  -- TQS_HEG_PRIVATE_WIRE: keep concealed general/kingdom metadata owner-only.
  -- ServerPlayerBase:doNotify also forwards to spectators: use the real seat
  -- connection directly, retaining the native CBOR wire framing.
  if self:getSettings("gameMode") == "new_heg_mode"
      and (mark:sub(1, 6) == "__heg_" or mark == "InitialGeneral"
        or mark == "ExtraAttachedSkills"
        or mark == "HalfMaxHpLeft" or mark == "CompanionEffect") then
    local realOwner = player._splayer
    if realOwner and realOwner:getState() ~= fk.Player_Robot then
      realOwner:doNotify("SetPlayerMark", cbor.encode({ player.id, mark, value }))
    end
    return
  end
  self:doBroadcastNotify("SetPlayerMark", {
    player.id,
    mark,
    value
  })
end`,
  },
  {
    file: 'lua/server/roombase.lua',
    before: 'local summary = self:serialize(observee)',
    after: 'local summary = self:serialize(observee, true) -- TQS_HEG_PRIVATE_WIRE: observer is not the owner',
  },
  {
    file: 'lua/server/roombase.lua',
    before: `function ServerRoomBase:serialize(player)
  local klass = self.class.super --[[@as Base.RoomBase]]
  local o = klass.serialize(self)
  -- 同步对局时长，避免双端时钟差异
  o.played_time = self.start_time and math.max(0, os.time() - self.start_time) or 0
  if player then
    o.you = player.id
  end
  return o
end`,
    legacy: [
      {
        before: `        record.mark = cbor.encode(projectedMarks)
        -- The real faction role is server state even when a general is shown.
        -- It must not enter another seat's reconnect or observer snapshot.
        if not self.game_finished then record.properties.role = "hidden" end
        record.fake_skills = {}`,
        after: `        record.mark = cbor.encode(projectedMarks)
        -- Hegemony can retain the real role during public general display.
        -- A late observer can also arrive while a concealed pair is being set.
        if not self.game_finished then
          record.properties.role = "hidden"
          if not record.properties.role_shown then
            record.properties.general = "anjiang"
            record.properties.deputyGeneral = "anjiang"
            record.properties.gender = Fk.generals.anjiang.gender
            record.properties.kingdom = Fk.generals.anjiang.kingdom
          end
        end
        record.fake_skills = {}`,
      },
      {
        before: `        record.mark = cbor.encode(projectedMarks)
        record.fake_skills = {}`,
        after: `        record.mark = cbor.encode(projectedMarks)
        -- Hegemony can retain the real role during public general display.
        -- A late observer can also arrive while a concealed pair is being set.
        if not self.game_finished then
          record.properties.role = "hidden"
          if not record.properties.role_shown then
            record.properties.general = "anjiang"
            record.properties.deputyGeneral = "anjiang"
            record.properties.gender = Fk.generals.anjiang.gender
            record.properties.kingdom = Fk.generals.anjiang.kingdom
          end
        end
        record.fake_skills = {}`,
      },
    ],
    after: `function ServerRoomBase:serialize(player, observer)
  local klass = self.class.super --[[@as Base.RoomBase]]
  local o = klass.serialize(self)
  -- TQS_HEG_PRIVATE_WIRE: project mark/hidden-skill snapshots per audience.
  -- Keep the real mark table on the server; never mutate source player state.
  -- Observer still needs 'you' for client setup but cannot access its secrets.
  if self:getSettings("gameMode") == "new_heg_mode" then
    for _, seat in ipairs(self.players) do
      if observer or not player or seat.id ~= player.id then
        local record = o.players[seat.id]
        local projectedMarks = cbor.decode(record.mark)
        for mark in pairs(projectedMarks) do
          if type(mark) == "string" and
              (mark:sub(1, 6) == "__heg_" or mark == "InitialGeneral"
                or mark == "ExtraAttachedSkills"
                or mark == "HalfMaxHpLeft" or mark == "CompanionEffect") then
            projectedMarks[mark] = nil
          end
        end
        record.mark = cbor.encode(projectedMarks)
        -- Hegemony can retain the real role during public general display.
        -- A late observer can also arrive while a concealed pair is being set.
        if not self.game_finished then
          record.properties.role = "hidden"
          if not record.properties.role_shown then
            record.properties.general = "anjiang"
            record.properties.deputyGeneral = "anjiang"
            record.properties.gender = Fk.generals.anjiang.gender
            record.properties.kingdom = Fk.generals.anjiang.kingdom
          end
        end
        record.fake_skills = {}
        record.prelighted_skills = {}
      end
    end
  end
  -- 同步对局时长，避免双端时钟差异
  o.played_time = self.start_time and math.max(0, os.time() - self.start_time) or 0
  if player then
    o.you = player.id
  end
  return o
end`,
  },
  // Hegemony's yin-yang/companion flags depend on unrevealed pairs and can
  // narrow down their identity before reveal. Route every writer through the
  // canonical mark guard and omit the flags from other-seat snapshots.
  {
    file: '../hegemony/pkg/gamemodes/new_hegemony_mode.lua',
    before: `      p:setMark("HalfMaxHpLeft", 1)
      p:doNotify("SetPlayerMark", { p.id, "HalfMaxHpLeft", 1})`,
    after: `      room:setPlayerMark(p, "HalfMaxHpLeft", 1) -- TQS_HEG_PRIVATE_WIRE`,
  },
  {
    file: '../hegemony/pkg/gamemodes/new_hegemony_mode.lua',
    before: `      p:setMark("CompanionEffect", 1)
      p:doNotify("SetPlayerMark", { p.id, "CompanionEffect", 1})`,
    after: `      room:setPlayerMark(p, "CompanionEffect", 1) -- TQS_HEG_PRIVATE_WIRE`,
  },
  {
    file: '../hegemony/util.lua',
    before: `        player:setMark("HalfMaxHpLeft", 1)
        player:doNotify("SetPlayerMark", { player.id, "HalfMaxHpLeft", 1})`,
    after: `        room:setPlayerMark(player, "HalfMaxHpLeft", 1) -- TQS_HEG_PRIVATE_WIRE`,
  },
  {
    file: '../hegemony/util.lua',
    before: `        player:setMark("HalfMaxHpLeft", 0)
        player:doNotify("SetPlayerMark", { player.id, "HalfMaxHpLeft", 0})`,
    after: `        room:setPlayerMark(player, "HalfMaxHpLeft", 0) -- TQS_HEG_PRIVATE_WIRE`,
  },
  {
    file: '../hegemony/util.lua',
    before: `      player:setMark("CompanionEffect", 1)
      player:doNotify("SetPlayerMark", { player.id, "CompanionEffect", 1})`,
    after: `      room:setPlayerMark(player, "CompanionEffect", 1) -- TQS_HEG_PRIVATE_WIRE`,
  },
  {
    file: '../hegemony/util.lua',
    before: `    p:setMark("HalfMaxHpLeft", 1)
    p:doNotify("SetPlayerMark", { p.id, "HalfMaxHpLeft", 1})`,
    after: `    room:setPlayerMark(p, "HalfMaxHpLeft", 1) -- TQS_HEG_PRIVATE_WIRE`,
  },
  {
    file: '../hegemony/util.lua',
    before: `    p:setMark("CompanionEffect", 1)
    p:doNotify("SetPlayerMark", { p.id, "CompanionEffect", 1})`,
    after: `    room:setPlayerMark(p, "CompanionEffect", 1) -- TQS_HEG_PRIVATE_WIRE`,
  },
  {
    file: '../hegemony/utilevent/events/remove_general.lua',
    before: `  player:setMark("CompanionEffect", 0)
  player:setMark("HalfMaxHpLeft", 0)
  player:doNotify("SetPlayerMark", { player.id, "CompanionEffect", 0})
  player:doNotify("SetPlayerMark", { player.id, "HalfMaxHpLeft", 0})`,
    after: `  room:setPlayerMark(player, "CompanionEffect", 0) -- TQS_HEG_PRIVATE_WIRE
  room:setPlayerMark(player, "HalfMaxHpLeft", 0) -- TQS_HEG_PRIVATE_WIRE`,
  },
];

// The separate candidate-only card mark guard inserts this exact snapshot
// projection immediately before the existing private-wire player projection.
// Accept the combined state in --check while still requiring every original
// private-wire hunk byte-for-byte. Do not silently accept arbitrary drift.
const cardMarkSnapshotProjection = `  -- TQS_HEG_CARD_MARK_WIRE: card marks can identify a hand/deck card even
  -- when the move log or UI only displays its back. Project a snapshot
  -- copy per physical recipient, never change the server card manager.
  if self:getSettings("gameMode") == "new_heg_mode"
      and o.card_manager and o.card_manager.card_marks then
    local projected = cbor.decode(o.card_manager.card_marks)
    for id in pairs(projected) do
      local area = self:getCardArea(id)
      local owner = self:getCardOwner(id)
      local pileName = area == Card.PlayerSpecial and owner and owner:getPileNameOfId(id)
      local privatePile = type(pileName) == "string" and pileName:sub(1, 1) == "$"
      if area == Card.DrawPile or
          ((area == Card.PlayerHand or privatePile) and
            (observer or not player or not owner or owner.id ~= player.id)) then
        projected[id] = nil
      end
    end
    o.card_manager.card_marks = next(projected) and cbor.encode(projected) or nil
  end
`;

// A subsequent candidate-only guard routes owner-exclusive updates through
// the physical-socket projector. Compare the original private-wire hunks
// against an in-memory canonical view; never revert the applied callsites.
const privatePhysicalCallsites = [
  [
    'self:notifyPrivatePhysical(p, realOwner, "PropertyUpdate", { player.id, property, player.role })',
    'realOwner:doNotify("PropertyUpdate", cbor.encode({ player.id, property, player.role }))',
  ],
  [
    'self:notifyPrivatePhysical(p, realOwner, "PropertyUpdate", { player.id, property, player[property] })',
    'realOwner:doNotify("PropertyUpdate", cbor.encode({ player.id, property, player[property] }))',
  ],
  [
    'self:notifyPrivatePhysical(player, realOwner, "SetPlayerMark", { player.id, mark, value })',
    'realOwner:doNotify("SetPlayerMark", cbor.encode({ player.id, mark, value }))',
  ],
];

const grouped = new Map();
const packageRoot = path.dirname(root);
for (const { file, before, after, legacy } of patches) {
  const target = path.resolve(root, file);
  const relative = path.relative(packageRoot, target);
  assert.ok(relative.startsWith(`freekill-core${path.sep}`)
    || relative.startsWith(`hegemony${path.sep}`), 'patch escapes isolated candidate packages');
  assert.equal(fs.realpathSync(target), target, 'refuse symlink outside isolated candidate');
  const data = grouped.get(target) ?? fs.readFileSync(target, 'utf8');
  let canonicalCheck = data;
  if (file === 'lua/server/roombase.lua' &&
      data.includes('TQS_HEG_CARD_WIRE_PRIVATE_PHYSICAL')) {
    for (const [projected, original] of privatePhysicalCallsites) {
      if (canonicalCheck.includes(projected)) {
        assert.equal(canonicalCheck.split(projected).length, 2,
          `owner-only physical callsite drift: ${projected}`);
        canonicalCheck = canonicalCheck.replace(projected, original);
      } else {
        assert.equal(canonicalCheck.split(original).length, 2,
          `owner-only canonical callsite drift: ${original}`);
      }
    }
  }
  const combinedCardMark = file === 'lua/server/roombase.lua'
    && after.startsWith('function ServerRoomBase:serialize(player, observer)')
    && canonicalCheck.split(cardMarkSnapshotProjection).length === 2
    && canonicalCheck.replace(cardMarkSnapshotProjection, '').includes(after);
  if (canonicalCheck.includes(after) || combinedCardMark) {
    grouped.set(target, data);
    continue;
  }
  const alternatives = Array.isArray(legacy) ? legacy : legacy ? [legacy] : [];
  const migration = alternatives.find((item) => data.includes(item.before));
  const from = data.includes(before) ? before : migration?.before;
  const to = from === before ? after : (migration?.after ?? after);
  assert.ok(from && to && data.includes(from), `candidate source differs at ${file}; stop for manual review`);
  assert.equal(data.split(from).length, 2, `nonunique target in ${file}`);
  assert.equal(mode, '--apply', `privacy guard missing from ${file}`);
  grouped.set(target, data.replace(from, to));
}
if (mode === '--apply') {
  for (const [file, data] of grouped) {
    fs.writeFileSync(file, data);
  }
}
console.log(`PASS isolated Hegemony private wire guard ${mode}: ${patches.length} source hunks`);
