local miaoxin = fk.CreateSkill {
  name = "miaoxin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["miaoxin"] = "妙心",
  [":miaoxin"] = "锁定技，当你受到1点伤害后，若〖温宜〗的可发动次数为0，你摸一张牌并令〖温宜〗的可发动次数+1，否则你摸两张牌。。",

  ["$miaoxin1"] = "环佩清音至，温宜入心来。",
  ["$miaoxin2"] = "妾心玲珑透，来解百般愁。",
}

miaoxin:addEffect(fk.Damaged, {
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_use = function(self, event, target, player, data)
    if
      player:hasSkill("wenyi", true) and
      player:usedSkillTimes("wenyi", Player.HistoryGame) >= 1 + player:getMark("wenyi")
    then
      player:drawCards(1, miaoxin.name)
      player.room:addPlayerMark(player, "wenyi")
    else
      player:drawCards(2, miaoxin.name)
    end
  end,
})

return miaoxin
