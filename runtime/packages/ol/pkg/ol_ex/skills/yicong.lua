
local yicong = fk.CreateSkill {
  name = "ol_ex__yicong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__yicong"] = "义从",
  [":ol_ex__yicong"] = "锁定技，你计算与其他角色的距离-1；若你的体力值小于等于2，其他角色计算与你的距离+1。",

  ["$ol_ex__yicong1"] = "跟着我，一起上！",
  ["$ol_ex__yicong2"] = "防御阵型准备！",
}

yicong:addEffect("distance", {
  correct_func = function(self, from, to)
    local n = 0
    if from:hasSkill(yicong.name) then
      n = -1
    end
    if to:hasSkill(yicong.name) and to.hp <= 2 then
      n = n + 1
    end
    return n
  end,
})

yicong:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(yicong.name)
  end,
  on_refresh = function(self, event, target, player, data)
    if player.hp <= 2 then
      player.room:notifySkillInvoked(player, yicong.name, "defensive")
      player:broadcastSkillInvoke(yicong.name, 2)
    else
      player.room:notifySkillInvoked(player, yicong.name, "offensive")
      player:broadcastSkillInvoke(yicong.name, 1)
    end
  end,
})

return yicong
