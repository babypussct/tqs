local paoxiao = fk.CreateSkill {
  name = "os_ex__paoxiao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os_ex__paoxiao"] = "咆哮",
  [":os_ex__paoxiao"] = "锁定技，你使用【杀】无次数限制。你的出牌阶段，若你于当前阶段使用过【杀】，你于此阶段使用【杀】无距离限制。",

  ["$os_ex__paoxiao1"] = "喝啊~",
  ["$os_ex__paoxiao2"] = "今，必斩汝马下！",
}

paoxiao:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return player:hasSkill(paoxiao.name) and card and card.trueName == "slash"
  end,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(paoxiao.name) and player.phase == Player.Play and card and card.trueName == "slash" and
      player:getMark("os_ex__paoxiao_slash-phase") > 0
  end,
})

paoxiao:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(paoxiao.name, true) and
      data.card.trueName == "slash" and player.phase == Player.Play and
      player:getMark("os_ex__paoxiao_slash-phase") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "os_ex__paoxiao_slash-phase", 1)
  end,
})

paoxiao:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(paoxiao.name) and
      data.card.trueName == "slash" and
      player:usedCardTimes("slash") > 1
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(paoxiao.name)
    player.room:doAnimate("InvokeSkill", {
      name = paoxiao.name,
      player = player.id,
      skill_type = "offensive",
    })
  end,
})

return paoxiao
