
local tianfu = fk.CreateSkill{
  name = "tianfu",
  tags = { Skill.MainPlace, Skill.Compulsory },
  related_skills = { "ld__kanpo" },
}

Fk:loadTranslationTable{
  ["tianfu"] = "天覆",
  [":tianfu"] = "主将技，阵法技，若当前回合角色与你处于同一<a href='heg_formation_href'>队列</a>，你拥有技能〖看破〗。",
}

local H = require "packages.hegemony.util"

tianfu:addEffect("arraysummon", {
  array_type = "formation",
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return player:hasShownSkill(tianfu.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local ret = H.inFormationRelation(room.current, player) and player:hasSkill(tianfu.name)
    room:handleAddLoseSkills(player, ret and "ld__kanpo" or "-ld__kanpo", nil, false, true)
  end,
}

tianfu:addEffect(fk.TurnStart, spec)
tianfu:addEffect(fk.GeneralRevealed, spec)
tianfu:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return data.skill.name == tianfu.name
  end,
  on_refresh = spec.on_refresh,
})
tianfu:addEffect(fk.GeneralHidden, {
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = spec.on_refresh,
})
tianfu:addEffect(fk.EventAcquireSkill, spec)
tianfu:addEffect(H.PlayerRemoved, spec)

return tianfu
