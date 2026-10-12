local jianbai = fk.CreateSkill{
  name = "jianbai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jianbai"] = "坚白",
  [":jianbai"] = "锁定技，你每回合首次使用一种类型的牌后，你保留一个花色，重铸其余牌。"..
  "此回合结束时，你交给一名其他角色一张牌并摸X张牌（X为此牌本回合被保留的次数）。",

  ["@jianbai-turn"] = "坚白",
  ["#jianbai-ask"] = "坚白：保留一个花色，重铸其余牌",
  ["#jianbai-give"] = "坚白：交给一名其他角色一张牌，摸对应张数的牌",
  ["@jianbai-inhand-turn"] = "坚白",

  ["$jianbai1"] = "阿爷答应我的事，一定能做到。",
  ["$jianbai2"] = "花开有期，世间流水终会相逢。",
}

jianbai:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jianbai.name) and not player:isNude() then
      local room = player.room
      local use_event = room.logic:getCurrentEvent()
      local mark_name = "jianbai_" .. data.card:getTypeString() .. "-turn"
      local mark = player:getMark(mark_name)
      if mark == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data
          if last_use.from == player and last_use.card.type == data.card.type then
            mark = e.id
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryTurn)
      end
      return mark == use_event.id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_choices = { "log_spade", "log_club", "log_heart", "log_diamond" }
    local choices = {}
    local choice_map = { {}, {}, {}, {}, {} } ---@type integer[][]
    for _, id in ipairs(player:getCardIds("he")) do
      table.insert(choice_map[Fk:getCardById(id).suit], id)
    end
    for i, c in ipairs(all_choices) do
      if #choice_map[i] > 0 then
        table.insert(choices, c)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      all_choices = all_choices,
      skill_name = jianbai.name,
      prompt = "#jianbai-ask",
    })
    local index = table.indexOf(all_choices, choice)
    local remains = table.remove(choice_map, index)
    local map = player:getTableMark("jianbai-turn")
    for _, id in ipairs(remains) do
      map[tostring(id)] = (map[tostring(id)] or 0) + 1
    end
    room:setPlayerMark(player, "jianbai-turn", map)
    for _, id in ipairs(remains) do
      room:setCardMark(Fk:getCardById(id, true), "@jianbai-inhand-turn", map[tostring(id)] or 0)
    end
    local cards = table.connect(table.unpack(choice_map))
    if #cards > 0 then
      room:recastCard(cards, player, jianbai.name)
    end
  end,
})

jianbai:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jianbai.name) and
      player:getMark("@jianbai-turn") ~= 0 and not player:isNude() and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".",
      skill_name = jianbai.name,
      prompt = "#jianbai-give",
      cancelable = false,
    })
    local n = player:getTableMark("jianbai-turn")[tostring(card[1])] or 0
    room:moveCardTo(card, Card.PlayerHand, to[1], fk.ReasonGive, jianbai.name, nil, false, player)
    if not player.dead and n > 0 then
      player:drawCards(n, jianbai.name)
    end
  end,
})

jianbai:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianbai.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@jianbai-turn", data.card:getTypeString().."_char")
  end,
})

jianbai:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local types = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(types, use.card:getTypeString().."_char")
      end
    end, Player.HistoryTurn)
    if #types > 0 then
      room:setPlayerMark(player, "@jianbai-turn", types)
    end
  end
end)

jianbai:addLoseEffect(function (self, player)
  local room = player.room
  room:setPlayerMark(player, "@jianbai-turn", 0)
  room:setPlayerMark(player, "jianbai-turn", 0)
  for _, id in ipairs(player:getCardIds("he")) do
    room:setCardMark(Fk:getCardById(id, true), "@jianbai-inhand-turn", 0)
  end
end)

return jianbai
