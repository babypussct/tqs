local jiawei = fk.CreateSkill{
  name = "jiawei",
}

Fk:loadTranslationTable{
  ["jiawei"] = "假威",
  [":jiawei"] = "出牌阶段限一次，你可弃置一名角色X张牌（X为你执行过的回合数且不超过你的体力上限），并亮出牌堆顶X+1张牌，"..
    "你获得其中的伤害牌，其获得其中的非伤害牌。若如此做，本回合你使用牌无距离限制。",

  ["#jiawei"] = "假威：弃置一名角色%arg张牌，亮出牌堆顶%arg2张牌，你获得其中的伤害牌，其获得其中的非伤害牌",

  ["$jiawei1"] = "甲胄在身，恕不能施以全礼。",
  ["$jiawei2"] = "往日披巾作盗，今朝簪缨为官。",
}

jiawei:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player, selected_cards, selected_targets)
    local n = math.min(player:getMark(jiawei.name), player.maxHp)
    return "#jiawei:::"..n..":"..(n+1)
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jiawei.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = player:getMark(jiawei.name)
    n = math.min(n, player.maxHp)
    if n > 0 and not target:isNude() then
      if target == player then
        room:askToDiscard(player, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = jiawei.name,
          cancelable = false,
        })
      else
        local cards = room:askToChooseCards(player, {
          target = target,
          min = n,
          max = n,
          flag = "he",
          skill_name = jiawei.name,
        })
        room:throwCard(cards, jiawei.name, target, player)
      end
    end
    local cards = room:getNCards(1 + n)
    room:turnOverCardsFromDrawPile(player, cards, jiawei.name, true)
    room:delay(2000)
    local ids1, ids2 = {}, {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).is_damage_card then
        table.insert(ids1, id)
      else
        table.insert(ids2, id)
      end
    end
    if #ids1 > 0 and not player.dead then
      room:moveCardTo(ids1, Card.PlayerHand, player, fk.ReasonJustMove, jiawei.name, nil, true, player)
    end
    if #ids2 > 0 and not target.dead then
      room:moveCardTo(ids2, Card.PlayerHand, target, fk.ReasonJustMove, jiawei.name, nil, true, target)
    end
    room:cleanProcessingArea(cards)
  end,
})

jiawei:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiawei.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, jiawei.name, 1)
  end,
})

jiawei:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:usedSkillTimes(jiawei.name, Player.HistoryPhase) > 0 and card
  end,
})

jiawei:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  if not is_start then
    local n = #room.logic:getEventsOfScope(GameEvent.Turn, 999, function (e)
      return e.data.who == player
    end, Player.HistoryGame)
    local currentTurn = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if currentTurn and currentTurn.data.who == player then
      n = n - 1
    end
    room:setPlayerMark(player, jiawei.name, n)
  end
end)

return jiawei
