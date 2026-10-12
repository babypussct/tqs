local sk = fk.CreateSkill {
  name = "#three_strategies_skill",
  tags = { Skill.Compulsory },
  attached_equip = "three_strategies",
}

Fk:loadTranslationTable{
  ["#three_strategies_skill"] = "三略",
}

sk:addEffect("atkrange", {
  correct_func = function (self, from)
    if from:hasSkill(sk.name) then
      return 1
    end
  end,
})
sk:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(sk.name) then
      return 1
    end
  end,
})
sk:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill(sk.name) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
})

return sk
