local wuku = fk.CreateSkill {
  name = "wuku",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["wuku"] = "武库",
  [":wuku"] = "锁定技，当一名角色使用装备时，你获得1个“武库”标记。（“武库”数量至多为3）",

  ["@wuku"] = "武库",

  ["$wuku1"] = "损益万枢，竭世运机。",
  ["$wuku2"] = "胸藏万卷，充盈如库。",
}

wuku:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wuku.name) and data.card.type == Card.TypeEquip and player:getMark("@wuku") < 3
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@wuku")
  end,
})

return wuku
