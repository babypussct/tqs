local diou = fk.CreateSkill {
  name = "diou",
}

Fk:loadTranslationTable{
  ["diou"] = "低讴",
  [":diou"] = "当你使用“檀板”牌结算结束后，你可以展示一张不为“檀板”牌的手牌，若展示了基本牌或普通锦囊牌，你视为使用展示牌。"..
  "若为你本回合第一次展示此牌或与使用的“檀板”牌牌名相同，你摸两张牌。",

  ["#diou-invoke"] = "低讴：你可以展示一张非“檀板”牌，视为使用之。初次展示此牌则摸两张牌",
  ["@@diou_showed"] = "已展示",

  ["$diou1"] = "一日不见兮，思之如狂。",
  ["$diou2"] = "有一美人兮，见之不忘。",
}

diou:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(diou.name) and
      not player:isKongcheng() and not data.card:isVirtual() and data:hasMark("@@tanban-inhand")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids, record = {}, player:getTableMark("diou-turn")
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      --实测不能展示不能使用的卡牌
      if card:getMark("@@tanban-inhand") == 0 and not player:prohibitUse(card) then
        table.insert(ids, id)
        if table.contains(record, id) then
          room:setCardMark(Fk:getCardById(id), "@@diou_showed", 1)
        end
      end
    end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#diou-invoke",
      skill_name = diou.name,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
    end
    for _, id in ipairs(ids) do
      if Fk:getCardById(id):getMark("@@diou_showed") ~= 0 then
        room:setCardMark(Fk:getCardById(id), "@@diou_showed", 0)
      end
    end
    return #cards > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    local draw = not table.contains(player:getTableMark("diou-turn"), id)
    if draw then
      room:addTableMark(player, "diou-turn", id)
    else
      draw = Fk:getCardById(id).trueName == data.card.trueName
    end
    player:showCards(id)
    if player.dead then return end
    local card = Fk:getCardById(id)
    if (card.type == Card.TypeBasic or card:isCommonTrick()) and
      #card:getAvailableTargets(player, { bypass_times = true }) > 0 then
      local use = room:askToUseRealCard(player, {
        pattern = { id },
        skill_name = diou.name,
        cancelable = false,
        extra_data = {
          bypass_times = true,
          expand_pile = { id },
        },
        skip = true,
      })
      if use then
        use.card = Fk:cloneCard(use.card.name, use.card.suit, 0)
        --实测使用【酒】无次数限制，且不计入次数
        room:useCard(use)
      end
    end
    if draw and not player.dead then
      player:drawCards(2, diou.name)
    end
  end,
})

return diou
