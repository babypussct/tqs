local liejie = fk.CreateSkill{
  name = "liejie",
}

Fk:loadTranslationTable{
  ["liejie"] = "烈节",
  [":liejie"] = "当你受到伤害后，你可以弃置至多三张牌并摸等量张牌，然后你可以弃置伤害来源至多X张牌（X为你以此法弃置的红色牌数）。",

  ["#liejie-ask"] = "烈节：你可以弃置至多三张牌并摸等量牌，然后可以弃置 %dest 其中红色牌数的牌",
  ["#liejie-invoke"] = "烈节：你可以弃置至多三张牌并摸等量牌",
  ["#liejie-discard"] = "烈节：你可以弃置 %dest 至多%arg张牌",

  ["$liejie1"] = "头可断，然节不可夺。",
  ["$liejie2"] = "血可流，而志不可改。",
}

liejie:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liejie.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#liejie-invoke"
    if data.from and not data.from.dead then
      prompt = "#liejie-ask::"..data.from.id
    end
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 3,
      include_equip = true,
      skill_name = liejie.name,
      prompt = prompt,
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {data.from}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    local n = #table.filter(cards, function (id)
      return Fk:getCardById(id).color == Card.Red
    end)
    room:throwCard(cards, liejie.name, player, player)
    if player.dead then return end
    player:drawCards(#cards, liejie.name)
    if n > 0 and not player.dead and data.from and not data.from.dead and not data.from:isNude() and
    room:askToSkillInvoke(player, {
      skill_name = liejie.name,
      prompt = "#liejie-discard::"..data.from.id..":"..n,
    }) then
      if data.from == player then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = n,
          include_equip = true,
          skill_name = liejie.name,
          cancelable = false,
        })
      else
        local ids = room:askToChooseCards(player, {
          target = data.from,
          min = 1,
          max = n,
          flag = "he",
          skill_name = liejie.name,
        })
        room:throwCard(ids, liejie.name, data.from, player)
      end
    end
  end,
})

liejie:addAI(Fk.Ltk.AI.newDiscardStrategy {
  choose_cards = function(self, ai)
    local data = ai.room.logic:getCurrentEvent().data._data
    local available_cards = ai:getEnabledCards()
    ai:sortCards(available_cards, "keep_value")
    local ret, benefit = {}, 0
    for i = 1, #available_cards do
      local tmp = ai:getBenefitOfEvents(function(logic)
        logic:moveCardTo(available_cards[i], Card.DiscardPile, nil, fk.ReasonDiscard)
        logic:drawCards(ai.player, 1)
        if data.from and not data.from:isNude() and Fk:getCardById(available_cards[i]).color == Card.Red then
          logic:throwCard(table.random(data.from:getCardIds("he")), self.skill_name, data.from, ai.player)
        end
      end)
      if tmp >= 0 then
        table.insert(ret, available_cards[i])
        benefit = benefit + tmp
        if #ret == 3 then
          break
        end
      end
    end
    if #ret > 0 then
      return ret, benefit
    end
  end,
})

liejie:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
    return ai:getBenefitOfEvents(function(logic)
      logic:throwCard(table.random(target:getCardIds("he")), self.skill_name, target, ai.player)
    end) >= 0
  end,
})

return liejie
