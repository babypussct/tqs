local yingji = fk.CreateSkill {
  name = "os__yingji",
}

Fk:loadTranslationTable{
  ["os__yingji"] = "应机",
  [":os__yingji"] = "当你于回合外需要使用/打出一张基本牌或普通锦囊牌时，若你没有手牌，你可摸一张牌并视为使用/打出此牌。",

  ["#os__yingji"] = "应机：你可以摸一张牌，视为使用或打出基本牌或普通锦囊牌",

  ["$os__yingji1"] = "辩适于世，论合于时。",
  ["$os__yingji2"] = "辩言出于口，不失思忖心。",
}

yingji:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic,trick",
  prompt = "#os__yingji",
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(yingji.name, all_names, {})
    return UI.CardNameBox { choices = names, all_choices = all_names}
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  filter_pattern = function (self, player, card_name, selected)
    return {
      min_num = 0,
      max_num = 0,
      pattern = "",
      subcards = {},
    }
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, yingji.name)
  end,
  before_use = function(self, player, use)
    player:drawCards(1, yingji.name)
  end,
  enabled_at_play = function(self, player)
    return Fk:currentRoom().current ~= player and player:isKongcheng()
  end,
  enabled_at_response = function(self, player)
    return Fk:currentRoom().current ~= player and player:isKongcheng()
  end,
})

return yingji
