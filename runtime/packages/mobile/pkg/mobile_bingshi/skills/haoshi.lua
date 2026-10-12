local haoshi = fk.CreateSkill{
  name = "m_shi__haoshi",
}

Fk:loadTranslationTable{
  ["m_shi__haoshi"] = "好施",
  [":m_shi__haoshi"] = "结束阶段，你可以选择一名其他角色，直到你的下个回合开始，其可以如手牌般使用或打出你的手牌。"..
  "当你于此期间前两次因此失去最后的手牌时，你将手牌摸至三张。",

  ["#m_shi__haoshi-choose"] = "好施：选择一名角色，直到你下回合开始，其可以如手牌般使用或打出你的手牌",
  ["@[list]m_shi__haoshi"] = "好施",

  ["$m_shi__haoshi1"] = "以其无私，故能成其私也。",
  ["$m_shi__haoshi2"] = "万贯家财，尽施百姓又何妨？",
  ["$m_shi__haoshi3"] = "今战事频起，百姓流离，吾安忍坐视？",
}

haoshi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(haoshi.name) and
      player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return p ~= player
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    local to = room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = haoshi.name,
        prompt = "#m_shi__haoshi-choose",
        cancelable = true,
      }
    )
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(player, "@[list]m_shi__haoshi", event:getCostData(self).tos[1])
    room:setPlayerMark(player, "haoshi_times", 2)
  end,
})

haoshi:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return
      table.contains(player:getTableMark("@[list]m_shi__haoshi"), target) and
      table.find(Card:getIdList(data.card), function(id)
        local room = player.room
        return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.mShiHaoshiOwner = data.extra_data.mShiHaoshiOwner or {}
    table.insertIfNeed(data.extra_data.mShiHaoshiOwner, player)
  end,
})

haoshi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(haoshi.name) and player:isKongcheng() and player:getMark("haoshi_times") > 0 then
      for _, move in ipairs(data) do
        if move.from == player and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse) then
          local parent_event = player.room.logic:getCurrentEvent().parent
          if parent_event ~= nil then
            if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
              local use = parent_event.data
              if use.extra_data and table.contains(use.extra_data.mShiHaoshiOwner or {}, player) then
                local cards = Card:getIdList(use.card)
                for _, info in ipairs(move.moveInfo) do
                  table.removeOne(cards, info.cardId)
                end
                return #cards == 0
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "haoshi_times")
    return true
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(3 - player:getHandcardNum(), haoshi.name)
  end,
})

haoshi:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and (player:getMark("@[list]m_shi__haoshi") ~= 0 or player:getMark("haoshi_times") > 0)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@[list]m_shi__haoshi", 0)
    room:setPlayerMark(player, "haoshi_times", 0)
  end,
})

haoshi:addEffect("filter", {
  handly_cards = function(self, player)
    local haoshiCards = {}
    table.forEach(Fk:currentRoom().alive_players, function(p)
      if table.contains(p:getTableMark("@[list]m_shi__haoshi"), player) then
        table.insertTable(haoshiCards, p:getCardIds("h"))
      end
    end)

    if #haoshiCards > 0 then
      return haoshiCards
    end
  end,
})

haoshi:addLoseEffect(function (self, player, is_death)
  if player:getMark("@[list]m_shi__haoshi") ~= 0 then
    player.room:setPlayerMark(player, "@[list]m_shi__haoshi", 0)
  end
end)

return haoshi
