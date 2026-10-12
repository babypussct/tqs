local donglai = fk.CreateSkill {
  name = "peixiu_donglai",
}

Fk:loadTranslationTable {
  ["peixiu_donglai"] = "东莱",
  [":peixiu_donglai"] = "你获得此技能后，可令一名角色使用的下一张牌无次数和距离限制。",

  ["#peixiu_donglai-choose"] = "东莱：选择一名角色，其使用的下一张牌无次数和距离限制",
  ["@@peixiu_donglai"] = "东莱",
}

donglai:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and not player.dead and data.skill.name == donglai.name
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = donglai.name,
      prompt = "#peixiu_donglai-choose",
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
    room:setPlayerMark(to, "@@peixiu_donglai", 1)
  end
})

donglai:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@peixiu_donglai") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@peixiu_donglai", 0)
    if not data.extraUse then
      player:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
  end,
})

donglai:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("@@peixiu_donglai") > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("@@peixiu_donglai") > 0
  end,
})

return donglai
