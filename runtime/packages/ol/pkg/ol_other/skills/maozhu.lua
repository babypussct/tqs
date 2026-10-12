local maozhu = fk.CreateSkill{
  name = "nos__maozhu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["nos__maozhu"] = "茂著",
  [":nos__maozhu"] = "锁定技，你使用【杀】的次数上限和手牌上限+X（X为你的技能数）；" ..
  "当你于出牌阶段内首次造成伤害时，若受伤角色的技能数少于你，则此伤害+1。",

  ["$nos__maozhu1"] = "",
  ["$nos__maozhu2"] = "",
}

maozhu:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(maozhu.name) and player.phase == Player.Play and
    player:usedSkillTimes(maozhu.name, Player.HistoryTurn) == 0 and
    #player:getSkillNameList() > #data.to:getSkillNameList() and
    #player.room.logic:getActualDamageEvents(1, function(e)
      return e.data.from == player
    end, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

maozhu:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(maozhu.name) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return #player:getSkillNameList()
    end
  end,
})

maozhu:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(maozhu.name) then
      return #player:getSkillNameList()
    end
  end,
})

return maozhu
