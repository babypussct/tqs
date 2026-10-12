local runan = fk.CreateSkill {
  name = "peixiu_runan",
}

Fk:loadTranslationTable {
  ["peixiu_runan"] = "汝南",
  [":peixiu_runan"] = "你获得此技能后，可以令一名角色摸等同于你手牌上限的牌。",

  ["#peixiu_runan-choose"] = "汝南：选择一名角色，其摸%arg张牌",
}

runan:addEffect(fk.EventAcquireSkill, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(runan.name) and data.skill.name == runan.name and
      player:getMaxCards() > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = runan.name,
      prompt = "#peixiu_runan-choose:::"..player:getMaxCards(),
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
    to:drawCards(player:getMaxCards(), runan.name)
  end
})

return runan
