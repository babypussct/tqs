local huoluan = fk.CreateSkill{
  name = "ty__huoluan",
}

Fk:loadTranslationTable{
  ["ty__huoluan"] = "惑乱",
  [":ty__huoluan"] = "出牌阶段限一次，你可以与至多两名其他角色同时拼点，你可以将拼点牌更改为任意点数，记录你的原拼点牌，点数唯一最小者"..
  "视为被其余角色各使用一张【杀】，点数唯一最大者摸等同于其体力值的牌，若你两者皆不符，此技能视为未发动过。",

  ["#ty__huoluan"] = "惑乱：你可以与至多两名角色同时拼点",
  ["#ty__huoluan-choice"] = "惑乱：你可以将拼点牌更改为任意点数",
}

huoluan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__huoluan",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(huoluan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    local pindian = player:pindian(effect.tos, huoluan.name)
    local targets = table.simpleClone(effect.tos)
    table.insert(targets, 1, player)
    local nums = {}
    if pindian.fromCard then
      table.insert(nums, pindian.fromCard.number)
      if not player.dead and player:hasSkill("guxing", true) then
        local id = pindian.fromCard:getEffectiveId()
        room:addTableMark(player, "@$guxing", id)
      end
    else
      table.insert(nums, -1)
    end
    for _, p in ipairs(effect.tos) do
      if pindian.results[p].toCard then
        table.insert(nums, pindian.results[p].toCard.number)
      else
        table.insert(nums, -1)
      end
    end
    local max, min = -1, 14
    local winner, loser
    for i = 1, #nums do
      if nums[i] > max then
        max = nums[i]
        winner = targets[i]
      elseif nums[i] == max then
        winner = nil
      end
      if nums[i] < min then
        min = nums[i]
        loser = targets[i]
      elseif nums[i] == min then
        loser = nil
      end
    end
    if loser then
      for _, p in ipairs(targets) do
        if not loser.dead and p ~= loser and not p.dead then
          room:useVirtualCard("slash", nil, p, loser, huoluan.name, true)
        end
      end
    end
    if winner and not winner.dead and winner.hp > 0 then
      winner:drawCards(winner.hp, huoluan.name)
    end
    if winner ~= player and loser ~= player then
      player:setSkillUseHistory(huoluan.name, 0, Player.HistoryPhase)
    end
  end,
})

huoluan:addEffect(fk.BeforeCardsMove, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not table.find(data, function(move) return move.skillName == huoluan.name and move.moveReason == fk.ReasonPindian end) then
      return false
    end

    local pindian = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian)
    if not pindian then
      return false
    end

    return
      pindian.data.from == player and
      not (data.extra_data or {}).huoluanNumber and
      table.find(data,
        function(move)
          return table.find(move.moveInfo, function(moveInfo) return moveInfo.cardId == pindian.data.fromCard:getEffectiveId() end) ~= nil
        end
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pindian = room.logic:getCurrentEvent():findParent(GameEvent.Pindian)
    if not pindian then
      return false
    end

    local number = room:askToNumber(
      player,
      {
        skill_name = huoluan.name,
        prompt = "#ty__huoluan-choice",
        min = 1,
        max = 13,
        cancelable = true,
      }
    )

    pindian.data.extra_data = data.extra_data or {}
    pindian.data.extra_data.huoluanNumber = number
  end,
})

huoluan:addEffect(fk.PindianCardsDisplayed, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.from == player and data.reason == huoluan.name and (data.extra_data or {}).huoluanNumber and player:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    player.room:changePindianNumber(data, player, data.extra_data.huoluanNumber - data.fromCard.number, huoluan.name)
  end,
})

return huoluan
