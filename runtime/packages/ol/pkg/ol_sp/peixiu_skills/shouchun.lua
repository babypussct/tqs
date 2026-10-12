local shouchun = fk.CreateSkill {
  name = "peixiu_shouchun",
}

Fk:loadTranslationTable {
  ["peixiu_shouchun"] = "寿春",
  [":peixiu_shouchun"] = "你获得此技能后，可令一名角色加1点体力上限。",

  ["#peixiu_shouchun-choose"] = "寿春：选择一名角色，令其加1点体力上限",
}

shouchun:addEffect(fk.EventAcquireSkill, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shouchun.name) and data.skill.name == shouchun.name
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = shouchun.name,
      prompt = "#peixiu_shouchun-choose",
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:changeMaxHp(to, 1)
  end
})

return shouchun
