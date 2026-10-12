local osShelie = fk.CreateSkill {
  name = "os__shelie",
}

Fk:loadTranslationTable{
  ["os__shelie"] = "涉猎",
  [":os__shelie"] = "摸牌阶段，你可以改为亮出牌堆顶的五张牌，然后获得其中每种花色的牌各一张。" ..
  "每轮限一次，结束阶段，若你本回合使用过四种花色的牌，你选择执行一个额外的摸牌阶段或出牌阶段且不能与上次选择相同。",

  ["#os__shelie_extra"] = "涉猎",
  ["@os__shelie-turn"] = "涉猎",
  ["#os__shelie_extra-ask"] = "涉猎：选择执行一个额外的阶段",

  ["$os__shelie1"] = "尘世之间，岂有吾所未闻之事？",
  ["$os__shelie2"] = "往事皆知，未来尽料。",
}

osShelie:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osShelie.name) and
      player.phase == Player.Draw and
      not data.phase_end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osShelie.name
    local room = player.room
    data.phase_end = true

    local cards = room:getNCards(5)
    room:turnOverCardsFromDrawPile(player, cards, skillName)

    local get = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id).suit
      if table.every(get, function (id2)
        return Fk:getCardById(id2).suit ~= suit
      end) then
        table.insert(get, id)
      end
    end
    get = room:askToArrangeCards(
      player,
      {
        skill_name = skillName,
        card_map = cards,
        prompt = "#shelie-choose",
        box_size = 0,
        max_limit = { 5, 4 },
        min_limit = { 0, #get },
        poxi_type = "shelie",
        default_choice = { {}, get },
      }
    )[2]
    if #get > 0 then
      room:moveCardTo(get, Player.Hand, player, fk.ReasonPrey, skillName, nil, true, player)
    end

    room:cleanProcessingArea(cards)
  end,
})

osShelie:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osShelie.name) and
      player.phase == Player.Finish and
      #player:getTableMark("@os__shelie-turn") == 4 and
      player:usedEffectTimes(self.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player)
    local choices = { "phase_draw", "phase_play" }
    if player:getMark("_os__shelie") ~= 0 then
      table.removeOne(choices, player:getMark("_os__shelie"))
    end
    event:setCostData(self, player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osShelie.name,
        prompt = "#os__shelie_extra-ask"
      }
    ))
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self)
    room:sendLog{
      type = "#os__shelie_extra_log",
      from = player.id,
      arg = osShelie.name,
      arg2 = choice,
    }
    room:setPlayerMark(player, "_os__shelie", choice)
    player:gainAnExtraPhase(choice == "phase_draw" and Player.Draw or Player.Play)
  end,
})

osShelie:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osShelie.name, true) and
      player.phase ~= Player.NotActive and
      data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@os__shelie-turn", data.card:getSuitString(true))
  end,
})

osShelie:addAcquireEffect(function(self, player, isStart)
  if not isStart and player.phase ~= Player.NotActive then
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event then
      local suitsRecorded = player:getTableMark("@os__shelie-turn")

      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == player then
          table.insertIfNeed(suitsRecorded, use.card:getSuitString(true))
        end
        return false
      end, turn_event.id)
      room:setPlayerMark(player, "@os__shelie-turn", suitsRecorded)
    end
  end
end)

return osShelie
