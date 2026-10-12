local fufeng = fk.CreateSkill {
  name = "peixiu_fufeng",
}

Fk:loadTranslationTable {
  ["peixiu_fufeng"] = "扶风",
  [":peixiu_fufeng"] = "你获得此技能后，从牌堆获得一张你手牌中未拥有类型的牌。",
}

fufeng:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fufeng.name) and data.skill.name == fufeng.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local types = { "basic", "trick", "equip" }
    for _, id in ipairs(player:getCardIds("h")) do
      table.removeOne(types, Fk:getCardById(id):getTypeString())
    end
    if #types == 0 then return end
    local card = room:getCardsFromPileByRule(".|.|.|.|.|"..table.concat(types, ","))
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, fufeng.name, nil, false, player)
    end
  end
})

return fufeng
