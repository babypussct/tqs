local jizhou = fk.CreateSkill {
  name = "peixiu_jizhou",
}

Fk:loadTranslationTable {
  ["peixiu_jizhou"] = "冀州",
  [":peixiu_jizhou"] = "你获得此技能后，从牌堆获得一张【万箭齐发】。",
}

jizhou:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jizhou.name) and data.skill.name == jizhou.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("archery_attack")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, jizhou.name, nil, false, player)
    end
  end
})

return jizhou
