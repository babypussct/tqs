local siqi = fk.CreateSkill{
  name = "siqi",
}

Fk:loadTranslationTable{
  ["siqi"] = "思泣",
  [":siqi"] = "当你的牌移至弃牌堆后，你将其中的红色牌置于牌堆底。"..
  "当你受到伤害后，你可以亮出牌堆底的X张牌（X为从牌堆底开始连续的红色牌数且至多为3），"..
  "依次可以使用其中的所有【桃】、【无中生有】和装备牌（可以对其他角色使用），然后摸等同于其他牌数的牌。",

  ["#siqi-use"] = "思泣：你可以依次使用亮出的牌（可以对其他角色使用）",

  ["$siqi1"] = "红泪落霜鬓，自此无处归乡。",
  ["$siqi2"] = "挥泪别古道，唯见瘦马曳西风。",
}

siqi:addAuxActiveSkill("siqi_active", {
  card_num = 1,
  expand_pile = function (self, player)
    return player:getTableMark("siqi-tmp")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getTableMark("siqi-tmp"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 0 or #selected > 0 then return false end
    local card = Fk:getCardById(selected_cards[1], true)
    return not player:isProhibited(to_select, card) and card.skill:modTargetFilter(player,to_select, {}, card, {bypass_times = true})
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 0 then return false end
    if #selected == 0 then
      local card = Fk:getCardById(selected_cards[1], true)
      return not player:isProhibited(player, card) and card.skill:modTargetFilter(player, player, {}, card, {bypass_times = true})
    end
    return true
  end,
})

siqi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(siqi.name) then
      local room = player.room
      local toObtain, toConfirm = {}, {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                Fk:getCardById(info.cardId).color == Card.Red and table.contains(room.discard_pile, info.cardId) then
                table.insert(toObtain, info.cardId)
              end
            end
          else
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.Processing and
                Fk:getCardById(info.cardId).color == Card.Red and table.contains(room.discard_pile, info.cardId) then
                if move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse then
                  table.insert(toConfirm, info.cardId)
                end
              end
            end
          end
        end
      end
      if #toConfirm > 0 then
        local move_event = room.logic:getCurrentEvent()
        local parent_event = move_event.parent
        if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
          local use = parent_event.data ---@type UseCardData|RespondCardData
          if use.from == player and use.subcardsFromInfo then
            for _, info in ipairs(use.subcardsFromInfo) do
              if table.removeOne(toConfirm, info.cardId) and info.from == player and
                (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
                table.insert(toObtain, info.cardId)
              end
            end
          end
        end
      end
      toObtain = room.logic:moveCardsHoldingAreaCheck(toObtain)
      if #toObtain > 0 then
        event:setCostData(self, { cards = toObtain })
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:moveCards {
      ids = event:getCostData(self).cards,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = siqi.name,
      proposer = player,
      moveVisible = true,
      drawPilePosition = -1
    }
  end,
})

siqi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(siqi.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local dp_cards = room.draw_pile
    local x = #dp_cards
    if x == 0 then return false end
    local id
    local card
    local to_show = {}
    local cards = {}
    for i = 1, math.min(3, x), 1 do
      id = dp_cards[x+1-i]
      card = Fk:getCardById(id, true)
      if card.color == Card.Red then
        table.insert(to_show, id)
        if card.type == Card.TypeEquip or card.trueName == "peach" or card.trueName == "ex_nihilo" then
          table.insert(cards, id)
        end
      else
        break
      end
    end
    if #to_show == 0 then return false end
    room:turnOverCardsFromDrawPile(player, to_show, siqi.name)
    local to_use
    repeat
      to_use = table.filter(cards, function(cid)
        if room:getCardArea(cid) ~= Card.Processing then return false end
        card = Fk:getCardById(cid, true)
        return not (player:prohibitUse(card) or table.every(room.alive_players, function(p)
          return player:isProhibited(p, card) or not card.skill:modTargetFilter(player, p, {}, card, {bypass_times = true})
        end))
      end)
      if #to_use == 0 then break end
      room:setPlayerMark(player, "siqi-tmp", to_use)
      local _, dat = room:askToUseActiveSkill(player, {
        skill_name = "siqi_active",
        prompt = "#siqi-use",
        no_indicate = true,
      })
      room:setPlayerMark(player, "siqi-tmp", 0)
      if dat then
        room:useCard{
          card = Fk:getCardById(dat.cards[1], true),
          from = player,
          tos = #dat.targets > 0 and dat.targets or { player },
          extraUse = true,
        }
      else
        break
      end
    until player.dead
    if not player.dead then
      x = #to_show - #cards
      if x > 0 then
        room:drawCards(player, x, siqi.name)
      end
    end
    room:cleanProcessingArea(to_show, siqi.name)
  end,
})

siqi:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return siqi
