local feibai = fk.CreateSkill {
  name = "ty__feibai",
}

Fk:loadTranslationTable{
  ["ty__feibai"] = "飞白",
  [":ty__feibai"] = "当你使用牌后，你可以从牌堆或弃牌堆随机两张字数为X的牌中选择一张获得（X为此牌与你本回合使用的上一张牌牌名字数之和，"..
  "若没有上一张牌则上一张字数视为0）。若没有字数为X的牌，你摸两张牌并标记为“弦”，此技能本回合失效。",

  ["$ty__feibai1"] = "顺笔若枯丝平行，转折如青锋突起。",
  ["$ty__feibai2"] = "以帚蘸金，可妆鸿都以飞白。",
}

feibai:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(feibai.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.card:getNameLength()
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
      if e.id < room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true).id then
        local use = e.data
        if use.from == player then
          n = n + use.card:getNameLength()
          return true
        end
      end
    end, nil, Player.HistoryTurn)
    local cards = {}
    for i = #room.draw_pile, 1, -1 do
      local id = room.draw_pile[i]
      if Fk:getCardById(id):getNameLength() == n then
        table.insert(cards, id)
        if #cards > 1 then
          break
        end
      end
    end
    if #cards < 2 then
      local cardsd = {}
      for i = #room.discard_pile, 1, -1 do
        local id = room.discard_pile[i]
        if Fk:getCardById(id):getNameLength() == n then
          table.insert(cardsd, id)
        end
      end
      if #cardsd > 0 then
        table.insertTable(cards, room:tableRandomPick(cardsd, 2 - #cards))
      end
    end
    if #cards > 0 then
      local card = room:askToChooseCard(player, {
        target = player,
        flag = { card_data = {{ "toObtain", room:tableRandomPick(cards, 2) }} },
        skill_name = feibai.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, feibai.name, nil, true, player)
    else
      player:drawCards(2, feibai.name, nil, player:hasSkill("jiaowei", true) and "@@jiaowei-inhand" or nil)
      room:invalidateSkill(player, feibai.name, "-turn")
    end
  end,
})

return feibai
