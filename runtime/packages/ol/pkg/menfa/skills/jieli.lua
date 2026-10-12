local jieli = fk.CreateSkill{
  name = "jieli",
}

Fk:loadTranslationTable{
  ["jieli"] = "诫厉",
  [":jieli"] = "结束阶段，你可以选择一名角色，观看其手牌中牌名字数最大的牌和牌堆顶的X张牌，"..
  "然后你可以交换其中等量的牌（X为你本回合使用过的牌名字数的最大值）。",

  ["#jieli-choose"] = "诫厉：选择一名角色，观看其手牌和牌堆顶的牌并交换等量的牌",
  ["#jieli-exchange"] = "诫厉：你可以交换 %dest 的手牌与牌堆顶等量的牌",

  ["$jieli1"] = "子不学难成其材，子不教难筑其器。",
  ["$jieli2"] = "此子顽劣如斯，必当严加管教。",
}

jieli:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieli.name) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = jieli.name,
      prompt = "#jieli-choose",
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
    local x, y = 0, 0
    local handcards = {}
    for _, id in ipairs(to:getCardIds("h")) do
      y = Fk:getCardById(id):getNameLength(true)
      if x < y then
        x = y
        handcards = {id}
      elseif x == y then
        table.insert(handcards, id)
      end
    end
    local n = 0
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        n = math.max(n, use.card:getNameLength(true))
      end
    end, Player.HistoryTurn)
    local cards = room:getNCards(n)
    local results = room:askToArrangeCards(player, {
      skill_name = jieli.name,
      card_map = {
        "Top", cards,
        "$Hand", handcards,
      },
      prompt = "#jieli-exchange::" .. to.id,
      free_arrange = false,
    })
    handcards = table.filter(cards, function(id)
      return table.contains(results[2], id)
    end)
    room:swapCardsWithPile(to, results[1], handcards, jieli.name, "Top", false, player)
  end,
})

return jieli
