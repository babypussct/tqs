local linzi = fk.CreateSkill {
  name = "peixiu_linzi",
}

Fk:loadTranslationTable {
  ["peixiu_linzi"] = "临淄",
  [":peixiu_linzi"] = "你获得此技能后，获得弃牌堆中三张随机的♣牌。",
}

linzi:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(linzi.name) and data.skill.name == linzi.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|club", 3, "discardPile")
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, linzi.name, nil, false, player)
    end
  end
})

return linzi
