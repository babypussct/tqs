local qinzhou = fk.CreateSkill {
  name = "peixiu_qinzhou",
}

Fk:loadTranslationTable {
  ["peixiu_qinzhou"] = "秦州",
  [":peixiu_qinzhou"] = "你获得此技能后，可选择一名其他角色，其使用的下一张牌对你无效。",

  ["#peixiu_qinzhou-choose"] = "秦州：选择一名其他角色，其使用的下一张牌对你无效",
  ["@@peixiu_qinzhou"] = "秦州",
}

qinzhou:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qinzhou.name) and data.skill.name == qinzhou.name and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = qinzhou.name,
      prompt = "#peixiu_qinzhou-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMarkIfNeed(to, "@@peixiu_qinzhou", player)
  end
})

qinzhou:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.from:getTableMark("@@peixiu_qinzhou"), player)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removeTableMark(data.from, "@@peixiu_qinzhou", player)
    data.nullified = true
  end,
})

return qinzhou
