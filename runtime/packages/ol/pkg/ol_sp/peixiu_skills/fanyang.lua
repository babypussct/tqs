local fanyang = fk.CreateSkill {
  name = "peixiu_fanyang",
}

Fk:loadTranslationTable {
  ["peixiu_fanyang"] = "范阳",
  [":peixiu_fanyang"] = "你获得此技能后，可以对攻击范围内的一名角色造成1点伤害。",

  ["#peixiu_fanyang-choose"] = "范阳：选择攻击范围内的一名角色，对其造成1点伤害",
}

fanyang:addEffect(fk.EventAcquireSkill, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fanyang.name) and
      data.skill.name == fanyang.name and
      table.find(player.room.alive_players, function (p)
        return player:inMyAttackRange(p)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return player:inMyAttackRange(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = fanyang.name,
      prompt = "#peixiu_fanyang-choose",
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
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = fanyang.name,
    }
  end
})

return fanyang
