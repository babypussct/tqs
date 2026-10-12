
local heyi = fk.CreateSkill{
  name = "nos_heg__heyi",
  tags = { Skill.Compulsory },
  related_skills = { "feiying" },
}

Fk:loadTranslationTable{
  ["nos_heg__heyi"] = "鹤翼",
  [":nos_heg__heyi"] = "阵法技，与你处于同一<a href='heg_formation_href'>队列</a>的其他角色视为拥有〖飞影〗。",
}

local H = require "packages.hegemony.util"

heyi:addEffect("arraysummon", {
  array_type = "formation",
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return player:hasShownSkill(heyi.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      local ret = player:hasSkill(heyi.name) and H.inFormationRelation(p, player) and p ~= player
      room:handleAddLoseSkills(p, ret and "feiying" or "-feiying", nil, false, true)
    end
  end,
}

heyi:addEffect(fk.TurnStart, spec)
heyi:addEffect(fk.GeneralRevealed, spec)
heyi:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return data.skill.name == heyi.name
  end,
  on_refresh = spec.on_refresh,
})
heyi:addEffect(fk.GeneralHidden, {
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = spec.on_refresh,
})
heyi:addEffect(fk.EventAcquireSkill, spec)
heyi:addEffect(H.PlayerRemoved, spec)

return heyi
