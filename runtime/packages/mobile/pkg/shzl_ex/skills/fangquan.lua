local fangquan = fk.CreateSkill{
  name = "m_ex__fangquan",
}

Fk:loadTranslationTable{
  ["m_ex__fangquan"] = "放权",
  [":m_ex__fangquan"] = "你可以跳过出牌阶段，若如此做，本回合你的手牌上限等于你的体力上限，且本回合结束后，你可以弃置一张手牌，令一名其他角色"..
  "获得一个额外回合。",

  ["$m_ex__fangquan1"] = "爱卿自行定夺便是。",
  ["$m_ex__fangquan2"] = "北伐事重，相父全权处理即可。",
}

fangquan:addEffect(fk.EventPhaseChanging, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fangquan.name) and data.phase == Player.Play and not data.skipped
  end,
  on_use = function (self, event, target, player, data)
    data.skipped = true
  end,
})
fangquan:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedEffectTimes(fangquan.name, Player.HistoryTurn) > 0 and
      not player.dead and not player:isKongcheng() and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      skill_name = fangquan.name,
      prompt = "#fangquan-choose",
      cancelable = true,
      will_throw = true,
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, fangquan.name, "support")
    room:throwCard(event:getCostData(self).cards, fangquan.name, player, player)
    local to = event:getCostData(self).tos[1]
    if not to.dead then
      to:gainAnExtraTurn(true, fangquan.name)
    end
  end,
})
fangquan:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:usedEffectTimes(fangquan.name, Player.HistoryTurn) > 0 then
      return player.maxHp
    end
  end,
})

return fangquan
