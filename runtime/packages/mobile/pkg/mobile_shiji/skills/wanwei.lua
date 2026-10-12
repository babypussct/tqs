local wanwei = fk.CreateSkill {
  name = "mobile__wanwei",
}

Fk:loadTranslationTable{
  ["mobile__wanwei"] = "挽危",
  [":mobile__wanwei"] = "每轮限一次，当一名其他角色进入濒死状态时，或出牌阶段内你可以选择一名其他角色，你可以令其回复X+1点体力"..
  "（若不足使其脱离濒死状态，改为回复至1点体力），然后你失去X点体力（X为你的体力值）。",

  ["#mobile__wanwei"] = "挽危：令一名其他角色回复%arg点体力，然后你失去所有体力",
  ["#mobile__wanwei-invoke"] = "挽危：你可以令 %dest 回复%arg点体力，然后你失去所有体力",

  ["$mobile__wanwei1"] = "事已至此，当思后策。",
  ["$mobile__wanwei2"] = "休养生息，无碍徐图天下。",
}

wanwei:addEffect("active", {
  anim_type = "support",
  prompt =function (self, player)
    return "#mobile__wanwei:::"..(player.hp + 1)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(wanwei.name, Player.HistoryRound) == 0
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = player.hp
    room:recover{
      who = target,
      num = n + 1,
      recoverBy = player,
      skillName = wanwei.name,
    }
    if not player.dead then
      room:loseHp(player, n, wanwei.name)
    end
  end
})
wanwei:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wanwei.name) and target ~= player and player:usedSkillTimes(wanwei.name, Player.HistoryRound) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local n = math.max( 1 - target.hp, player.hp + 1)
    if player.room:askToSkillInvoke(player, {
      skill_name = wanwei.name,
      prompt = "#mobile__wanwei-invoke::"..target.id..":"..n
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.max( 1 - target.hp, player.hp + 1)
    room:recover{
      who = target,
      num = n,
      recoverBy = player,
      skillName = wanwei.name,
    }
    if not player.dead then
      room:loseHp(player, player.hp, wanwei.name)
    end
  end,
})

return wanwei
