local yangzhou = fk.CreateSkill {
  name = "peixiu_yangzhou",
}

Fk:loadTranslationTable {
  ["peixiu_yangzhou"] = "扬州",
  [":peixiu_yangzhou"] = "你获得此技能后，可以令一名其他角色回复1点体力。",

  ["#peixiu_yangzhou-choose"] = "扬州：选择一名其他角色，令其回复1点体力",
}

yangzhou:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yangzhou.name) and data.skill.name == yangzhou.name and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:isWounded()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isWounded()
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = yangzhou.name,
      prompt = "#peixiu_yangzhou-choose",
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]

    room:recover{
      who = to,
      num = 1,
      recoverBy = player,
      skillName = yangzhou.name,
    }
  end
})

return yangzhou
