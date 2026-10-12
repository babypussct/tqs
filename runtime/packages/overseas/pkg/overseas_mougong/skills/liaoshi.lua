local liaoshi = fk.CreateSkill {
  name = "os_mou__liaoshi",
}

Fk:loadTranslationTable {
  ["os_mou__liaoshi"] = "料势",
  [":os_mou__liaoshi"] = "每回合限一次，你可以将因〖巧变〗获得的牌当【杀】或【闪】使用或打出。",

  ["#os_mou__liaoshi"] = "料势：你可以将一张“巧变”获得的牌当【杀】或【闪】使用或打出",

  ["$os_mou__liaoshi1"] = "",
  ["$os_mou__liaoshi2"] = "",
}

liaoshi:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#os_mou__liaoshi",
  interaction_helper = function(self, player, selected_cards)
    local all_names = { "slash", "fire__slash", "thunder__slash", "jink" }
    local names = player:getViewAsCardNames(liaoshi.name, all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  filter_pattern = function (self, player)
    local cards = table.filter(player:getCardIds("he"), function(c)
      return Fk:getCardById(c):getMark("@@os_mou__qiaobian-inhand") > 0
    end)
    return {
      max_num = 1,
      min_num = 1,
      pattern = tostring(Exppattern{ id = cards }),
    }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = liaoshi.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(liaoshi.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(liaoshi.name, Player.HistoryTurn) == 0
  end,
})

return liaoshi
