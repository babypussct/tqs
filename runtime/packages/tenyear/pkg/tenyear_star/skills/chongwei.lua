local chongwei = fk.CreateSkill {
  name = "chongwei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chongwei"] = "重围",
  [":chongwei"] = "锁定技，你计算与其他角色的距离+3；当你造成伤害后，此数值-1，然后若数值减至0，你回复1点体力，摸体力值张牌，" ..
  "然后“冲阻”增加一个选项，失去此技能。",

  ["@chongwei"] = "重围",

  ["$chongwei1"] = "敌聚如蝗，不可等闲视之。",
  ["$chongwei2"] = "贼围甚密，唯乘夜伺隙。",
}

chongwei:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chongwei.name) and player:getMark("@chongwei") > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chongwei.name
    local room = player.room
    room:removePlayerMark(player, "@chongwei")
    if player:getMark("@chongwei") == 0 then
      room:recover{
        who = player,
        num = 1,
        skillName = skillName,
        recoverBy = player,
      }

      player:drawCards(player.hp, skillName)
      room:setPlayerMark(player, "chongzu_update", 1)
      room:handleAddLoseSkills(player, "-" .. skillName)
    end
  end,
})

chongwei:addEffect("distance", {
  correct_func = function(self, from, to)
    return from:hasSkill(chongwei.name) and from:getMark("@chongwei") or 0
  end,
})

chongwei:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@chongwei", 3)
end)

chongwei:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@chongwei", 0)
end)

return chongwei
