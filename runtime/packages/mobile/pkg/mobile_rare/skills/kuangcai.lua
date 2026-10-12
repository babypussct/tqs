local kuangcai = fk.CreateSkill {
  name = "mobile__kuangcai",
}

Fk:loadTranslationTable{
  ["mobile__kuangcai"] = "狂才",
  [":mobile__kuangcai"] = "出牌阶段开始时，你可以令你此阶段内的主动出牌时间变为5秒。若如此做，本阶段你使用牌无距离次数限制，"..
  "且当你使用牌时，你摸一张牌且主动出牌时间-1秒（每阶段至多以此法摸五张牌）。",

  ["$mobile__kuangcai1"] = "博古揽今，信手拈来。",
  ["$mobile__kuangcai2"] = "功名为尘，光阴为金。",
}

kuangcai:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuangcai.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "mobile__kuangcai_timeout-phase", 5)
  end,
})
kuangcai:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(kuangcai.name, Player.HistoryPhase) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "mobile__kuangcai_timeout-phase", 1)
    player:drawCards(1, kuangcai.name)
  end,
})
kuangcai:addEffect(fk.StartPlayCard, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:usedSkillTimes(kuangcai.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.timeout = player:getMark("mobile__kuangcai_timeout-phase")
  end,
})
kuangcai:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:usedSkillTimes(kuangcai.name, Player.HistoryPhase) > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:usedSkillTimes(kuangcai.name, Player.HistoryPhase) > 0
  end,
})

return kuangcai
