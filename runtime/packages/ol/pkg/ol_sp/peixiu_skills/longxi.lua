local longxi = fk.CreateSkill {
  name = "peixiu_longxi",
}

Fk:loadTranslationTable {
  ["peixiu_longxi"] = "陇西",
  [":peixiu_longxi"] = "你获得此技能后，从牌堆中获得一张防御坐骑牌。",
}

longxi:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(longxi.name) and data.skill.name == longxi.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(room.draw_pile, function (id)
      return Fk:getCardById(id).sub_type == Card.SubtypeDefensiveRide
    end)
    if #cards > 0 then
      room:moveCardTo(room:tableRandomPick(cards), Card.PlayerHand, player, fk.ReasonJustMove, longxi.name, nil, false, player)
    end
  end
})

return longxi
