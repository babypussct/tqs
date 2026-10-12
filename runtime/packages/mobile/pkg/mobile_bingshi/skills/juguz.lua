local juguz = fk.CreateSkill {
  name = "juguz",
}

Fk:loadTranslationTable{
  ["juguz"] = "据孤",
  [":juguz"] = "当你成为牌的目标后，若你未受伤，你可以摸两张牌，然后弃置X张牌（X为本回合本技能发动次数）。",

  ["#juguz-invoke"] = "据孤：你可以摸两张牌，然后弃置%arg张牌",

  ["$juguz1"] = "洪为大义，不得不死，今诸君无事空与此祸。",
  ["$juguz2"] = "袁氏无道，所图不轨，洪安可背国而事贼？",
}

juguz:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(juguz.name) and
      not player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = juguz.name,
      prompt = "#juguz-invoke:::"..player:usedSkillTimes(juguz.name, Player.HistoryTurn) + 1,
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, juguz.name)
    if player.dead then return end
    local n = player:usedSkillTimes(juguz.name, Player.HistoryTurn)
    player.room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = juguz.name,
      cancelable = false,
    })
  end,
})

return juguz
