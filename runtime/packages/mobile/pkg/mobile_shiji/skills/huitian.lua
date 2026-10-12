local huitian = fk.CreateSkill{
  name = "huitian",
}

Fk:loadTranslationTable{
  ["huitian"] = "回天",
  [":huitian"] = "一名体力值大于你的角色回合结束时，你可摸一张牌并执行一个额外的回合。每轮开始时，若你发动过此技能，你死亡。",

  ["$huitian1"] = "胸怀赤义，敢问苍天争命数！",
  ["$huitian2"] = "但凭天澍，偏离覆地逆乾坤！",
  ["$huitian3"] = "何方后人评说，维自……无愧苍生。",
  ["$huitian4"] = "山河依在，碧血……长流。",
}

huitian:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return not target.dead and target.hp > player.hp and player:hasSkill(huitian.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, huitian.name)
    if not player.dead then
      player:gainAnExtraTurn(true, huitian.name)
    end
  end,
})

huitian:addEffect(fk.RoundStart, {
  anim_type = "negative",
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huitian.name) and player:usedSkillTimes(huitian.name, Player.HistoryGame) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:killPlayer({ who = player })
  end,
})

return huitian
