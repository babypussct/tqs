local anxian = fk.CreateSkill {
  name = "anxianc",
}

Fk:loadTranslationTable{
  ["anxianc"] = "暗弦",
  [":anxianc"] = "当你每回合首次弃置手牌后，你可以获得并使用其中一张【杀】，此【杀】不计入次数且无距离次数限制。",

  ["#anxianc-choose"] = "暗弦：你可以获得其中一张【杀】然后使用之（不计入次数且无距离次数限制）",
  ["#anxianc-slash"] = "暗弦：请使用此【杀】（不计入次数且无距离次数限制）",

  ["$anxianc1"] = "暗挽雕弓，箭引霹雳之声！",
  ["$anxianc2"] = "今日让尔，知我箭术的历害！",
}

anxian:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(anxian.name) then
      return false
    end

    local room = player.room
    local recordId = player:getMark("anxian_record-turn-noclear")
    if recordId == 0 then
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local moveData = e.data
        if
          table.find(moveData, function(move)
            if move.from == player and move.moveReason == fk.ReasonDiscard then
              return table.find(move.moveInfo, function(info)
                return info.fromArea == Card.PlayerHand
              end) ~= nil
            end
          end) ~= nil
        then
          recordId = e.id
          room:setPlayerMark(player, "anxian_record-turn-noclear", e.id)
          return true
        end
      end, Player.HistoryTurn)
    end

    return
      recordId == room.logic:getCurrentEvent().id and
      table.find(data, function(move)
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          return table.find(move.moveInfo, function(info)
            local card = Fk:getCardById(info.cardId)
            return
              card.trueName == "slash" and
              info.fromArea == Card.PlayerHand and
              room:getCardArea(card) == Card.DiscardPile
          end) ~= nil
        end
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local slashes = {}
    local room = player.room
    table.forEach(data, function(move)
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        table.forEach(move.moveInfo, function(info)
          local card = Fk:getCardById(info.cardId)
          if
            card.trueName == "slash" and
            info.fromArea == Card.PlayerHand and
            room:getCardArea(card) == Card.DiscardPile
          then
            table.insert(slashes, info.cardId)
          end
        end)
      end
    end)

    if #slashes == 0 then
      return false
    end

    local ids = room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        pattern = tostring(Exppattern { id = slashes }),
        skill_name = anxian.name,
        prompt = "#anxianc-choose",
        expand_pile = slashes,
      }
    )

    if #ids > 0 then
      event:setCostData(self, { cards = ids })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    ---@type integer[]
    local cards = event:getCostData(self).cards
    room:obtainCard(player, cards, true, fk.ReasonPrey, player, anxian.name)

    room:askToUseRealCard(
      player,
      {
        pattern = cards,
        prompt = "#anxianc-slash",
        skill_name = anxian.name,
        cancelable = false,
        extra_data = {
          bypass_distances = true,
          expand_pile = cards,
        }
      }
    )
  end,
})

return anxian
