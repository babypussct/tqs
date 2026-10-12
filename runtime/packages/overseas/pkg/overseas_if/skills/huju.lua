local huju = fk.CreateSkill {
  name = "os__huju",
  tags = { Skill.Compulsory, Skill.Switch },
}

Fk:loadTranslationTable {
  ["os__huju"] = "虎踞",
  [":os__huju"] = "锁定技，转换技：阳，你令〖翦魇〗拥有者的手牌上限+1；阴，你令〖寄志〗拥有者的出牌阶段使用【杀】的次数上限+1。",
}

huju:addEffect("maxcards", {
  correct_func = function (self, player)
    if player:hasSkill("os__jianyanc") then
      return #table.filter(Fk:currentRoom().alive_players, function(t) return t:hasSkill("os__huju") end)
    end
  end
})

huju:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("os__jizhis") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return #table.filter(Fk:currentRoom().alive_players, function(t) return t:hasSkill("os__huju") end)
    end
  end,
})

return huju
