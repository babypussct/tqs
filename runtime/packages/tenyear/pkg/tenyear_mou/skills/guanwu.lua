local guanwu = fk.CreateSkill {
  name = "guanwu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["guanwu"] = "冠武",
  [":guanwu"] = "锁定技，回合开始时，你从场上、弃牌堆或牌堆中获得【青龙偃月刀】。本轮你每使用两张【杀】，你本轮使用的【杀】伤害+1。",

  ["$guanwu1"] = "某今既来，便敢独去。",
  ["$guanwu2"] = "汝无霸王之姿，安敢仿宴鸿门！",
}

guanwu:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(guanwu.name) then
      if table.find(table.connect(player.room.draw_pile, player.room.discard_pile), function(id)
            return Fk:getCardById(id).name == "blade"
          end) then
        return true
      else
        return table.find(player.room.alive_players, function(p)
          return table.find(p:getCardIds("ej"), function(id)
            return Fk:getCardById(id).name == "blade"
          end) ~= nil
        end)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local moves = {}
    local cards = table.filter(table.connect(room.draw_pile, room.discard_pile), function(id)
      return Fk:getCardById(id).name == "blade"
    end)
    if #cards > 0 then
      table.insert(moves, {
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        moveVisible = true,
        skillName = guanwu.name,
      })
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      cards = table.filter(p:getCardIds("ej"), function(id)
        return Fk:getCardById(id).name == "blade"
      end)
      if #cards > 0 then
        table.insert(moves, {
          ids = cards,
          from = p,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          moveVisible = true,
          skillName = guanwu.name,
        })
      end
    end
    room:moveCards(table.unpack(moves))
  end,
})

guanwu:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guanwu.name) and
      data.card and data.card.trueName == "slash" and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        return e.data.from == player and e.data.card.trueName == "slash"
      end, Player.HistoryRound) > 1
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      return e.data.from == player and e.data.card.trueName == "slash"
    end, Player.HistoryRound)
    data.damage = (data.damage or 0) + (n // 2)
  end,
})


return guanwu
