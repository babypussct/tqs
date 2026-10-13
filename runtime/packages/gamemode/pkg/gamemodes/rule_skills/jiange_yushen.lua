local yushen = fk.CreateSkill{
  name = "jiange__yushen",
}

Fk:loadTranslationTable{
  ["jiange__yushen"] = "熨身",
  [":jiange__yushen"] = "出牌阶段各限一次，你可以令一名已受伤的其他角色回复1点体力并选择：1.视为其对你使用冰【杀】；2.视为你对其使用冰【杀】。",
}

yushen:addEffect("active", {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = function(self, player)
    return "#yushen:::" .. self.interaction.data
  end,
  interaction = function (self, player)
    local all_choices = {"yushen1", "yushen2"}
    local choices = table.filter(all_choices, function(choice)
      return not table.contains(player:getTableMark("jiange__yushen-phase"), choice)
    end)
    return UI.ComboBox { choices = choices , all_choices = all_choices}
  end,
  can_use = function(self, player)
    return #player:getTableMark("jiange__yushen-phase") < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and to_select ~= player and to_select:isWounded() then
      local slash = Fk:cloneCard("ice__slash")
      slash.skillName = yushen.name
      if self.interaction.data == "yushen1" then
        return to_select:canUseTo(slash, player, { bypass_times = true, bypass_distances = true })
      elseif self.interaction.data == "yushen2" then
        return player:canUseTo(slash, to_select, { bypass_times = true, bypass_distances = true })
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "jiange__yushen-phase", self.interaction.data)
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
