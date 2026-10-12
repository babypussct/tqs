local xingbu = fk.CreateSkill {
  name = "xingbu"
}

Fk:loadTranslationTable{
  ["xingbu"] = "星卜",
  [":xingbu"] = "结束阶段，你可以亮出牌堆顶的三张牌，然后你可以根据其中红色牌的数量，令一名你指定的其他角色获得以下效果之一：<br/>" ..
  "3张红色牌：<font color='#CC3131'>«五星连珠»</font>，其下个回合摸牌阶段额外摸2张牌、出牌阶段可以额外使用一张【杀】；<br/>" ..
  "2张红色牌：«白虹贯日»，其下个回合出牌阶段可使用【杀】的次数-1，并跳过弃牌阶段；<br/>" ..
  "不多于1张红色牌：<font color='grey'>«荧惑守心»</font>，其下个回合准备阶段弃置一张手牌。",

  ["_xingbu_1"] = "<font color='grey'>荧惑守心</font>",
  ["#xingbu-target"] = "星卜：你可选择一名其他角色，令其获得“%arg”",
  ["@xingbu"] = "星卜",
  ["@xingbu-turn"] = "星卜",
  ["_xingbu_2"] = "白虹贯日",
  ["_xingbu_3"] = "<font color='#CC3131'>五星连珠</font>",
  ["#xingbu-discard"] = "星卜：弃置一张牌",

  ["$xingbu1"] = "天现祥瑞，此乃大吉之兆。",
  ["$xingbu2"] = "天象显异，北伐万不可期。",
}

xingbu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(xingbu.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = xingbu.name
    local room = player.room
    local cids = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cids, skillName)

    local num = 0
    for _, cid in ipairs(cids) do
      if Fk:getCardById(cid).color == Card.Red then
        num = num + 1
      end
    end
    local result
    if num > 1 then
      result = "_xingbu_" .. tostring(num)
      player:broadcastSkillInvoke(skillName, 1)
      room:notifySkillInvoked(player, skillName)
    else
      result = "_xingbu_1"
      player:broadcastSkillInvoke(skillName, 2)
      room:notifySkillInvoked(player, skillName, "negative")
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#xingbu-target:::" .. result,
        skill_name = skillName,
      }
    )
    if #tos > 0 then
      room:setPlayerMark(tos[1], "@xingbu", result)
    end
    room:moveCardTo(cids, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, nil, true, player)
  end,
})

xingbu:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player)
    return
      player == target and
      not player.dead and
      player.phase == Player.Start and
      player:getMark("@xingbu-turn") == "_xingbu_1"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    player.room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = xingbu.name,
        cancelable = false,
        prompt = "#xingbu-discard"
      }
    )
  end,
})

xingbu:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and not player.dead and player:getMark("@xingbu-turn") == "_xingbu_3"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

xingbu:addEffect(fk.EventPhaseChanging, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:getMark("@xingbu-turn") == "_xingbu_2" and
      data.phase == Player.Discard and
      not data.skipped
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.skipped = true
  end,
})

xingbu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("@xingbu") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@xingbu-turn", player:getMark("@xingbu"))
    room:setPlayerMark(player, "@xingbu", 0)
  end,
})

xingbu:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player:getMark("@xingbu-turn") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      if player:getMark("@xingbu-turn") == "_xingbu_3" then
        return 1
      elseif player:getMark("@xingbu-turn") == "_xingbu_2" then
        return -1
      end
    end
  end,
})

return xingbu
