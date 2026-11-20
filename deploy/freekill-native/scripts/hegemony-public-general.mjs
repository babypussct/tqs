import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const roomFile = 'lua/server/roombase.lua';
const playerFile = 'ltk/server/serverplayer.lua';
const edits = [
  {
    file: roomFile,
    before: 'function ServerRoomBase:notifyProperty(p, player, property)',
    after: `function ServerRoomBase:publicHegemonyRole(role, shown)
  if shown and type(role) == "string" and role:sub(1, 4) == "heg_" and
      table.contains(require("packages.hegemony.util").wildKingdoms, role) then
    return role
  end
  return "hidden"
end

function ServerRoomBase:notifyProperty(p, player, property)`,
  },
  {
    file: roomFile,
    before: '    if property == "role" and not self.game_finished then',
    after: `    if property == "role" and not self.game_finished and
        self:publicHegemonyRole(player.role, player.role_shown) == "hidden" then`,
  },
  {
    file: roomFile,
    before: '          record.properties.role = "hidden"\n          if not record.properties.role_shown then',
    after: `          record.properties.role = self:publicHegemonyRole(record.properties.role, record.properties.role_shown)
          if not record.properties.role_shown then`,
  },
  {
    file: roomFile,
    before: 'function ServerRoomBase:setPlayerProperty(player, property, value)\n  player[property] = value',
    after: `function ServerRoomBase:setPlayerProperty(player, property, value)
  local publicGenerals = player._tqs_public_generals
  if publicGenerals and publicGenerals[property] and publicGenerals[property] ~= value then
    publicGenerals[property] = nil
  end
  player[property] = value`,
  },
  {
    file: roomFile,
    before: '    if concealed then\n      local privateValue =',
    after: `    local publicGenerals = player._tqs_public_generals
    local published = publicGenerals and publicGenerals[property]
    if concealed and (not published or published ~= player[property]) then
      local privateValue =`,
  },
  {
    file: roomFile,
    before: `  player[property] = value
  self:broadcastProperty(player, property)
end`,
    after: `  player[property] = value
  self:broadcastProperty(player, property)
  if property == "role_shown" and value == true and publicGenerals and
      self:getSettings("gameMode") == "new_heg_mode" and
      ((publicGenerals.general and publicGenerals.general == player.general) or
        (publicGenerals.deputyGeneral and publicGenerals.deputyGeneral == player.deputyGeneral)) then
    -- revealGeneral broadcasts kingdom before the faction is public.
    self:broadcastProperty(player, "kingdom")
  end
end`,
  },
  {
    file: roomFile,
    before: `            record.properties.general = "anjiang"
            record.properties.deputyGeneral = "anjiang"
            record.properties.gender = Fk.generals.anjiang.gender`,
    after: `            local publicGenerals = seat._tqs_public_generals
            if not publicGenerals or publicGenerals.general ~= record.properties.general then
              record.properties.general = "anjiang"
            end
            if not publicGenerals or publicGenerals.deputyGeneral ~= record.properties.deputyGeneral then
              record.properties.deputyGeneral = "anjiang"
            end
            record.properties.gender = Fk.generals.anjiang.gender`,
  },
  {
    file: playerFile,
    before: '  room:changeHero(self, generalName, false, isDeputy, false, false, false)\n  if #tolose > 0 then',
    after: `  room:changeHero(self, generalName, false, isDeputy, false, false, false)
  -- The first reveal can precede faction disclosure. Publish just the slot
  -- that the reveal actually changed, without exposing the other slot.
  local property = isDeputy and "deputyGeneral" or "general"
  if room:getSettings("gameMode") == "new_heg_mode" and self[property] == generalName then
    self._tqs_public_generals = self._tqs_public_generals or {}
    self._tqs_public_generals[property] = generalName
    if not self.role_shown then room:broadcastProperty(self, property) end
  end
  if #tolose > 0 then`,
  },
  {
    file: playerFile,
    before: 'function ServerPlayer:hideGeneral(isDeputy)\n  local room = self.room',
    after: `function ServerPlayer:hideGeneral(isDeputy)
  if self._tqs_public_generals then
    self._tqs_public_generals[isDeputy and "deputyGeneral" or "general"] = nil
  end
  local room = self.room`,
  },
];

// Keep the earlier privacy guard able to check its own exact hunks.
export function withoutPublicGeneralEdits(file, source) {
  for (const edit of edits.toReversed()) {
    if (edit.file === file) source = source.replace(edit.after, edit.before);
  }
  return source;
}

export function updatePublicGeneralSource(core, mode) {
  const files = new Map();
  for (const {file, before, after} of edits) {
    const target = path.join(core, file);
    assert.equal(fs.realpathSync(target), target, `Refusing symlink: ${target}`);
    const source = files.get(target) ?? fs.readFileSync(target, 'utf8');
    if (source.split(after).length === 2) continue;
    assert.equal(mode, '--apply', `Public general edit missing in ${file}`);
    assert.equal(source.split(before).length, 2, `Public general source drift in ${file}`);
    files.set(target, source.replace(before, after));
  }
  for (const [target, source] of files) fs.writeFileSync(target, source);
}
