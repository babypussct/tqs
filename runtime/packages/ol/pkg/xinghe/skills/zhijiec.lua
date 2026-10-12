local zhijiec = fk.CreateSkill {
  name = "zhijiec",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhijiec"] = "直节",
  [":zhijiec"] = "锁定技，每回合结束时，若你此回合使用或打出过牌，且你成为过牌的目标，你对攻击范围内的一名角色造成1点伤害。",

  ["#zhijiec-choose"] = "直节：对一名角色造成1点伤害",

  ["$zhijiec1"] = "今邦国殄瘁，唯世子慎以行正。",
  ["$zhijiec2"] = "校计甲兵，不问风俗，真大负众望！",
}

zhijiec:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhijiec.name) and
      (#player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0 or
      #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return table.contains(e.data.tos, player)
      end, Player.HistoryTurn) > 0 and
      table.find(player.room.alive_players, function (p)
        return player:inMyAttackRange(p)
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return player:inMyAttackRange(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhijiec.name,
      prompt = "#zhijiec-choose",
      cancelable = false,
    })[1]
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = zhijiec.name,
    }
  end,
})

return zhijiec
