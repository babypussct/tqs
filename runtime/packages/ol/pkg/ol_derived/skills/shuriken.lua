local skill = fk.CreateSkill {
  name = "#shuriken_skill",
  tags = { Skill.Compulsory },
  attached_equip = "shuriken",
}

skill:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.to ~= player and not table.contains(player:getTableMark("shuriken-turn"), data.to)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = {data.to} })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "shuriken-turn", data.to)
    local skills = table.filter(data.to:getSkillNameList(), function (s)
      return data.to:hasSkill(s)
    end)
    if #skills > 0 then
      room:addTableMark(data.to, "@shuriken", room:tableRandomPick(skills))
    end
  end,
})

skill:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@shuriken", 0)
  end,
})

skill:addEffect("invalidity", {
  invalidity_func = function (self, from, s)
    if from:getMark("@shuriken") ~= 0 and s:isPlayerSkill(from) then
      return table.contains(from:getMark("@shuriken"), s:getSkeleton().name)
    end
  end,
})

return skill
