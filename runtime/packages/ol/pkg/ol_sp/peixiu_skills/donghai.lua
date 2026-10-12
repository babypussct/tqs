local donghai = fk.CreateSkill {
  name = "peixiu_donghai",
}

Fk:loadTranslationTable {
  ["peixiu_donghai"] = "东海",
  [":peixiu_donghai"] = "你获得此技能后，令一名角色下个摸牌阶段多摸一张牌。",

  ["#peixiu_donghai-choose"] = "东海：选择一名角色，其下个摸牌阶段多摸一张牌",
  ["@@peixiu_donghai"] = "东海",
}

donghai:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and not player.dead and data.skill.name == donghai.name
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = donghai.name,
      prompt = "#peixiu_donghai-choose",
      cancelable = false,
    })
    event:setCostData(self, { tos = to })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addPlayerMark(to, "@@peixiu_donghai", 1)
  end
})

donghai:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@peixiu_donghai") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@@peixiu_donghai")
    player.room:setPlayerMark(player, "@@peixiu_donghai", 0)
  end,
})

return donghai
