
local bishid = fk.CreateSkill {
  name = "bishid",
}

Fk:loadTranslationTable{
  ["bishid"] = "弼士",
  [":bishid"] = "每轮限一次，一名角色的回合结束时，你可以交给其任意张牌，然后若其手牌数与体力值相等，"..
  "其执行一个出牌阶段，此阶段内其使用的第一张牌不能被响应，且每次使用伤害牌时你摸一张牌。",

  ["#bishid-give"] = "弼士：你可以交给 %dest 任意张牌，然后若其手牌数与体力值相等则其执行出牌阶段",

  ["$bishid1"] = "臣面冷，不敢忘彼时先帝遗命。",
  ["$bishid2"] = "臣言厉，不忍将汉家山河付水流。",
}

bishid:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(bishid.name) and target.phase == Player.Finish and
      not target.dead and player:usedSkillTimes(bishid.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = bishid.name,
      prompt = "#bishid-give::" .. target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target.dead then return end
    if not player.dead then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        skill_name = bishid.name,
        pattern = player == target and ".|.|.|equip" or ".",
        prompt = "#bishid-give::"..target.id,
        cancelable = true,
      })
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, bishid.name, nil, false, player)
        if target.dead then return end
      end
    end
    if target.hp == target:getHandcardNum() then
      target:gainAnExtraPhase(Player.Play, bishid.name, true, { from = player })
    end
  end,
})

bishid:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(bishid.name) then
      local phase_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Phase)
      if phase_event and phase_event.data.reason == bishid.name and
        phase_event.data.who == data.from and (phase_event.data.extra_data or {}).from == player then
        if data.card.is_damage_card then
          return true
        end
        local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          return e.data.from == data.from
        end, Player.HistoryPhase)
        return #use_events == 1 and use_events[1].data == data
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use_events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      return e.data.from == data.from
    end, Player.HistoryPhase)
    if #use_events == 1 and use_events[1].data == data then
      data.disresponsiveList = table.simpleClone(room.players)
    end
    if data.card.is_damage_card and not player.dead then
      player:drawCards(1, bishid.name)
    end
  end,
})

return bishid
