
local huomo = fk.CreateSkill {
  name = "mobile__huomo",
}

Fk:loadTranslationTable{
  ["mobile__huomo"] = "活墨",
  [":mobile__huomo"] = "你可以将一张黑色非基本牌置于牌堆顶，视为使用一张基本牌（每回合每种牌名限一次）。",

  ["#mobile__huomo"] = "活墨：将一张黑色非基本牌置于牌堆顶，视为使用一张基本牌",

  ["$mobile__huomo1"] = "醉墨淋漓，万夫莫敌！",
  ["$mobile__huomo2"] = "挥毫落纸墨痕新，励军克敌如有神",
}

huomo:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#mobile__huomo",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(huomo.name, all_names, nil, player:getTableMark("mobile__huomo-turn"))
    if #names == 0 then return end
    return UI.CardNameBox { choices = names, all_names = all_names }
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = function (self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.type ~= Card.TypeBasic and card.color == Card.Black
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = huomo.name
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    room:addTableMark(player, "mobile__huomo-turn", use.card.trueName)
    room:moveCards({
      ids = use.card.fake_subcards,
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = huomo.name,
      proposer = player,
      moveVisible = true,
    })
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude() and
      #player:getViewAsCardNames(huomo.name, Fk:getAllCardNames("b"), nil, player:getTableMark("mobile__huomo-turn"))
  end,
})

huomo:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "mobile__huomo-turn", 0)
end)

return huomo
