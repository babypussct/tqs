local shedao = fk.CreateSkill {
  name = "shedao",
}

Fk:loadTranslationTable{
  ["shedao"] = "慑道",
  [":shedao"] = "其他角色的牌于你的回合内移至弃牌堆后，你可以选择一项："..
  "1.获得其中至少一张红色牌并弃置一张黑色牌，然后本回合这些牌不计入手牌上限；"..
  "2.获得其中的【杀】并永久视为雷【杀】。",

  ["#shedao-choice"] = "慑道：你可以选择一项发动",
  ["shedao_red"] = "获得其中任意张红色牌并弃置一张黑色牌",
  ["shedao_slash"] = "获得其中的【杀】并永久视为雷【杀】",
  ["#shedao-cards"] = "慑道：获得其中任意张红色牌并弃置一张黑色牌",
  ["@@shedao-inhand-turn"] = "慑道",

  ["$shedao1"] = "刘备急战，必经此路而过。",
  ["$shedao2"] = "张网待敌，纵凤雏也难遁！",
}

local shedaoCardFilter = function(room, id)
  if table.contains(room.discard_pile, id) then
    local card = Fk:getCardById(id)
    return card.trueName == "slash" or card.color == Card.Red
  end
  return false
end

shedao:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(shedao.name) and room.current == player then
      local cards, toUseOrResponse, toPindian, toConfirm = {}, {}, {}, {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.from and move.from ~= player then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                shedaoCardFilter(room, info.cardId) then
                table.insert(cards, info.cardId)
              end
            end
          else
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.Processing and shedaoCardFilter(room, info.cardId) then
                if move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse then
                  table.insert(toUseOrResponse, info.cardId)
                elseif move.moveReason == fk.ReasonPindian then
                  table.insert(toPindian, info.cardId)
                else
                  table.insert(toConfirm, info.cardId)
                end
              end
            end
          end
        end
      end
      if #toUseOrResponse > 0 then
        local move_event = room.logic:getCurrentEvent()
        local parent_event = move_event.parent
        if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
          local use = parent_event.data ---@type UseCardData|RespondCardData
          if use.from ~= player and use.subcardsFromInfo then
            for _, info in ipairs(use.subcardsFromInfo) do
              if table.removeOne(toUseOrResponse, info.cardId) and info.from == use.from then
                --使用木马里的牌也能发动，故不判fromArea
                table.insert(cards, info.cardId)
              end
            end
          end
        end
      end
      if #toPindian > 0 then
        local move_event = room.logic:getCurrentEvent()
        local parent_event = move_event.parent
        if parent_event.event == GameEvent.Pindian then
          local pindian = parent_event.data ---@type PindianData
          if pindian.from ~= player then
            for _, id in ipairs(room:getSubcardsByRule(pindian.fromCard)) do
              if table.removeOne(toPindian, id) then
                table.insert(cards, id)
              end
            end
          end
          for to, result in pairs(pindian.results) do
            if to ~= player then
              for _, id in ipairs(room:getSubcardsByRule(result.toCard)) do
                if table.removeOne(toPindian, id) then
                  table.insert(cards, id)
                end
              end
            end
          end
        end
      end
      if #toConfirm > 0 then
        local start_id = room.logic:getCurrentEvent().id
        room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
          if e.id < start_id then
            for _, move in ipairs(e.data) do
              for _, info in ipairs(move.moveInfo) do
                if table.removeOne(toConfirm, info.cardId) and move.from ~= player and
                  (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
                  table.insert(cards, info.cardId)
                end
              end
            end
            return (#toConfirm == 0)
          end
        end, 0)
      end
      if #cards > 0 then
        event:setCostData(self, { cards = cards })
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local all_choice = {"shedao_red", "shedao_slash", "Cancel"}
    local reds, slashs = {}, {}
    for _, id in ipairs(event:getCostData(self).cards) do
      local card = Fk:getCardById(id)
      if card.color == Card.Red then
        table.insert(reds, id)
      end
      if card.trueName == "slash" then
        table.insert(slashs, id)
      end
    end
    local choices = {"Cancel"}
    if #reds > 0 and table.find(player:getCardIds("he"), function(id)
      local card = Fk:getCardById(id)
      return card.color == Card.Black and not player:prohibitDiscard(card)
    end) ~= nil then
      table.insert(choices, "shedao_red")
    end
    if #slashs > 0 then
      table.insert(choices, "shedao_slash")
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = shedao.name,
      prompt = "#shedao-choice",
      all_choices = all_choice
    })
    if choice == "shedao_red" then
      event:setCostData(self, { cards = reds, choice = choice })
      return true
    elseif choice == "shedao_slash" then
      event:setCostData(self, { cards = slashs, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = shedao.name
    local dat = event:getCostData(self)
    local cards = dat.cards ---@type integer[]
    if dat.choice == "shedao_red" then
      if not table.find(player:getCardIds("he"), function(id)
        local card = Fk:getCardById(id)
        return card.color == Card.Black and not player:prohibitDiscard(card)
      end) then
        return
      end
      cards = room:askToCards(player, {
        min_num = 1,
        max_num = #cards,
        include_equip = false,
        skill_name = skillName,
        pattern = tostring(Exppattern{ id = cards }),
        prompt = "#shedao-cards",
        cancelable = false,
        expand_pile = cards
      })
      room:obtainCard(player, cards, true, fk.ReasonJustMove, player, skillName)
      if player.dead then return end
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        pattern = ".|.|black",
        cancelable = false,
      })
      if player.dead then return end
      for _, id in ipairs(player:getCardIds("h")) do
        if table.contains(cards, id) then
          room:setCardMark(Fk:getCardById(id), "@@shedao-inhand-turn", 1)
        end
      end
    elseif dat.choice == "shedao_slash" then
      room:obtainCard(player, cards, true, fk.ReasonJustMove, player, skillName)
      for _, id in ipairs(player:getCardIds("h")) do
        if table.contains(cards, id) then
          room:setCardMark(Fk:getCardById(id), "shedao_slash", 1)
          Fk:filterCard(id, player)
        end
      end
    end
  end,
})

--在所有角色的手牌区时视为雷【杀】
shedao:addEffect("filter", {
  card_filter = function(self, to_select, player)
    return to_select:getMark("shedao_slash") ~= 0 and table.contains(player:getCardIds("h"), to_select.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("thunder__slash", card.suit, card.number)
  end,
})

shedao:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@shedao-inhand-turn") > 0
  end,
})

return shedao
