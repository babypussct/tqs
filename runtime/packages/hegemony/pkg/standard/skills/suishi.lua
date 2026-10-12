
local suishi = fk.CreateSkill{
  name = "suishi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["suishi"] = "随势",
  [":suishi"] = "锁定技，当其他角色因受到伤害而进入濒死状态时，若来源与你势力相同，你摸一张牌；当其他角色死亡时，若其与你势力相同，你失去1点体力。",

  ["$suishi1"] = "一荣俱荣！",
  ["$suishi2"] = "一损俱损……",
}

local H = require "packages.hegemony.util"

suishi:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(suishi.name) and target ~= player and
      data.killer and H.compareKingdomWith(data.killer, player)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, suishi.name)
  end,
})
suishi:addEffect(fk.Death, {
  anim_type = "negative",
  audio_index = 2,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(suishi.name) and target ~= player and
      H.compareKingdomWith(target, player)
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, suishi.name)
  end
})

return suishi
