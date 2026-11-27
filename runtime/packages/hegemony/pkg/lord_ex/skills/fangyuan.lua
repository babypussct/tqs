
local fangyuan = fk.CreateSkill {
  name = "ld__fangyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__fangyuan"] = "方圆",
  [":ld__fangyuan"] = "阵法技，若你是围攻角色或被围攻角色，则你对该围攻关系中的其他势力角色造成的伤害+1。",

  ["$ld__fangyuan1"] = "布阵合围，滴水不漏，待敌自溃。",
  ["$ld__fangyuan2"] = "乘敌阵未猛，待我斩将易旗，先奋士气。",
}

local H = require "packages.hegemony.util"

fangyuan:addEffect("arraysummon", {
  array_type = "siege",
})

fangyuan:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(fangyuan.name) and
      H.compareKingdomWith(player, data.to, true) and
      (H.inSiegeRelation(player, player, data.to) or H.inSiegeRelation(data.to, data.to, player))
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return fangyuan
