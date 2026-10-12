local bibu = fk.CreateSkill {
  name = "bibu",
}

Fk:loadTranslationTable {
  ["bibu"] = "庇部",
  [":bibu"] = "你的上家和下家每回合首次成为其他角色使用的【杀】或普通锦囊牌的唯一目标时，你可以摸一张牌，令此牌的目标改为你；" ..
      "你的上家和下家每回合首次使用【杀】或普通锦囊牌结算结束后，你可以摸一张牌，然后可以视为使用此牌。",

  ["#bibu1-invoke"] = "庇部：是否摸一张牌，令以 %dest 为目标使用的%arg，改为以你为目标？",
  ["#bibu2-invoke"] = "庇部：你可以摸一张牌，然后可以视为使用【%arg】",
  ["#bibu-use"] = "庇部：你可以视为使用【%arg】",

  ["$bibu1"] = "我死则死，袍泽何辜？",
  ["$bibu2"] = "昔项王踌躇乌江，我何只身南渡？",
}

bibu:addEffect(fk.TargetConfirming, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(bibu.name) and data:isOnlyTarget(target) and
        (target:getNextAlive() == player or player:getNextAlive() == target) and
        (data.card.trueName == "slash" or data.card:isCommonTrick()) and data.from ~= player
        and table.find(data:getExtraTargets({ bypass_distances = true, bypass_times = true }), function(p, index, array)
          return p == player
        end) then
      local room = player.room
      local bibuRecord = target:getMark("bibu_record-turn-noclear")
      if bibuRecord == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data
          if
            table.contains(use.tos, target) and
            (use.card.trueName == "slash" or use.card:isCommonTrick()) and
            not table.find(use.tos, function(p) return p ~= target end)
          then
            bibuRecord = e.id
            room:setPlayerMark(target, "bibu_record-turn-noclear", e.id)
            return true
          end
        end, Player.HistoryTurn)
      end

      return bibuRecord == room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true).id
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = bibu.name,
      prompt = "#bibu1-invoke::" .. target.id .. ":" .. data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    if data:cancelCurrentTarget() then
      data:addTarget(player)
    end
    player:drawCards(1, bibu.name)
  end,
})

bibu:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(bibu.name) and
        (target:getNextAlive() == player or player:getNextAlive() == target) and
        (data.card.trueName == "slash" or data.card:isCommonTrick()) and
        not data.card.is_passive then
      local room = player.room
      local use_events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from == target and (use.card.trueName == "slash" or use.card:isCommonTrick())
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].id == room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
          .id
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = bibu.name,
      prompt = "#bibu2-invoke:::" .. data.card.name,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, bibu.name)
    if not player.dead then
      room:askToUseVirtualCard(player, {
        name = data.card.name,
        skill_name = bibu.name,
        prompt = "#bibu-use:::" .. data.card.name,
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      })
    end
  end,
})

return bibu
