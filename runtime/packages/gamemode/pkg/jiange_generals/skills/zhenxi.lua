local zhenxi = fk.CreateSkill {
  name = "jiange__zhenxi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__zhenxi"] = "镇西",
  [":jiange__zhenxi"] = "锁定技，当友方角色受到伤害后，其下个摸牌阶段摸牌数+1。",

  ["@jiange__zhenxi"] = "镇西",
}

zhenxi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhenxi.name) and target:isFriend(player)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "@jiange__zhenxi", 1)
  end,
})

zhenxi:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@jiange__zhenxi") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n + player:getMark("@jiange__zhenxi")
    player.room:setPlayerMark(player, "@jiange__zhenxi", 0)
  end,
})

return zhenxi
