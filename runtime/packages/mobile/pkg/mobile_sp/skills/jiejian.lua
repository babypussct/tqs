local jiejian = fk.CreateSkill{
  name = "jiejianw",
}

Fk:loadTranslationTable{
  ["jiejianw"] = "节谏",
  [":jiejianw"] = "准备阶段，你可以将任意张手牌交给一名其他角色，令其获得“节谏”标记。每名角色的回合限一次，当“节谏”角色成为其他角色使用"..
  "非装备牌的唯一目标时，你可以将此牌转移给你，然后摸一张牌。“节谏”角色的回合结束时，移除其“节谏”标记，若其体力值不小于你交给其牌时的体力值，"..
  "你摸两张牌。",

  ["#jiejianw-give"] = "节谏：将任意张手牌交给一名角色，其获得“节谏”标记",
  ["@jiejianw"] = "节谏",
  ["#jiejianw-invoke"] = "节谏：是否将对 %dest 使用的%arg转移给你并摸一张牌？",

  ["$jiejianw1"] = "陛下何急一时，今当忍而待机啊。",
  ["$jiejianw2"] = "今权在其门，为日已久，陛下何以为抗。",
  ["$jiejianw3"] = "昔鲁昭公败走失国，陛下因而更宜深虑。",
}

jiejian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiejian.name) and player.phase == Player.Start and
      not player:isKongcheng() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 999,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      skill_name = jiejian.name,
      prompt = "#jiejianw-give",
      cancelable = true,
    })
    if #to > 0 and #cards > 0 then
      event:setCostData(self, {tos = to, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(to, "@jiejianw", tostring(math.max(to.hp, 0)))
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, jiejian.name, nil, false, player)
  end
})
jiejian:addEffect(fk.TargetConfirming, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiejian.name) and target:getMark("@jiejianw") ~= 0 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      data:isOnlyTarget(target) and data.from ~= player and data.card.type ~= Card.TypeEquip and not data.cancelled and
      not data.from:isProhibited(player, data.card) and
      player.room.logic:getCurrentEvent():findParent(GameEvent.Turn) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jiejian.name,
      prompt = "#jiejianw-invoke::"..target.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if data:cancelCurrentTarget() then
      data:addTarget(player)
      player:drawCards(1, jiejian.name)
    end
  end,
})
jiejian:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiejian.name) and target:getMark("@jiejianw") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target.hp >= tonumber(target:getMark("@jiejianw")) then
      player:drawCards(2, jiejian.name)
    end
    room:setPlayerMark(target, "@jiejianw", 0)
  end,
})

return jiejian
