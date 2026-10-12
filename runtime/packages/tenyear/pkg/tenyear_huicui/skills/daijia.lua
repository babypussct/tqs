local daijia = fk.CreateSkill {
  name = "daijia",
  derived_piles = "daijia_pile",
}

Fk:loadTranslationTable{
  ["daijia"] = "黛颊",
  [":daijia"] = "每轮开始时，你可以随机将牌堆里的体力上限张红色牌置于武将牌上（均称为“黛”），然后回复1点体力；"..
    "当牌使用结算结束后，若目标角色包含你，你随机获得一张“黛”；每轮结束时，你获得所有“黛”。",

  ["daijia_pile"] = "黛",
  ["#daijia-prey"] = "黛颊：获得一种花色的“黛”",

  ["$daijia1"] = "",
  ["$daijia2"] = "",
}

daijia:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(daijia.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.dead then return end
    local cards = room:getCardsFromPileByRule(".|.|red", player.maxHp)
    if #cards > 0 then
      player:addToPile("daijia_pile", cards, true, daijia.name, player)
      if player.dead then return end
    end
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = daijia.name,
    }
  end,
})

daijia:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(daijia.name) and
      table.contains(data.tos, player) and #player:getPile("daijia_pile") > 0
    --实测被【无懈可击】抵消过的锦囊牌不能触发此效果，懒得还原
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(room:tableRandomPick(player:getPile("daijia_pile")), Card.PlayerHand, player,
      fk.ReasonJustMove, daijia.name, nil, false, player)
  end,
})

daijia:addEffect(fk.RoundEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(daijia.name) and #player:getPile("daijia_pile") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("daijia_pile"), Card.PlayerHand, player,
      fk.ReasonJustMove, daijia.name, nil, false, player)
  end,
})

return daijia
