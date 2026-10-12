local yanjing = fk.CreateSkill {
  name = "yanjing",
}

Fk:loadTranslationTable{
  ["yanjing"] = "焰靖",
  [":yanjing"] = "准备阶段，你可以指定一名其他角色，对其造成1点火焰伤害，然后跳过本回合下X个阶段，跳过其下回合第X个阶段（X为其体力值）。",

  ["#yanjing-choose"] = "焰靖：对一名角色造成1点火焰伤害，你跳过其体力值个阶段，其跳过下回合第体力值个阶段",

  ["$yanjing1"] = "",
  ["$yanjing2"] = ""
}

yanjing:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yanjing.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#yanjing-choose",
      skill_name = yanjing.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:damage{
      from = player,
      to = to,
      damage = 1,
      damageType = fk.FireDamage,
      skillName = yanjing.name,
    }
    if to.hp > 0 then
      if not player.dead then
        room:addPlayerMark(player, "yanjing-turn", to.hp)
        room:addTableMarkIfNeed(to, "yanjing_skip", to.hp)
      end
    end
  end,
})

yanjing:addEffect(fk.EventPhaseChanging, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.phase < Player.NotActive and not data.skipped and
      (player:getMark("yanjing-turn") > 0 or player:getMark("yanjing_skip") ~= 0)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("yanjing-turn") > 0 then
      player.room:removePlayerMark(player, "yanjing-turn", 1)
      data.skipped = true
    end
    if player:getMark("yanjing_skip") ~= 0 then
      local phase_events = room.logic:getEventsOfScope(GameEvent.Phase, 999, function (e)
        return e.data.who == player
      end, Player.HistoryTurn)
      if room:removeTableMark(player, "yanjing_skip", 1 + #phase_events) then
        data.skipped = true
      end
    end
  end,
})

yanjing:addEffect(fk.TurnEnd, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "yanjing_skip", 0)
  end,
})

return yanjing
