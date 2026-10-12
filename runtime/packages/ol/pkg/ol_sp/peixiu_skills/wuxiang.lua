local wuxiang = fk.CreateSkill {
  name = "peixiu_wuxiang",
}

Fk:loadTranslationTable {
  ["peixiu_wuxiang"] = "武乡",
  [":peixiu_wuxiang"] = "你获得此技能后，从牌堆中获得一张【火攻】。",
}

wuxiang:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(wuxiang.name) and data.skill.name == wuxiang.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("fire_attack")
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, wuxiang.name, nil, false, player)
  end
})

return wuxiang
