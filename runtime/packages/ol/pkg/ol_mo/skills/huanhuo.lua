local huanhuo = fk.CreateSkill {
  name = "huanhuo",
}

Fk:loadTranslationTable{
  ["huanhuo"] = "幻惑",
  [":huanhuo"] = "每轮开始时，你摸两张牌，然后你可弃置至多两张牌并选择等量名其他角色获得2枚“幻惑”标记直到其下个出牌阶段结束。" ..
  "其下个出牌阶段内具有以下效果：<br/>" ..
  "1.若其有可使用的手牌且其有“幻惑”标记，将其出牌阶段空闲时间点操作改为：其只能使用一张随机的可使用的手牌<br/>" ..
  "2.当其使用牌结算结束后，若其有“幻惑”标记，则其随机弃置一张牌并移除一枚“幻惑”标记。",

  ["@huanhuo"] = "幻惑",
  ["#huanhuo-choose"] = "幻惑：请选择至多两张牌弃置并选择等量其他角色",
  ["#huanhuo-use"] = "幻惑：你须使用此牌，否则结束出牌阶段",

  ["$huanhuo1"] = "你们的争斗，不过是我指尖的傀儡戏。",
  ["$huanhuo2"] = "我动动指尖，便能让山河变色，群雄皆醉。",
}

huanhuo:addEffect(fk.RoundStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huanhuo.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = huanhuo.name
    local room = player.room

    player:drawCards(2, skillName)
    local others = room:getOtherPlayers(player, false)
    if #others == 0 or player:isNude() then
      return false
    end

    local tos, cids = room:askToChooseCardsAndPlayers(
      player,
      {
        min_num = 1,
        max_num = 2,
        min_card_num = 1,
        max_card_num = 2,
        targets = others,
        skill_name = skillName,
        will_throw = true,
        equal = true,
        prompt = "#huanhuo-choose",
      }
    )

    room:throwCard(cids, skillName, player, player)
    for _, p in ipairs(tos) do
      room:setPlayerMark(p, "@huanhuo", 2)
    end
  end,
})

huanhuo:addEffect(fk.BeforePlayCard, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:isAlive() and
      player:getMark("@huanhuo") > 0 and
      table.find(player:getCardIds("h"), function(id) return #Fk:getCardById(id):getAvailableTargets(player) > 0 end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = huanhuo.name
    local room = player.room

    while player:getMark("@huanhuo") > 0 and not data.phase_end do
      local availableCards = table.filter(player:getCardIds("h"),
        function(id) return #Fk:getCardById(id):getAvailableTargets(player) > 0 end
      )

      if #availableCards == 0 then
        return false
      end

      local use = room:askToUseRealCard(
        player,
        {
          pattern = room:tableRandomPick(availableCards, 1),
          skill_name = skillName,
          prompt = "#huanhuo-use",
          extra_data = {
            bypass_times = false,
            extraUse = false,
          },
        }
      )

      if not use then
        data.phase_end = true
      end
    end
  end,
})

huanhuo:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@huanhuo") > 0 and player.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = huanhuo.name
    local room = player.room

    local handsCanDiscard = table.filter(player:getCardIds("h"), function(id) return not player:prohibitDiscard(id) end)
    local equipmentsCanDiscard = table.filter(player:getCardIds("e"), function(id) return not player:prohibitDiscard(id) end)
    if #handsCanDiscard + #equipmentsCanDiscard > 0 then
      room:throwCard(room:tableRandomPick(#handsCanDiscard > 0 and handsCanDiscard or equipmentsCanDiscard), skillName, player, player)
    end

    room:removePlayerMark(player, "@huanhuo")
  end,
})

huanhuo:addEffect(fk.EventPhaseEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("@huanhuo") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@huanhuo", 0)
  end,
})

return huanhuo
