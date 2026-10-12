local chuifeng = fk.CreateSkill {
  name = "ofl_heg__chuifeng",
  tags = { Skill.MainPlace },
}

Fk:loadTranslationTable{
  ["ofl_heg__chuifeng"] = "椎锋",
  [":ofl_heg__chuifeng"] = "主将技，出牌阶段限一次，你可以视为使用一张【决斗】。",

  ["#ofl_heg__chuifeng"] = "椎锋：你可以视为使用一张【决斗】",

  ["$ofl_heg__chuifeng1"] = "率军冲锋，不惧刀枪所阻！",
  ["$ofl_heg__chuifeng2"] = "登锋履刃，何妨马革裹尸！",
}

chuifeng:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#ofl_heg__chuifeng",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("duel")
    card.skillName = chuifeng.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(chuifeng.name, Player.HistoryPhase) == 0
  end,
})

return chuifeng
