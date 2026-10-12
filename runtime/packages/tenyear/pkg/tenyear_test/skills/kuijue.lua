
local kuijue = fk.CreateSkill {
  name = "kuijue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kuijue"] = "愧绝",
  [":kuijue"] = "锁定技，若你的体力上限：大于等于6，你的回合内获得过牌的其他角色无法响应你使用的第一张牌；"..
  "大于等于4，你的回合内你使用的第二张牌若对本回合获得过牌的其他角色使用则不限次数；"..
  "大于等于2，你的攻击范围+3。",

  ["$kuijue1"] = "",
  ["$kuijue2"] = "",
}

kuijue:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuijue.name) and
      player.maxHp >= 6 and player.room:getCurrent() == player and
      #player:getTableMark("UseCardRecord-turn") == 1 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #player:getTableMark("kuijue-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertTableIfNeed(data.disresponsiveList, player:getTableMark("kuijue-turn"))
  end,
})

kuijue:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuijue.name) and
      player.maxHp >= 4 and player.room:getCurrent() == player and
      #player:getTableMark("UseCardRecord-turn") == 2 and
      table.hasIntersection(data.tos, player:getTableMark("kuijue-turn"))
  end,
  on_use = function (self, event, target, player, data)
    data.extraUse = true
  end,
})

kuijue:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(kuijue.name, true) and player.room:getCurrent() == player
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to and move.to ~= player and
        (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
        player.room:addTableMarkIfNeed(player, "kuijue-turn", move.to)
      end
    end
  end,
})

kuijue:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return player:hasSkill(kuijue.name) and card and to and
      #player:getTableMark("UseCardRecord-turn") == 1 and
      table.contains(player:getTableMark("kuijue-turn"), to)
  end,
})

kuijue:addEffect("atkrange", {
  correct_func = function(self, from, to)
    if from:hasSkill(kuijue.name) and from.maxHp >= 2 then
      return 3
    end
  end,
})

kuijue:addAcquireEffect(function (self, player, is_start, src)
  local room = player.room
  room:addSkill("#UseCardRecoder")
  if room:getCurrent() == player then
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.to and move.to ~= player and
          (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
          table.insertIfNeed(mark, move.to)
        end
      end
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "kuijue-turn", mark)
    if player:getMark("#UseCardRecoder") == 0 then
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        if e.data.from == player then
          room:addTableMark(player, "UseCardRecord-turn", e.data.card)
        end
      end, Player.HistoryTurn)
    end
  end
end)

return kuijue
