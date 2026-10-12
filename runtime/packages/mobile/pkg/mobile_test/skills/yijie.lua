local yijie = fk.CreateSkill {
  name = "yijie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yijie"] = "遗诫",
  [":yijie"] = "锁定技，当你死亡时，将场上所有角色的体力值调整至X（X为场上所有其他角色体力值的平均值，向下取整且至少为1）。",

  ["$yijie1"] = "《传》称师克在和不在众，此言天地和则万物生。",
  ["$yijie2"] = "君臣和则国家平，九族和则家族兴。",
}

yijie:addEffect(fk.Death, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yijie.name, false, true)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = player.room:getOtherPlayers(player)})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      n = n + p.hp
    end
    n = math.max(n // #room:getOtherPlayers(player, false), 1)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and p.hp ~= n then
        if p.hp > n then
          room:loseHp(p, p.hp - n, yijie.name)
        else
          room:recover{
            who = p,
            num = n - p.hp,
            recoverBy = player,
            skillName = yijie.name,
          }
        end
      end
    end
  end,
})

return yijie
