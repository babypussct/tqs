local xiangyu = fk.CreateSkill {
  name = "os__xiangyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__xiangyu"] = "翔羽",
  [":os__xiangyu"] = "锁定技，你的回合内，每有一名角色失去过牌，本回合你的攻击范围便+1（至多+5）。你使用【杀】指定一名角色为目标时，"..
  "若你与其距离小于你的攻击范围，则其需依次使用两张【闪】才能抵消此【杀】。",

  ["@os__xiangyu-turn"] = "翔羽",

  ["$os__xiangyu1"] = "此战必是有死无生！",
  ["$os__xiangyu2"] = "抢占先机，占尽优势！",
}

xiangyu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiangyu.name) and data.card.trueName == "slash" and
      player:distanceTo(data.to) < player:getAttackRange()
  end,
  on_use = function(self, event, target, player, data)
    data:setResponseTimes(2)
  end,
})

xiangyu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(xiangyu.name) and player.room.current == player then
      for _, move in ipairs(data) do
        if move.from and
          table.find(move.moveInfo, function(info)
            return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
          end) then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from and
        table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) then
        room:addTableMarkIfNeed(player, "os__xiangyu-turn", move.from.id)
      end
    end
    room:setPlayerMark(player, "@os__xiangyu-turn", math.min(5, #player:getTableMark("os__xiangyu-turn")))
  end,
})

xiangyu:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:hasSkill(xiangyu.name) and from:getMark("@os__xiangyu-turn")
  end,
})

xiangyu:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    if room.current == player then
      local mark = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from and
          table.find(move.moveInfo, function(info)
            return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
          end) then
          table.insertIfNeed(mark, move.from.id)
        end
      end
      end, Player.HistoryTurn)
      if #mark > 0 then
        room:setPlayerMark(player, "os__xiangyu-turn", mark)
        room:setPlayerMark(player, "@os__xiangyu-turn", math.min(5, #mark))
      end
    end
  end
end)

return xiangyu
