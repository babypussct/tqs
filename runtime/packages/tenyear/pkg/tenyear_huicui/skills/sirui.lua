local sirui = fk.CreateSkill {
  name = "sirui",
}

Fk:loadTranslationTable{
  ["sirui"] = "思锐",
  [":sirui"] = "出牌阶段限一次，你可以将一张牌当牌名字数相等的基本牌或普通锦囊牌使用（无距离和次数限制）。",

  ["#sirui"] = "思锐：将一张牌当牌名字数相等的牌使用（无距离和次数限制）",

  ["$sirui1"] = "暑气可借酒气消，此间艳阳最佐酒！",
  ["$sirui2"] = "诸君饮泥而醉，举世唯我独醒！",
}

sirui:addEffect("viewas", {
  prompt = "#sirui",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  interaction_helper = function(self, player, selected_cards)
    if #selected_cards == 0 then return end
    local n = Fk:getCardById(selected_cards[1]):getNameLength()
    local all_names = table.filter(Fk:getAllCardNames("bt"), function(name)
      return Fk:cloneCard(name):getNameLength() == n
    end)
    local names = player:getViewAsCardNames(sirui.name, all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if #cards == 0 or not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, sirui.name, cards)
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(sirui.name, Player.HistoryPhase) == 0
  end,
})

sirui:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, sirui.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, sirui.name)
  end,
})

return sirui
