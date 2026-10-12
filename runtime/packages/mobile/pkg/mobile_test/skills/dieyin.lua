local dieyin = fk.CreateSkill {
  name = "dieyin",
}

Fk:loadTranslationTable{
  ["dieyin"] = "叠音",
  [":dieyin"] = "出牌阶段限一次，你可以将武将牌翻至背面朝上并选择一个阶段，你于当前阶段结束后执行此额外阶段。",

  ["$dieyin1"] = "琴音之变，在技更在心。",
  ["$dieyin2"] = "弦震如雷奔，韵转若涡旋。",
}

local phaseList = { "phase_start", "phase_judge", "phase_draw", "phase_play", "phase_discard", "phase_finish" }

dieyin:addEffect("active", {
  prompt = "#dieyin-active",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    return UI.ComboBox { choices = phaseList }
  end,
  can_use = function(self, player)
    return player.faceup and player:usedSkillTimes(dieyin.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    effect.from:turnOver()
    effect.from:gainAnExtraPhase(table.indexOf(phaseList, self.interaction.data) + 1, dieyin.name)
  end,
})

return dieyin
