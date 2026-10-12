local aocai = fk.CreateSkill{
  name = "ol__aocai",
}

Fk:loadTranslationTable{
  ["ol__aocai"] = "傲才",
  [":ol__aocai"] = "当你于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌（若你没有手牌则改为四张），使用或打出其中你需要的牌。",

  ["#ol__aocai"] = "傲才：你可以使用或打出其中你需要的基本牌",

  ["$ol__aocai1"] = "英才卓越，功盖一国，非我诸葛恪莫属。",
  ["$ol__aocai2"] = "壮士当唱大风歌，宵小之徒能几何？",
}

aocai:addEffect("viewas", {
  anim_type = "special",
  pattern = ".|.|.|.|.|basic",
  prompt = "#ol__aocai",
  expand_pile = function(self, player)
    local n = player:isKongcheng() and 4 or 2
    local ids = {}
    for i = 1, n, 1 do
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
          return player:canUse(card) and not player:prohibitUse(card)
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

return aocai
