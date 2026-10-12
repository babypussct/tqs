local jinzu = fk.CreateSkill {
  name = "jinzu",
}

Fk:loadTranslationTable{
  ["jinzu"] = "劲镞",
  [":jinzu"] = "出牌阶段限一次，你可以选择一名其他角色与其分别同时展示一张、两张手牌，若你展示牌的点数在所有展示牌中："..
  "为中间值，你本回合对其使用的下一张【杀】对其造成的伤害+1且其不可响应；为最值，你弃置所有展示牌。"..
  "若你因此弃置了牌，本技能可以再次发动。",

  ["#jinzu-active"] = "劲镞：你可选择一名其他角色与其一同展示牌",
  ["#jinzu-display"] = "劲镞：展示%arg张手牌，点数为中间值则【杀】有额外效果，为最值则弃置展示牌",
  ["@@jinzu_damage_record-turn"] = "劲镞",

  ["$jinzu1"] = "此箭一出，必丧我流矢之下！",
  ["$jinzu2"] = "纵汝武艺通天，亦躲不过我审心一箭！",
}

jinzu:addEffect("active", {
  prompt = "#jinzu-active",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(jinzu.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player ~= to_select
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = jinzu.name
    local from = effect.from
    local to = effect.tos[1]

    local targets = { from }
    if not to:isKongcheng() then
      table.insert(targets, to)
    end

    if from:isKongcheng() then
      return false
    end

    local displayedMapper = { [from] = {}, [to] = {} }
    if #targets == 1 then
      local ids = room:askToCards(
        from,
        {
          min_num = 1,
          max_num = 1,
          skill_name = skillName,
          prompt = "#jinzu-display:::" .. 1,
          cancelable = false,
        }
      )

      displayedMapper[from] = ids
    else
      local req = Request:new(targets, "AskForUseActiveSkill")
      req.focus_text = skillName
      req.focus_players = targets

      req:setData(from, {
        "choose_cards_skill",
        "#jinzu-display:::" .. 1,
        false,
        {
          num = 1,
          min_num = 1,
          include_equip = false,
          skillName = skillName,
          pattern = ".",
        },
      })
      req:setDefaultReply(from, room:tableRandomPick(from:getCardIds("h"), 1))

      local displayNum = math.min(2, to:getHandcardNum())
      req:setData(to, {
        "choose_cards_skill",
        "#jinzu-display:::" .. displayNum,
        false,
        {
          num = displayNum,
          min_num = displayNum,
          include_equip = false,
          skillName = skillName,
          pattern = ".",
        },
      })
      req:setDefaultReply(to, room:tableRandomPick(to:getCardIds("h"), displayNum))

      req:ask()

      local ids = {}
      local result = req:getResult(from)
      if result ~= "" then
        if result.card then
          ids = result.card.subcards
        else
          ids = result
        end
      end
      displayedMapper[from] = ids

      local targetIds = {}
      result = req:getResult(to)
      if result ~= "" then
        if result.card then
          targetIds = result.card.subcards
        else
          targetIds = result
        end
      end
      displayedMapper[to] = targetIds
    end

    if #displayedMapper[to] == 0 then
      local chosenCard = displayedMapper[from][1]
      from:showCards(chosenCard)

      local damageMapper = to:getTableMark("@@jinzu_damage_record-turn")
      damageMapper[tostring(from.id)] = (damageMapper[tostring(from.id)] or 0) + 1
      room:setPlayerMark(to, "@@jinzu_damage_record-turn", damageMapper)

      if
        table.contains(from:getCardIds("h"), chosenCard) and
        not from:prohibitDiscard(chosenCard)
      then
        room:throwCard(chosenCard, skillName, from, from)
        from:clearSkillHistory(skillName)
      end
    else
      local yourCard = Fk:getCardById(displayedMapper[from][1])
      local targetCards = table.map(displayedMapper[to], function(id)
        return Fk:getCardById(id)
      end)
      from:showCards(yourCard)
      if not to:isAlive() then
        return false
      end

      to:showCards(targetCards)
      if not from:isAlive() then
        return false
      end

      local minNumber, maxNumber = 0, 0
      if #targetCards == 1 then
        minNumber = targetCards[1].number
        maxNumber = minNumber
      else
        if targetCards[1].number >= targetCards[2].number then
          minNumber = targetCards[2].number
          maxNumber = targetCards[1].number
        else
          minNumber = targetCards[1].number
          maxNumber = targetCards[2].number
        end
      end

      if yourCard.number <= maxNumber and yourCard.number >= minNumber then
        local damageMapper = to:getTableMark("@@jinzu_damage_record-turn")
        damageMapper[tostring(from.id)] = (damageMapper[tostring(from.id)] or 0) + 1
        room:setPlayerMark(to, "@@jinzu_damage_record-turn", damageMapper)
      end

      if yourCard.number >= maxNumber or yourCard.number <= minNumber then
        if
          table.contains(from:getCardIds("h"), yourCard.id) and
          not from:prohibitDiscard(yourCard)
        then
          room:throwCard(yourCard, skillName, from, from)
          from:clearSkillHistory(skillName)
        end

        local toDiscard = table.filter(targetCards, function(card)
          return table.contains(to:getCardIds("h"), card.id)
        end)
        if to:isAlive() and #toDiscard > 0 then
          room:throwCard(toDiscard, skillName, to, from)
        end
      end
    end
  end,
})

jinzu:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      table.find(data.tos, function(p)
        return p:getTableMark("@@jinzu_damage_record-turn")[tostring(player.id)]
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    local targets = table.filter(data.tos, function(p)
      return p:getTableMark("@@jinzu_damage_record-turn")[tostring(player.id)]
    end)

    data.extra_data = data.extra_data or {}
    data.extra_data.jinzuDmgMapper = data.extra_data.jinzuDmgMapper or {}
    table.forEach(targets, function(p)
      local jinzuRecord = p:getTableMark("@@jinzu_damage_record-turn")
      local playerId = tostring(player.id)

      data.disresponsiveList = data.disresponsiveList or {}
      table.insertIfNeed(data.disresponsiveList, p)
      data.extra_data.jinzuDmgMapper[p] = (data.extra_data.jinzuDmgMapper[p] or 0) +
        jinzuRecord[playerId]

      jinzuRecord[playerId] = nil
      if next(jinzuRecord) == nil then
        jinzuRecord = 0
      end

      player.room:setPlayerMark(p, "@@jinzu_damage_record-turn", jinzuRecord)
    end)
  end,
})

jinzu:addEffect(fk.DamageInflicted, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:isAlive() and data.card and not data.chain) then
      return false
    end

    local effect = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if effect and ((effect.data.extra_data or {}).jinzuDmgMapper or {})[player] then
      event:setCostData(self, { damage = effect.data.extra_data.jinzuDmgMapper[player] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(event:getCostData(self).damage)
  end,
})

return jinzu
