local benxi = fk.CreateSkill{
  name = "m_ex__benxi",
}

Fk:loadTranslationTable{
  ["m_ex__benxi"] = "奔袭",
  [":m_ex__benxi"] = "出牌阶段开始时，你可以弃置任意张牌，令你本阶段：计算与其他角色的距离-X、"..
  "使用的下一张基本牌或普通锦囊牌可以额外指定至多X名你计算与其距离为1的角色为目标（X为你以此法弃置的牌数），"..
  "然后此牌结算结束后，若此牌造成过伤害，你摸五张牌。",

  ["#m_ex__benxi-discard"] = "奔袭：弃置数张牌，此阶段使用第一张牌可额外指定等量目标",
  ["#m_ex__benxi-choose"] = "奔袭：可为此【%arg】额外指定至多%arg2个距离为1的目标",
  ["@m_ex__benxi-phase"] = "奔袭减距离",
  ["@@m_ex__benxi-phase"] = "奔袭加目标",

  ["$m_ex__benxi1"] = "战事唯论成败，何惜此等无用之物？",
  ["$m_ex__benxi2"] = "汝等惊弓之鸟，亦难逃吾奔战穷击！",
  ["$m_ex__benxi3"] = "袍染雍凉落日，马过岐山残雪！",
}

benxi:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benxi.name) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 998,
      include_equip = true,
      skill_name = benxi.name,
      cancelable = true,
      pattern = ".",
      prompt = "#m_ex__benxi-discard",
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, benxi.name, "offensive")
    player:broadcastSkillInvoke(benxi.name, 1)
    local cards = event:getCostData(self).cards
    room:throwCard(cards, benxi.name, player)
    if player.dead then return false end
    room:addPlayerMark(player, "@m_ex__benxi-phase", #cards)
    room:addPlayerMark(player, "@@m_ex__benxi-phase")
  end,
})

benxi:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player:getMark("@@m_ex__benxi-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@m_ex__benxi-phase", 0)
    data.extra_data = data.extra_data or {}
    data.extra_data.m_ex__benxi_triggerable = true
  end,
})

benxi:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and (data.extra_data or {}).m_ex__benxi_triggerable and player:hasSkill(benxi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, benxi.name, "offensive")
    player:broadcastSkillInvoke(benxi.name, 2)
    local n = player:getMark("@m_ex__benxi-phase")
    local tos = table.filter(data:getExtraTargets(), function (p)
      return player:distanceTo(p) == 1
    end)
    if #tos == 0 then return false end
    tos = room:askToChoosePlayers(player, {
      targets = tos,
      min_num = 1,
      max_num = n,
      prompt = "#m_ex__benxi-choose:::"..data.card:toLogString()..":"..tostring(n),
      skill_name = benxi.name,
      cancelable = true
    })
    if #tos > 0 then
      table.forEach(tos, function (p)
        data:addTarget(p)
      end)
    end
  end,
})

benxi:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and (data.extra_data or {}).m_ex__benxi_triggerable and data.damageDealt and player:hasSkill(benxi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, benxi.name, "drawcard")
    player:broadcastSkillInvoke(benxi.name, 3)
    player:drawCards(5, benxi.name)
  end,
})

benxi:addEffect("distance", {
  correct_func = function(self, from, to)
    return -from:getMark("@m_ex__benxi-phase")
  end,
})

benxi:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "@m_ex__benxi-phase", 0)
  room:setPlayerMark(player, "@@m_ex__benxi-phase", 0)
end)

return benxi
