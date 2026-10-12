local renxing = fk.CreateSkill {
  name = "renxing",
}

Fk:loadTranslationTable{
  ["renxing"] = "任行",
  [":renxing"] = "每轮限两次，每回合首次有牌不于弃牌阶段被弃置时，你可以选择一项：1.与当前回合角色各摸一张牌；2.弃置一名本回合未使用或打出过"..
  "【杀】的角色一张牌。",

  ["renxing_draw"] = "与%dest各摸一张牌",
  ["renxing_discard"] = "弃置一名角色一张牌",
  ["#renxing-choose"] = "任行：选择一名角色，弃置其一张牌",

  ["$renxing1"] = "吾乃天子近臣，自依圣命行事。",
  ["$renxing2"] = "陛下金口玉言，岂会有误？",
}

renxing:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(renxing.name) and
      player.room:getBanner("renxing-turn") == player.room.logic:getCurrentEvent().id and
      player:usedSkillTimes(renxing.name, Player.HistoryRound) < 2
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    if room:getCurrent() and not room:getCurrent().dead then
      table.insert(choices, "renxing_draw::"..room:getCurrent().id)
    end
    local targets = table.filter(room.alive_players, function (p)
      return not p:isNude()
    end)
    if table.contains(targets, player) and
      not table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.card.trueName == "slash" then
        table.removeOne(targets, use.from)
      end
    end, Player.HistoryTurn)
    room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function (e)
      local use = e.data
      if use.card.trueName == "slash" then
        table.removeOne(targets, use.from)
      end
    end, Player.HistoryTurn)
    if #targets > 0 then
      table.insert(choices, "renxing_discard")
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = renxing.name,
    })
    if choice ~= "Cancel" then
      if choice == "renxing_discard" then
        local tos = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = renxing.name,
          prompt = "#renxing-choose",
          cancelable = true,
        })
        if #tos > 0 then
          event:setCostData(self, { choice = "renxing_discard", tos = tos })
          return true
        end
      else
        event:setCostData(self, {choice = "renxing_draw", tos = { room:getCurrent() }})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "renxing_draw" then
      player:drawCards(1, renxing.name)
      if not room:getCurrent().dead then
        room:getCurrent():drawCards(1, renxing.name)
      end
    else
      local to = event:getCostData(self).tos[1]
      if to == player then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = renxing.name,
          cancelable = false,
        })
      else
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = renxing.name,
        })
        room:throwCard(card, renxing.name, to, player)
      end
    end
  end,

  can_refresh = function (self, event, target, player, data)
    if not table.contains({"false", player.room.logic:getCurrentEvent().id}, player.room:getBanner("renxing-turn")) and
      player.room:getCurrent() and player.room.current.phase ~= Player.Discard then
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if room:getBanner("renxing-turn") == nil then
      room:setBanner("renxing-turn", room.logic:getCurrentEvent().id)
    else
      room:setBanner("renxing-turn", "false")
    end
  end,
})

return renxing