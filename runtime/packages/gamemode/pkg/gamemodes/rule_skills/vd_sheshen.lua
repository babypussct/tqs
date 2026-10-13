local sheshen = fk.CreateSkill {
  name = "vd_sheshen",
  tags = { Skill.Compulsory },
  mode_skill = true,
}

Fk:loadTranslationTable{
  ["vd_sheshen"] = "舍身",
  [":vd_sheshen"] = "锁定技，主公处于濒死状态即将死亡时，你令其体力上限+1，回复体力至X点（X为你的体力值），获得你所有牌，然后你死亡。",

  ["$vd_sheshen1"] = "舍身为主，死而无憾！",
  ["$vd_sheshen2"] = "捐躯赴国难，视死忽如归。",
}

sheshen:addEffect(fk.AskForPeachesDone, {
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sheshen.name) and
      target.role == "lord" and target.hp <= 0 and target.dying and not data.ignoreDeath and
      player:usedSkillTimes(sheshen.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(target, 1)
    if target.dead then return end
    if target:isWounded() and target.hp < player.hp then
      room:recover{
        who = target,
        num = player.hp - target.hp,
        recoverBy = player,
        skillName = sheshen.name,
      }
      if target.dead then return end
    end
    if not player:isNude() then
      room:obtainCard(target, player:getCardIds("he"), false, fk.ReasonGive, player)
    end
    if not player.dead then
      room:killPlayer({who = player})
    end
  end,
})

return sheshen
