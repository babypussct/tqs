local yuxiang = fk.CreateSkill {
  name = "ty__yuxiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__yuxiang"] = "驭象",
  [":ty__yuxiang"] = "锁定技，你计算与其他角色的距离-2；你对距离2以内的角色使用【杀】不可被响应。",
}

yuxiang:addEffect("distance", {
  correct_func = function (self, from, to, card)
    return from:hasSkill(yuxiang.name) and -2 or 0
  end,
})

yuxiang:addEffect(fk.CardUsing, {
  can_trigger = function (self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and player:hasSkill(yuxiang.name)
  end,
  on_use = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p)
      return player:compareDistance(p, 2, "<=")
    end)

    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertTableIfNeed(data.disresponsiveList, targets)
    end
  end,
})

return yuxiang
