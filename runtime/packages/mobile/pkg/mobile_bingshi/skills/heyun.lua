
local heyun = fk.CreateSkill {
  name = "heyun",
}

Fk:loadTranslationTable{
  ["heyun"] = "合韵",
  [":heyun"] = "出牌阶段限两次，你可以选择一名与你有相同技能的角色，然后你失去一个技能并令其摸两张牌。",

  ["#heyun"] = "合韵：失去一个技能，令一名角色摸两张牌",
  ["#heyun-choice"] = "合韵：选择令 %dest 摸两张牌",

  ["$heyun1"] = "江东岂独郎才？曲高亦能和之！",
  ["$heyun2"] = "我有一曲雅乐，随江遥助军威！",
}

heyun:addEffect("active", {
  anim_type = "support",
  prompt = "#heyun",
  card_num = 0,
  target_num = 1,
  interaction = function (self, player)
    return UI.ComboBox { choices = player:getSkillNameList() }
  end,
  times = function (self, player)
    return 2 - player:usedSkillTimes(heyun.name, Player.HistoryPhase)
  end,
  can_use = function (self, player)
    return player:usedSkillTimes(heyun.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and
      table.find(to_select:getSkillNameList(), function (s)
        return table.contains(player:getSkillNameList(), s)
      end)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:handleAddLoseSkills(player, "-" .. self.interaction.data)

    if not target:isAlive() then
      return false
    end

    target:drawCards(2, heyun.name)
  end,
})

return heyun
