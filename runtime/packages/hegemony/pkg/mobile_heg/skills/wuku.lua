local wuku = fk.CreateSkill {
  name = "m_heg__wuku",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__wuku"] = "武库",
  [":m_heg__wuku"] = "锁定技，当一名势力与你不同的角色使用装备牌时，你获得1个“武库”标记。（“武库”数量至多为2）",

  ["@m_heg__wuku"] = "武库",

  ["$m_heg__wuku1"] = "损益万枢，竭世运机。",
  ["$m_heg__wuku2"] = "胸藏万卷，充盈如库。",
}

local H = require "packages.hegemony.util"

wuku:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wuku.name) and data.card.type == Card.TypeEquip and
      H.compareKingdomWith(target, player, true) and player:getMark("@m_heg__wuku") < 2
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@m_heg__wuku")
  end,
})

return wuku
