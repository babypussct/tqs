local shuchen = fk.CreateSkill {
  name = "shuchen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shuchen"] = "疏陈",
  [":shuchen"] = "锁定技，当一名角色进入濒死状态时，若“仁”牌数至少为4，你获得所有“仁”牌，然后令其回复1点体力。",

  ["$shuchen1"] = "陛下应先留心于治道，以征伐为后事也。",
  ["$shuchen2"] = "陛下若修文德，察民疾苦，则天下幸甚。",
}

local U = require "packages.utility.utility"

shuchen:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shuchen.name) and #U.GetRenPile(player.room) > 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, {target})
    room:moveCardTo(U.GetRenPile(room), Card.PlayerHand, player, fk.ReasonJustMove, shuchen.name, nil, true, player)
    if target:isWounded() and not target.dead then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = shuchen.name,
      }
    end
  end,
})

return shuchen
