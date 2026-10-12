local shanjia = fk.CreateSkill{
  name = "ol__shanjia",
}

Fk:loadTranslationTable{
  ["ol__shanjia"] = "缮甲",
  [":ol__shanjia"] = "游戏开始时，你获得3个“损”标记。当你失去装备牌后，你移去1个“损”。"..
  "出牌阶段限一次，你可以摸三张牌，并可以使用一张【杀】，然后你此阶段使用下X张手牌时，你弃置一张牌（X为“损”数）。"..
  "若如此做，此阶段结束时，若你此阶段未因“缮甲”弃置过牌或仅弃置过装备牌，你可以视为使用一张无距离限制的【杀】。",

  ["@ol__shanjia"] = "损",
  ["#ol__shanjia"] = "缮甲：你可以摸三张牌，使用一张【杀】",
  ["#ol__shanjia-use"] = "缮甲：你可以使用一张【杀】",
  ["#ol__shanjia-slash"] = "缮甲：你可以视为使用一张无距离限制的【杀】",

  ["$ol__shanjia1"] = "虎豹骁骑，甲兵自当冠宇天下。",
  ["$ol__shanjia2"] = "非虎贲难入我营，唯坚铠方配锐士。",
}

shanjia:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ol__shanjia", 0)
end)

shanjia:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ol__shanjia",
  card_num = 0,
  target_num = 0,
  can_use = function (self, player)
    return player:usedEffectTimes(shanjia.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function (self, room, effect)
    local player = effect.from
    player:drawCards(3, shanjia.name)
    if player.dead then return end
    local use = room:askToUseCard(player, {
      skill_name = shanjia.name,
      pattern = "slash",
      prompt = "#ol__shanjia-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
      },
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    end

    if player:isAlive() then
      room:setPlayerMark(player, "ol__shanjia_active-phase", 1)
    end
  end,
})
shanjia:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(shanjia.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@ol__shanjia", 3)
  end,
})

shanjia:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@ol__shanjia") > 0 and player:hasSkill(shanjia.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player then
        if move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).type == Card.TypeEquip then
              n = n + 1
            end
          end
        else
          local parent_event = player.room.logic:getCurrentEvent().parent
          if parent_event ~= nil then
            if parent_event.event == GameEvent.UseCard then
              local use = parent_event.data
              if use.from ~= player or use.card.type ~= Card.TypeEquip then
                parent_event:searchEvents(GameEvent.MoveCards, 1, function(e2)
                  if e2.parent and e2.parent.id == parent_event.id then
                    for _, move2 in ipairs(e2.data) do
                      if move2.from == player and move2.moveReason == fk.ReasonUse then
                        for _, info in ipairs(move2.moveInfo) do
                          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId).type == Card.TypeEquip then
                            n = n + 1
                          end
                        end
                      end
                    end
                  end
                end)
              end
            end
          end
        end
      end
    end
    if n > 0 then
      player.room:removePlayerMark(player, "@ol__shanjia", n)
    end
  end,
})

shanjia:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player:getMark("ol__shanjia_active-phase") > 0 and
      player:getMark("@ol__shanjia") > player:getMark("ol__shanjia_used-phase") and
      data:isUsingHandcard(player)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "ol__shanjia_used-phase")
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shanjia.name,
      cancelable = false,
    })
  end,
})
shanjia:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      player:usedEffectTimes(shanjia.name, Player.HistoryPhase) > 0 and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.skillName == shanjia.name and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              return Fk:getCardById(info.cardId).type ~= Card.TypeEquip
            end
          end
        end
      end, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = shanjia.name,
      prompt = "#ol__shanjia-slash",
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

shanjia:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    return {}, ai:getBenefitOfEvents(function(logic)
      logic:drawCards(ai.player, 3)
    end)
  end,
})

return shanjia
