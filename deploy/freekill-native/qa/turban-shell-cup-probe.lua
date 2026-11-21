-- Exercise the skill from a promoted release with a concealed client deck and
-- a physical server deck. The host stub rejects any lookup of an anonymous ID.
local root = assert(arg[1], "expected a promoted native release root")
local refs = dofile(root .. "/packages/freekill-core/ltk/client/card_wire_refs.lua").new()
local hidden = refs:mintAnonymous()
local physical = 21
local room = { draw_pile = { hidden }, card_wire_version = 1, card_wire_refs = refs }
local effect
fk = {
  CreateSkill = function(skill)
    skill.addEffect = function(_, kind, callbacks)
      assert(kind == "viewas")
      effect = callbacks
    end
    return skill
  end,
}
Fk = {
  currentRoom = function() return room end,
  cloneCard = function(_, name)
    assert(name == "analeptic")
    return {
      subcards = {},
      addSubcard = function(self, id)
        assert(id == physical, "preview tried resolving a hidden deck slot")
        self.subcards[1] = id
      end,
    }
  end,
}
Player = { HistoryTurn = 1 }
local used = 0
local player = { usedSkillTimes = function() return used end }
dofile(root .. "/packages/hegemony/pkg/nine_variations/skills/turban_shell_cup.lua")

assert(effect.enabled_at_response(nil, player, false))
assert(effect.enabled_at_play(nil, player))
assert(not effect.enabled_at_response(nil, player, true))
local preview = assert(effect.view_as(nil, player, {}))
assert(preview.skillName == "turban_shell_cup" and #preview.subcards == 0)
assert(not effect.view_as(nil, player, { physical }))

room.draw_pile[1] = physical
room.card_wire_refs = nil
assert(effect.view_as(nil, player, {}).subcards[1] == physical, "v1 server must consume the top card")
room.card_wire_version = nil
assert(effect.view_as(nil, player, {}).subcards[1] == physical, "legacy preview must keep its subcard")
used = 9
assert(not effect.enabled_at_play(nil, player))
assert(not effect.enabled_at_response(nil, player, false))
used = 0
room.draw_pile = {}
assert(not effect.enabled_at_play(nil, player))
assert(not effect.enabled_at_response(nil, player, false))
assert(not effect.view_as(nil, player, {}))
print("PASS Anh Vu Boi: v1 preview, physical server and legacy card, response, turn limit, empty deck")
