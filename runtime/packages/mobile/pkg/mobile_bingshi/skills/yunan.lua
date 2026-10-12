local yunan = fk.CreateSkill {
  name = "yunan",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["yunan"] = "迂难",
  [":yunan"] = "觉醒技，你的登场势力为魏；当你令一名角色进入濒死状态时，若本轮有角色死亡，你将势力变更为群，"..
  "然后获得或升级技能<a href=':kechang'>〖克昌〗</a>。",

  ["$yunan1"] = "纵有子房之谋，亦难逃谗言中伤。",
  ["$yunan2"] = "此生如履薄冰，一朝错则万劫不复。",
  ["$yunan3"] = "司马氏心狠手毒，不可同甘，只可共苦。",
  ["$yunan4"] = "而今功高震主，岂可坐待其祸。",
}

yunan:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return
      (
        data.killer == player or
        (data.hpLost and data.hpLost.proposer == player)
      ) and
      player:hasSkill(yunan.name) and
      player:usedSkillTimes(yunan.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local death = player.room.logic:getEventsOfScope(GameEvent.Death, 1, function(e)
      local deathData = e.data
      return not (deathData.who:isAlive() or deathData.who.rest > 0)
    end, Player.HistoryRound)

    return #death > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeKingdom(player, "qun", true)
    if player:hasSkill("kechang", true, true) then
      room:setPlayerMark(player, "@kechang_level-noclear", 2)
    else
      room:handleAddLoseSkills(player, "kechang")
    end
  end,
})

return yunan
