local ailao = fk.CreateSkill {
  name = "peixiu_ailao",
}

Fk:loadTranslationTable {
  ["peixiu_ailao"] = "哀牢",
  [":peixiu_ailao"] = "你获得此技能后，可以令一名角色选择：其弃置两张牌，或其失去1点体力。",

  ["#peixiu_ailao-choose"] = "哀牢：可选择一名角色弃牌或掉血",
  ["#peixiu_ailao-discard"] = "哀牢：弃置两张牌，否则失去1点体力",
}

ailao:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(ailao.name) and data.skill.name == ailao.name
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#peixiu_ailao-choose",
      skill_name = ailao.name,
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

    local cards = room:askToDiscard(to, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = ailao.name,
      cancelable = true,
      prompt = "#peixiu_ailao-discard",
    })
    if #cards == 0 then
      room:loseHp(to, 1, ailao.name)
    end
  end
})

return ailao
