local zhangming = fk.CreateSkill {
  name = "zhangming",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhangming"] = "彰名",
  [":zhangming"] = "锁定技，你使用♣牌不能被响应。每回合限一次，你对其他角色造成伤害后，其随机弃置一张手牌，然后你从牌堆或弃牌堆中获得"..
  "与其弃置牌类型不同的牌各一张（若其无法弃置手牌，改为你从牌堆或弃牌堆获得所有类型牌各一张），以此法获得的牌不计入本回合手牌上限。",

  ["@@zhangming-inhand-turn"] = "彰名",

  ["$zhangming1"] = "心怀远志，何愁声名不彰！",
  ["$zhangming2"] = "从今始学，成为有用之才！",
}

zhangming:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhangming.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and data.card.suit == Card.Club
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})
zhangming:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhangming.name) and
      player:usedEffectTimes(self.name) == 0 and player ~= data.to and not data.to.dead and
      not (data.extra_data or {}).zhangmingInvalidate
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    if not data.to.dead then
      local cards = table.filter(data.to:getCardIds("h"), function (id)
        return not data.to:prohibitDiscard(id)
      end)
      if #cards > 0 then
        local id = room:tableRandomPick(cards)
        table.removeOne(types, Fk:getCardById(id):getTypeString())
        room:throwCard(id, zhangming.name, data.to, data.to)
      end
    end
    local toObtain = {}
    for _, type_name in ipairs(types) do
      local randomCard = room:getCardsFromPileByRule(".|.|.|.|.|" .. type_name)
      if #randomCard == 0 then
        randomCard = room:getCardsFromPileByRule(".|.|.|.|.|" .. type_name, 1, "discardPile")
      end
      if #randomCard > 0 then
        table.insert(toObtain, randomCard[1])
      end
    end
    if #toObtain > 0 then
      room:moveCardTo(toObtain, Card.PlayerHand, player, fk.ReasonPrey, zhangming.name, nil, false, player, "@@zhangming-inhand-turn")
    end
  end,
})
zhangming:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@zhangming-inhand-turn") > 0
  end,
})

return zhangming
