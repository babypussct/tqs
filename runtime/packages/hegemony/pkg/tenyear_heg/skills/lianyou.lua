local lianyou = fk.CreateSkill{
  name = "ty_heg__lianyou",
  related_skills = { "ty_heg__xinghuo" },
}

Fk:loadTranslationTable{
  ["ty_heg__lianyou"] = "莲佑",
  [":ty_heg__lianyou"] = "当你死亡时，你可以令一名其他角色获得〖兴火〗。",

  ["#ty_heg__lianyou-choose"] = "莲佑：选择一名角色，其获得“兴火”。",
}

lianyou:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianyou.name, false, true)
      and table.find(player.room.alive_players, function(p)
        return not p:hasSkill("xinghuo")
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:hasSkill("xinghuo")
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_heg__lianyou-choose",
      skill_name = lianyou.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:handleAddLoseSkills(to, "ty_heg__xinghuo")
  end,
})

return lianyou
