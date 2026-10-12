local dangyi = fk.CreateSkill {
  name = "mobile__dangyi",
  tags = { Skill.Lord, Skill.Permanent },
}

Fk:loadTranslationTable{
  ["mobile__dangyi"] = "荡异",
  [":mobile__dangyi"] = "持恒技，主公技，每回合限一次，当你造成伤害时，你可以令此伤害+1（每局游戏限两次）。",

  ["#mobile__dangyi-invoke"] = "荡异：是否令你对 %dest 造成的伤害+1？（还剩%arg次！）",

  ["$mobile__dangyi1"] = "徒生逆心，未有其力，破之易如反掌！",
  ["$mobile__dangyi2"] = "司马氏江山，自不容怀异之徒！",
}

dangyi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangyi.name) and
      player:usedSkillTimes(dangyi.name, Player.HistoryGame) < 2 and
      player:usedSkillTimes(dangyi.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = dangyi.name,
      prompt = "#mobile__dangyi-invoke::"..data.to.id..":"..(2 - player:usedSkillTimes(dangyi.name, Player.HistoryGame)),
    })
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

dangyi:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local data = ai.room.logic:getCurrentEvent().data._data
    return ai:getBenefitOfEvents(function(logic)
      logic:changeDamage(data, 1)
    end) >= 0
  end,
})

return dangyi
