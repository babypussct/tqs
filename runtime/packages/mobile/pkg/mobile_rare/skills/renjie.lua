local renjie = fk.CreateSkill {
  name = "mobile__renjie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__renjie"] = "忍戒",
  [":mobile__renjie"] = "锁定技，每轮限四次，当你需要使用或打出牌以响应一张牌时，若你不为使用者且未响应，你获得一枚“忍”标记。",

  ["@mobile__renjie_ren"] = "忍",

  ["$mobile__renjie1"] = "朝中大小事宜，自有大将军定夺。",
  ["$mobile__renjie2"] = "朝论政事，老夫唯大将军马首是瞻。",
}

renjie:addEffect(fk.AfterAskForCardUse, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(renjie.name) and data.eventData and data.eventData.from ~= player and
      player:usedSkillTimes(renjie.name, Player.HistoryRound) < 4 and
      not (data.result and data.result.from == player)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@mobile__renjie_ren")
  end,
})
renjie:addEffect(fk.AfterAskForCardResponse, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(renjie.name) and data.eventData and data.eventData.from ~= player and
      player:usedSkillTimes(renjie.name, Player.HistoryRound) < 4 and
      not data.result
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@mobile__renjie_ren")
  end,
})
renjie:addEffect(fk.AfterAskForNullification, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(renjie.name) and
      data.eventData and
      data.eventData.from ~= player and
      not data.eventData:isDisresponsive(player) and
      player:usedSkillTimes(renjie.name, Player.HistoryRound) < 4 and
      not (data.result and data.result.from == player)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@mobile__renjie_ren")
  end,
})

return renjie
