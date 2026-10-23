local aocai = fk.CreateSkill{
  name = "aocai",
}

Fk:loadTranslationTable{
  ["aocai"] = "傲才",
  [":aocai"] = "当你于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，使用或打出其中你需要的牌。",

  ["#aocai"] = "傲才：你可以使用或打出其中你需要的基本牌",

  ["$aocai1"] = "哼，易如反掌。",
  ["$aocai2"] = "吾主圣明，泽披臣属。",
}

aocai:addEffect("viewas", {
  anim_type = "special",
  pattern = ".|.|.|.|.|basic",
  prompt = "#aocai",
  expand_pile = function(self, player)
    local ids = {}
    for i = 1, 2, 1 do
      if i > #Fk:currentRoom().draw_pile then break end
      table.insert(ids, Fk:currentRoom().draw_pile[i])
    end
    return ids
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(Fk:currentRoom().draw_pile, to_select) then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeBasic then
        if Fk.currentResponsePattern == nil then
          return player:canUse(card)
        else
          return Exppattern:Parse(Fk.currentResponsePattern):match(card)
        end
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    return Fk:getCardById(cards[1])
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return Fk:currentRoom().current ~= player and
      #player:getViewAsCardNames(aocai.name, Fk:getAllCardNames("b")) > 0
  end,
})

-- The server already exposes only the two top cards that match the current
-- response pattern.  Prefer the lower-keep-value legal card so Ao Cai does
-- not spend a stronger basic card when either revealed card works.
aocai:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local best, best_value
    for _, id in ipairs(ai:getEnabledCards()) do
      local card = Fk:getCardById(id)
      if card and card.type == Card.TypeBasic then
        local keep_value = ai:getCardValue(id, "keep_value") or 0
        local value = 50 - keep_value
        if not best or value > best_value or (value == best_value and id < best) then
          best, best_value = id, value
        end
      end
    end
    if best then
      return { { best }, {} }, best_value
    end
  end,
})

return aocai
