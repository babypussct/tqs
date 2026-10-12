local kedi = fk.CreateSkill{
  name = "kedi",
}

Fk:loadTranslationTable{
  ["kedi"] = "柯笛",
  [":kedi"] = "当你每回合前两次使用牌结算结束后，你可以令一名角色重铸一张牌。"..
  "你可以无次数限制地使用弃牌堆里的以此法重铸的牌，直到你的下个回合开始。",

  ["#kedi-choose"] = "柯笛：令一名角色重铸一张牌，你可以使用其重铸的牌",
  ["#kedi_nosuit-recast"] = "柯笛：请重铸一张牌",
  ["#kedi-recast"] = "柯笛：请重铸一张牌，%src 可以使用重铸的牌",
  ["#kedi"] = "柯笛：你可以使用其中的牌（无次数限制）",
  ["@$kedi"] = "柯笛",

  ["$kedi1"] = "",
  ["$kedi2"] = "",
}

kedi:addEffect("viewas", {
  pattern = ".",
  prompt = "#kedi",
  expand_pile = function(self, player)
    return player:getTableMark("@$kedi")
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  card_filter = function(self, player, to_select, selected)
    return
      #selected == 0 and
      table.contains(Fk:currentRoom().discard_pile, to_select) and
      table.contains(player:getTableMark("@$kedi"), to_select) and
      player:canUseOrResponseInCurrent(Fk:getCardById(to_select))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    return Fk:getCardById(cards[1])
  end,
  enabled_at_play = function(self, player)
    return #player:getTableMark("@$kedi") > 0
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    for _, id in ipairs(player:getTableMark("@$kedi")) do
      if player:canUseOrResponseInCurrent(Fk:getCardById(id)) then
        return true
      end
    end
  end,
  enabled_at_nullification = function(self, player, data)
    for _, id in ipairs(player:getTableMark("@$kedi")) do
      if Fk:getCardById(id).trueName == "nullification" then
        return true
      end
    end
  end
})

kedi:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if target == player and player:hasSkill(kedi.name) and player.room:getCurrent() and
      table.find(room.alive_players, function(p)
        return not p:isNude()
      end) then
      local mark = player:getTableMark("kedi_record-turn")
      if #mark < 2 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data
          if use.from == player and use:isUsingHandcard(player) then
            table.insert(mark, e.id)
          end
        end, Player.HistoryTurn)
        room:setPlayerMark(player, "kedi_record-turn", mark)
      end
      return table.contains(mark, room.logic:getCurrentEvent().id)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = kedi.name,
      prompt = "#kedi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = kedi.name,
      prompt = "#kedi-recast:"..player.id,
      cancelable = false,
    })
    room:recastCard(card, to, kedi.name)
    if room:getCardArea(card[1]) == Card.DiscardPile and player:hasSkill(kedi.name, true) then
      room:addTableMarkIfNeed(player, "@$kedi", card[1])
    end
  end,
})

kedi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$kedi", 0)
  end,
})

kedi:addEffect(fk.AfterDrawPileShuffle, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$kedi", 0)
  end,
})

kedi:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return #player:getTableMark("@$kedi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@$kedi")
    for _, move in ipairs(data) do
      if move.toArea ~= Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DiscardPile then
            table.removeOne(mark, info.cardId)
          end
        end
      end
    end
    room:setPlayerMark(player, "@$kedi", #mark > 0 and mark or 0)
  end,
})

kedi:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(player:getTableMark("@$kedi"), card.id)
  end,
})

kedi:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@$kedi", 0)
end)

return kedi
