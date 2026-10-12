local xuzhou = fk.CreateSkill {
  name = "peixiu_xuzhou",
}

Fk:loadTranslationTable {
  ["peixiu_xuzhou"] = "徐州",
  [":peixiu_xuzhou"] = "你获得此技能后，可以指定一名其他角色，其于其的回合外使用牌后摸一张牌。",

  ["#peixiu_xuzhou-choose"] = "徐州：选择一名其他角色，其回合外使用牌后摸一张牌",
  ["@@peixiu_xuzhou"] = "徐州",
}

xuzhou:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xuzhou.name) and data.skill.name == xuzhou.name and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = xuzhou.name,
      prompt = "#peixiu_xuzhou-choose",
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addPlayerMark(to, "@@peixiu_xuzhou", 1)
  end
})

xuzhou:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@peixiu_xuzhou") > 0
      and player.room:getCurrent() ~= player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("@@peixiu_xuzhou"), xuzhou.name)
  end,
})

xuzhou:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@@peixiu_xuzhou", 0)
end)

return xuzhou
