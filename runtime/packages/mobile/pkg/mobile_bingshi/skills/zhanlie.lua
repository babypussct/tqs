local zhanlie = fk.CreateSkill{
  name = "zhanlie",
}

Fk:loadTranslationTable{
  ["zhanlie"] = "战烈",
  [":zhanlie"] = "一名角色的回合开始时，你记录X（X为此时你的攻击范围）。本回合中的前X张【杀】进入弃牌堆后，若此牌在弃牌堆内，" ..
  "你获得1枚“烈”标记（你至多拥有6枚“烈”标记）；出牌阶段结束时，你可以移除所有“烈”标记，视为使用一张无次数限制的【杀】，" ..
  "并选择至多Y项（Y为你本次移除的标记数/3，向下取整）：1.此【杀】目标+1；2.此【杀】伤害基数+1；3.此【杀】需目标角色额外弃置一张牌方可响应；" ..
  "4.此【杀】结算结束后你摸两张牌。",

  ["@zhanlie"] = "烈",
  ["#zhanlie-slash"] = "战烈：你可以视为使用带有至多%arg个额外效果的【杀】",
  ["#zhanlie-choice"] = "战烈：请为此【杀】选择至多%arg项额外效果",
  ["zhanlie_target"] = "目标+1",
  ["zhanlie_damage"] = "伤害+1",
  ["zhanlie_disresponsive"] = "需额外弃置一张牌响应",
  ["zhanlie_draw"] = "结算后摸两张牌",
  ["#zhanlie_target"] = "战烈：请为此【杀】选择一个额外目标",
  ["#zhanlie_discard"] = "战烈：请弃置一张牌，否则你不能响应此【杀】",

  ["$zhanlie1"] = "且看此箭之下，焉有偷生之人？",
  ["$zhanlie2"] = "哼，汝还能战否？",
  ["$zhanlie3"] = "君头已在此，还不授首来降！",
}

local parseZhanLieMark = function (player)
  local mark = player:getMark("@zhanlie")
  if mark == 0 then
    return { num = 0, max = 0 }
  end

  local markParsed = mark:split('/')
  return { num = tonumber(markParsed[1]), max = tonumber(markParsed[2]) }
end

zhanlie:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhanlie.name) and parseZhanLieMark(player).max > parseZhanLieMark(player).num then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).trueName == "slash" and table.contains(player.room.discard_pile, info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = parseZhanLieMark(player)
    local canPlusNum = dat.max - dat.num
    if canPlusNum == 0 then
      return false
    end

    local marksToGet = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).trueName == "slash" and table.contains(player.room.discard_pile, info.cardId) then
            marksToGet = marksToGet + 1
          end
          if marksToGet >= canPlusNum then
            break
          end
        end
        if marksToGet >= canPlusNum then
          break
        end
      end
    end
    room:removePlayerMark(player, "zhanlie_max", marksToGet)
    room:setPlayerMark(player, "@zhanlie", (dat.num + marksToGet) .. "/" .. dat.max)
  end,
})
zhanlie:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhanlie.name) and player.phase == Player.Play and
      parseZhanLieMark(player).num > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = zhanlie.name,
      prompt = "#zhanlie-slash:::" .. math.floor(parseZhanLieMark(player).num / 3),
      extra_data = {
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
  on_use = function(self, event, target, player, data)
    local room = player.room
    local buffNum = math.floor(parseZhanLieMark(player).num / 3)
    room:setPlayerMark(player, "@zhanlie", "0/" .. math.min(6, player:getMark("zhanlie_max")))

    local use = event:getCostData(self).extra_data
    if buffNum > 0 then
      local all_choices = { "zhanlie_target", "zhanlie_damage", "zhanlie_disresponsive", "zhanlie_draw" }
      local choiceList = table.simpleClone(all_choices)

      local targets = UseCardData:new(use):getExtraTargets()
      if (#targets == 0) then
        table.remove(choiceList, 1)
      end
      local choices = room:askToChoices(player, {
        choices = choiceList,
        min_num = 1,
        max_num = buffNum,
        skill_name = zhanlie.name,
        prompt = "#zhanlie-choice:::" .. buffNum,
        cancelable = false,
        all_choices = all_choices,
      })

      for _, choice in ipairs(choices) do
        if choice == "zhanlie_target" then
          local to = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = targets,
            skill_name = zhanlie.name,
            prompt = "#zhanlie_target",
            cancelable = false,
          })[1]
          table.insert(use.tos, to)
          room:sortByAction(use.tos)
        elseif choice == "zhanlie_damage" then
          use.additionalDamage = (use.additionalDamage or 0) + 1
        else
          use.extra_data = use.extra_data or {}
          use.extra_data.zhanlieBuff = use.extra_data.zhanlieBuff or {}
          if choice == "zhanlie_disresponsive" then
            use.extra_data.zhanlieBuff[choice] = true
          else
            use.extra_data.zhanlieBuff[choice] = player
          end
        end
      end
    end

    room:useCard(use)
  end,
})
zhanlie:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(zhanlie.name)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local dat = parseZhanLieMark(player)
    local n = player:getAttackRange()
    local change = player:getMark("@mobile__zhenfeng_"..zhanlie.name)
    if change ~= 0 then
      if change == "mobile__zhenfeng_hp" then
        n = player.hp
      elseif change == "mobile__zhenfeng_lostHp" then
        n = player:getLostHp()
      elseif change == "mobile__zhenfeng_alives" then
        n = #room.alive_players
      end
    end
    if parseZhanLieMark(player).num < 6 then
      room:setPlayerMark(player, "@zhanlie", dat.num .. "/" .. math.min(6, dat.num + n))
    end
    room:setPlayerMark(player, "zhanlie_max", n)
  end,
})
zhanlie:addEffect(fk.PreCardEffect, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.zhanlieBuff and
      data.to == player and data.card.trueName == "slash" and data.extra_data.zhanlieBuff.zhanlie_disresponsive
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zhanlie.name,
      prompt = "#zhanlie_discard",
      cancelable = true,
    }) == 0 then
      data.disresponsive = true
    end
  end,
})
zhanlie:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.zhanlieBuff and
      data.extra_data.zhanlieBuff.zhanlie_draw == player and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, zhanlie.name)
  end,
})

return zhanlie
