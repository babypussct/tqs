local guixiu = fk.CreateSkill {
  name = "nos__guixiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["nos__guixiu"] = "闺秀",
  [":nos__guixiu"] = "锁定技，当你受到伤害后，你将武将牌翻至正面朝上；当你的武将牌翻至正面朝上后，你摸一张牌。",

  ["$nos__guixiu1"] = "坐秀闺中，亦明正理。",
  ["$nos__guixiu2"] = "夜依闺楼月，复影自相怜。",
}

guixiu:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guixiu.name) and not player.faceup
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,
})

guixiu:addEffect(fk.TurnedOver, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guixiu.name) and player.faceup
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, guixiu.name)
  end,
})

return guixiu
