local niwo = fk.CreateSkill{
  name = "os__niwo",
}

Fk:loadTranslationTable{
  ["os__niwo"] = "逆涡",
  [":os__niwo"] = "出牌阶段开始时，你可以选择一名其他角色，选择你与其等量的手牌，选择一项：1.本回合你与其不能使用或打出这些牌；2.你与其交换这些牌，且〖砺锋〗本回合失效。",

  ["#os__niwo-choose"] = "逆涡：你可以选择一名角色，选择双方等量的手牌，选择本回合无法使用或打出或交换",
  ["#os__niwo"] = "逆涡：选择双方等量手牌，本回合不能使用或打出或交换",
  ["os__niwo_cannot_use"] = "本回合你与其不能使用或打出这些牌",
  ["os__niwo_swap"] = "交换这些牌",
  ["@@os__niwo-inhand-turn"] = "逆涡",

  ["$os__niwo1"] = "疲敌而取之以逸，其势易也！",
  ["$os__niwo2"] = "调其心疲其士，则可以静制动，以弱胜强！",
}

Fk:addPoxiMethod{
  name = "os__niwo",
  prompt = "#os__niwo",
  card_filter = Util.TrueFunc,
  feasible = function(selected, data)
    if #selected > 0 and #selected % 2 == 0 then
      return #table.filter(selected, function (id)
        return table.contains(data[1][2], id)
      end) == #table.filter(selected, function (id)
        return table.contains(data[2][2], id)
      end)
    end
  end,
}

niwo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(niwo.name) and player.phase == Player.Play and
      not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__niwo-choose",
      skill_name = niwo.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local extra_data = {}
    local visible_data = {}
    for _, id in ipairs(player:getCardIds("h")) do
      if not player:cardVisible(id) then
        visible_data[tostring(id)] = false
      end
    end
    for _, id in ipairs(to:getCardIds("h")) do
      if not player:cardVisible(id) then
        visible_data[tostring(id)] = false
      end
    end
    if next(visible_data) == nil then visible_data = nil end
    extra_data.visible_data = visible_data
    local cards = room:askToPoxi(player, {
      poxi_type = niwo.name,
      data = {
        { player.general, player:getCardIds("h") },
        { to.general, to:getCardIds("h") },
      },
      extra_data = extra_data,
      cancelable = true,
    })
    if #cards > 0 then
      local choice = room:askToChoice(player, {
        choices = { "os__niwo_cannot_use", "os__niwo_swap" },
        skill_name = niwo.name
      })
      if choice == "os__niwo_cannot_use" then
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id), "@@os__niwo-inhand-turn", 1)
        end
      else
        local my_cards = {}
        for i = #cards, 1, -1 do
          if room:getCardOwner(cards[i]) == player then
            table.insert(my_cards, table.remove(cards, i))
          end
        end
        room:swapCards(player, { { player, my_cards }, { to, cards } }, niwo.name)
        room:invalidateSkill(player, "os__lifengh", "-turn", niwo.name)
      end
    end
  end,
})

niwo:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local subcards = card:isVirtual() and card.subcards or {card.id}
    return #subcards > 0 and
      table.find(subcards, function(id)
        return Fk:getCardById(id):getMark("@@os__niwo-inhand-turn") > 0
      end)
  end,
  prohibit_response = function(self, player, card)
    local subcards = card:isVirtual() and card.subcards or {card.id}
    return #subcards > 0 and
      table.find(subcards, function(id)
        return Fk:getCardById(id):getMark("@@os__niwo-inhand-turn") > 0
      end)
  end,
})

return niwo
