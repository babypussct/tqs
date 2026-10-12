local bingzhou = fk.CreateSkill {
  name = "peixiu_bingzhou",
}

Fk:loadTranslationTable {
  ["peixiu_bingzhou"] = "并州",
  [":peixiu_bingzhou"] = "你获得此技能后，可以视为使用一张【决斗】。",

  ["#peixiu_bingzhou-invoke"] = "并州：是否视为使用一张【决斗】？",
}

bingzhou:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(bingzhou.name) and data.skill.name == bingzhou.name
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "duel",
      skill_name = bingzhou.name,
      prompt = "#peixiu_bingzhou-invoke",
      cancelable = true,
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end
})

return bingzhou
