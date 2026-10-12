local aocai = fk.CreateSkill{
  name = "ld__aocai",
}

Fk:loadTranslationTable{
  ["ld__aocai"] = "傲才",
  [":ld__aocai"] = "当你于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，若你观看的牌中有相同牌名的牌，你可以使用或打出之。",

  ["#ld__aocai"] = "发动 傲才，观看牌堆顶的两张牌，并可以使用或打出其中你需要的基本牌",
  ["#ld__aocai-choose"] = "傲才：选择你需要使用或打出的基本牌",

  ["$ld__aocai1"] = "哼，易如反掌。",
  ["$ld__aocai2"] = "吾主圣明，泽披臣属。",
}

aocai:addEffect("viewas",{
  pattern = ".|.|.|.|.|basic",
  anim_type = "defensive",
  prompt = "#ld__aocai",
  card_filter = Util.FalseFunc,
  view_as = Util.DummyFunc,
  feasible = Util.TrueFunc,
  on_use = function(self, room, cardUseEvent, _, params)
    local player = cardUseEvent.from
    local cards = room:getNCards(2)
    if ((params or {}).is_response) then
      local ids = table.filter(cards, function(cid)
        local card = Fk:getCardById(cid)
        return not player:prohibitResponse(card) and card:matchPattern(params.pattern)
      end)
      cards = room:askToCards(player,{
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = aocai.name,
        pattern = tostring(Exppattern{ id = ids }),
        prompt = "#ld__aocai-choose",
        expand_pile = cards,
        cancelable = true,
      })
      if #cards > 0 then
        ---@type UseCardDataSpec
        local use = {
          from = player,
          tos = {},
          card = Fk:getCardById(cards[1]),
        }
        return use
      end
    else
      --askToUseRealCard 的extra_data.not_passive默认值为true，缺省值需重新配置
      local extra_data = (params or {}).extra_data or {}
      extra_data.not_passive = extra_data.not_passive or false
      local use = room:askToUseRealCard(player, {
        pattern = table.filter(cards, function(cid)
          local card = Fk:getCardById(cid)
          return card:matchPattern(params.pattern)
        end),
        skill_name = aocai.name,
        prompt = "#ld__aocai-choose",
        extra_data = extra_data,
        cancelable = true,
        skip = true,
        expand_pile = cards
      })
      if use then
        return use
      end
    end
    return aocai.name
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return Fk:currentRoom():getCurrent() ~= player
  end,
})

return aocai