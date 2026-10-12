local yushen = fk.CreateSkill{
  name = "yushen",
}

Fk:loadTranslationTable{
  ["yushen"] = "熨身",
  [":yushen"] = "出牌阶段限一次，你可以选择一名已受伤的其他角色并选择："..
  "1.令其回复1点体力，其视为对你使用冰【杀】；2.令其回复1点体力，你视为对其使用冰【杀】。",

  ["#yushen"] = "熨身：令一名其他角色回复1点体力，并执行一项效果",
  ["yushen1"] = "视为其对你使用冰【杀】",
  ["yushen2"] = "视为你对其使用冰【杀】",

  ["$yushen1"] = "此心恋卿，尽融三九之冰。",
  ["$yushen2"] = "寒梅傲雪，馥郁三尺之香。",
}

yushen:addEffect("active", {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#yushen",
  times = function(self, player)
    return 1 - player:usedSkillTimes(yushen.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(yushen.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:isWounded()
  end,
  interaction_helper = function(self, player, selected_cards, selected_targets)
    if #selected_targets == 0 then return {} end
    local to_select = selected_targets[1]
    local slash = Fk:cloneCard("ice__slash", nil, nil, yushen.name)
    local arr = {}
    if to_select:canUseTo(slash, player, { bypass_times = true, bypass_distances = true }) then
      table.insert(arr, "yushen1")
    end
    if player:canUseTo(slash, to_select, { bypass_times = true, bypass_distances = true }) then
      table.insert(arr, "yushen2")
    end
    return UI.OptionBox { options = arr, all_options = { "yushen1", "yushen2" } }
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if player:getMark("fenchai") == 0 and player:compareGenderWith(target, true) then
      room:setPlayerMark(player, "fenchai", target.id)
    end
    room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = yushen.name,
    }
    if player.dead or target.dead then return end
    if self.interaction.data == "yushen1" then
      room:useVirtualCard("ice__slash", nil, target, player, yushen.name, true)
    else
      room:useVirtualCard("ice__slash", nil, player, target, yushen.name, true)
    end
  end,
})

return yushen
