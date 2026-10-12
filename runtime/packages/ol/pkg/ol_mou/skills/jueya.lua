local jueya = fk.CreateSkill{
  name = "jueya",
}

Fk:loadTranslationTable{
  ["jueya"] = "绝崖",
  [":jueya"] = "若你没有手牌，你可以于需要时视为使用一张基本牌（每种牌名限一次）。",

  ["#jueya"] = "绝崖：视为使用一张基本牌",
}

jueya:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#jueya",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    return UI.CardNameBox {
      choices = player:getViewAsCardNames(jueya.name, all_names, {}, player:getTableMark(jueya.name)),
      all_choices = all_names,
    }
  end,
  view_as = function(self)
    if not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, jueya.name)
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, jueya.name, use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    return player:isKongcheng() and
      #player:getViewAsCardNames(jueya.name, Fk:getAllCardNames("b"), nil, player:getTableMark(jueya.name)) > 0
  end,
  enabled_at_response = function(self, player, response)
    if response or not player:isKongcheng() then return end
    return #player:getViewAsCardNames(jueya.name, Fk:getAllCardNames("b"), nil, player:getTableMark(jueya.name)) > 0
  end,
})

return jueya
