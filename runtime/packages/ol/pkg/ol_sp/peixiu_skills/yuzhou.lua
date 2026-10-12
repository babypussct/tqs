local yuzhou = fk.CreateSkill {
  name = "peixiu_yuzhou",
}

Fk:loadTranslationTable {
  ["peixiu_yuzhou"] = "豫州",
  [":peixiu_yuzhou"] = "你获得此技能后，可以进入连环状态，令一名体力值小于你的角色回复1点体力。",

  ["#peixiu_yuzhou-choose"] = "豫州：你可以进入连环状态并选择一名体力值小于你的角色，令其回复1点体力",
}

yuzhou:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yuzhou.name) and data.skill.name == yuzhou.name and
      not player.chained
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p.hp < player.hp and p:isWounded()
    end)
    if #targets == 0 then return false end

    local to
    if #targets == 1 then
      to = targets[1]
    else
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = yuzhou.name,
        prompt = "#peixiu_yuzhou-choose",
      })
      if #tos == 0 then return false end
      to = tos[1]
    end
    event:setCostData(self, { tos = { to } })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    player:setChainState(true)
    if not to.dead then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = yuzhou.name,
      }
    end
  end
})

return yuzhou
