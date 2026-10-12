local qingren = fk.CreateSkill {
  name = "qingren"
}

Fk:loadTranslationTable{
  ["qingren"] = "青刃",
  [":qingren"] = "结束阶段，你可以摸X张牌（X为你本回合发动〖翊赞〗的次数）。",

  ["$qingren1"] = "父凭长枪行四海，子承父志卫江山。",
  ["$qingren2"] = "纵至天涯海角，亦当忠义相随。",
}

qingren:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingren.name) and player.phase == Player.Finish and
      player:usedSkillTimes("ty__yizan", Player.HistoryTurn) > 0
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(player:usedSkillTimes("ty__yizan", Player.HistoryTurn), qingren.name)
  end,
})

qingren:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(ai.player, ai.player:usedSkillTimes("ty__yizan", Player.HistoryTurn))
    end) >= 0
  end,
})

return qingren
