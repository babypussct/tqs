local kangming = fk.CreateSkill {
  name = "kangming",
}

Fk:loadTranslationTable{
  ["kangming"] = "抗明",
  [":kangming"] = "以你为目标的牌结算结束后，你摸一张牌并选择一项：1.展示一张本回合未以此法展示过的【杀】或普通锦囊牌视为对使用者使用；" ..
  "2.再摸三张牌，此技能失效直到你下回合开始（若此时是你的回合，则改为本回合结束）。",

  ["#kangming-use"] = "抗明：展示其中一张牌视为对 %dest 使用，或点“取消”再摸三张牌且此技能失效",
  ["#kangming-choose"] = "抗明：选择对 %dest 使用【%arg】的副目标",

  ["$kangming1"] = "备者，失翼之虎，丕者，怀匕之狼。",
  ["$kangming2"] = "三足即可久立，何故二虎相争？",
}

kangming:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(kangming.name) and table.contains(data.tos, player) then
      --线上似乎是只能对最后的包含谋骆统的使用事件发动，不知何意
      local events = player.room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      for i = #events, 1, -1 do
        local e = events[i]
        if table.contains(e.data.tos, player) then
          return e.data == data
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(1, kangming.name)
    if player.dead then return end
    if player:isNude() then
      room:setPlayerMark(player, kangming.name, 1)
      room:invalidateSkill(player, kangming.name, "", kangming.name)
      player:drawCards(3, kangming.name)
    else
      local availableCards = table.filter(player:getCardIds("he"), function(id)
        local card = Fk:getCardById(id)
        return
          (card.trueName == "slash" or card:isCommonTrick()) and
          not table.contains(player:getTableMark("kangming_shown-turn"), id) and
          table.contains(card:getAvailableTargets(player, { bypass_distances = true, bypass_times = true}), target)
      end)
      local ids = room:askToCards(
        player,
        {
          min_num = 1,
          max_num = 1,
          pattern = tostring(Exppattern({ id = availableCards })),
          skill_name = kangming.name,
          prompt = "#kangming-use::" .. target.id,
        }
      )
      if #ids > 0 then
        room:addTableMarkIfNeed(player, "kangming_shown-turn", ids[1])
        local card = Fk:getCardById(ids[1])
        player:showCards(ids)
        card = Fk:cloneCard(card.name, card.suit, 0)
        if target:isAlive() and
          table.contains(card:getAvailableTargets(player, { bypass_distances = true, bypass_times = true}), target) then
          local tos = { target }
          local n = card.skill:getMinTargetNum(player)
          if n == 2 then
            local sub_tos = table.filter(room.alive_players, function (p)
              return card.skill:targetFilter(player, p, tos, {}, card, { bypass_distances = true, bypass_times = true })
            end)
            if #sub_tos == 0 then return end
            sub_tos = room:askToChoosePlayers(player, {
              min_num = 1,
              max_num = 1,
              targets = sub_tos,
              skill_name = kangming.name,
              prompt = "#kangming-choose::" .. target.id .. ":" .. card.name,
              cancelable = false,
            })
            table.insert(tos, sub_tos[1])
          end
          room:useCard{
            from = player,
            tos = tos,
            card = card,
            extraUse = true
          }
        end
      else
        room:setPlayerMark(player, kangming.name, 1)
        if room.current == player then
          room:invalidateSkill(player, kangming.name, "-turn")
        else
          room:invalidateSkill(player, kangming.name, "", kangming.name)
        end
        player:drawCards(3, kangming.name)
      end
    end
  end,
})

kangming:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(kangming.name) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, kangming.name, 0)
    room:validateSkill(player, kangming.name, "", kangming.name)
  end,
})

return kangming
