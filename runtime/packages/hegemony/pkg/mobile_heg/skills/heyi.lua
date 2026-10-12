
local heyi = fk.CreateSkill{
  name = "m_heg__heyi",
  tags = { Skill.Compulsory },
  related_skills = { "feiying" },
}

Fk:loadTranslationTable{
  ["m_heg__heyi"] = "鹤翼",
  [":m_heg__heyi"] = "<a href='m_heg_summon'>阵法技</a>，锁定技，你视为拥有〖飞影〗；"..
  "你处于队列时，改为与你处于同一队列的其他角色视为拥有〖飞影〗。",
}

local H = require "packages.hegemony.util"

local spec = {
  can_refresh = function(self, event, target, player, data)
    return player:hasShownSkill(heyi.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      local ret = player:hasSkill(heyi.name) and H.inFormationRelation(p, player)
      if p == player then
        room:handleAddLoseSkills(player, ret and "-feiying" or "feiying", nil, false, true)
      else
        room:handleAddLoseSkills(p, ret and "feiying" or "-feiying", nil, false, true)
      end
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
