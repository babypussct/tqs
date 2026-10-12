
local zhanyi_viewas = fk.CreateSkill {
  name = "os__zhanyi_viewas&"
}

Fk:loadTranslationTable{
  ["os__zhanyi_viewas&"] = "战意",
  [":os__zhanyi_viewas&"] = "你可以将一张基本牌当成任意基本牌使用。",

  ["#os__zhanyi_viewas&"] = "战意：将一张基本牌当成任意基本牌使用",
}

zhanyi_viewas:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#os__zhanyi_viewas&",
  handly_pile = true,
  filter_pattern = function (self, player, card_name, selected)
    return {
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|.|.|basic",
    }
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames("os__zhanyi", all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = "os__zhanyi"
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@os__zhanyi-phase") == "basic"
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@os__zhanyi-phase") == "basic" and not response
  end,
})

return zhanyi_viewas
