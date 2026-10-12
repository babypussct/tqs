local lean = fk.CreateSkill {
  name = "peixiu_lean",
}

Fk:loadTranslationTable {
  ["peixiu_lean"] = "乐安",
  [":peixiu_lean"] = "你获得此技能后，从牌堆获得一张属性【杀】和一张【铁索连环】。",
}

lean:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(lean.name) and data.skill.name == lean.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("slash|.|.|.|^slash")
    table.insertTable(cards, room:getCardsFromPileByRule("iron_chain"))
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, lean.name, nil, false, player)
    end
  end
})

return lean
