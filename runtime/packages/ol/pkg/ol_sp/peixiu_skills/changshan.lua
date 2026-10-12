local changshan = fk.CreateSkill {
  name = "peixiu_changshan",
}

Fk:loadTranslationTable {
  ["peixiu_changshan"] = "常山",
  [":peixiu_changshan"] = "你从牌堆中获得两张【闪】。",
}

changshan:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(changshan.name) and data.skill.name == changshan.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("jink", 2)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, changshan.name, nil, false, player)
    end
  end
})

return changshan
