local fuhui = fk.CreateSkill{
  name = "fuhui",
}

Fk:loadTranslationTable{
  ["fuhui"] = "赋绘",
  [":fuhui"] = "你可将两张手牌当作任意一张基本牌或普通锦囊牌使用（每种牌名每回合限一次），"..
    "若两张手牌的花色组合为本回合首次，你摸一张牌。",

  ["#fuhui"] = "赋绘：转化两张手牌",

  ["$fuhui1"] = "笔落惊鸿，墨染云山。",
  ["$fuhui2"] = "丹青不须拘纸砚，星斗作毫云为宣。",
}

-- 神人AI哥，那我要从组合中反推怎么办啊
-- 直接杀了改新逻辑

local function getCombinationID(a, b)
  if a > b then
    a, b = b, a
  end
  return a * 10 + b
end

local function getCombineStrFromId(id)
  local suit1 = id // 10
  local suit2 = id % 10
  ---@diagnostic disable-next-line
  return Fk:translate(Card.getSuitString({suit=suit1},true)) ..
  ---@diagnostic disable-next-line
    Fk:translate(Card.getSuitString({suit=suit2},true))
end


fuhui:addEffect("viewas", {
  prompt = function(self, player, selected_cards)
    local ret = Fk:translate("#fuhui")
    local used = ""
    local existingCombines = player:getTableMark("fuhui_suits-turn")
    if #existingCombines > 0 then
      local strs = table.map(existingCombines, getCombineStrFromId)
      used = "(已用过：" .. table.concat(strs, "/") .. ")"
    end

    ret = ret .. " " .. used

    if #selected_cards == 2 then
      local id = getCombinationID(Fk:getCardById(selected_cards[1]).suit, Fk:getCardById(selected_cards[2]).suit)
      if not table.contains(existingCombines, id) then
        ret = '<b>此组合为本回合首次！</b><br>' .. ret
      end
    end
    return ret
  end,
  pattern = ".",
  handly_pile = true,
  filter_pattern = {
    max_num = 2,
    min_num = 2,
    pattern = ".|.|.|^equip",
  },
  interaction_helper = function(self, player, selected_cards, selected_targets, extra_data)
    local all_names = Fk:getAllCardNames("bt")
    return UI.CardNameBox {
      choices = player:getViewAsCardNames(fuhui.name, all_names, selected_cards, player:getTableMark("fuhui-turn")),
      all_choices = all_names
    }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 or not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, fuhui.name, cards)
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addTableMark(player, "fuhui-turn", use.card.trueName)

    local existingCombines = player:getTableMark("fuhui_suits-turn")
    local a = Fk:getCardById(use.card.subcards[1]).suit
    local b = Fk:getCardById(use.card.subcards[2]).suit
    local id = getCombinationID(a, b)
    if not table.contains(existingCombines, id) then
      table.insert(existingCombines, id)
      room:setPlayerMark(player, "fuhui_suits-turn", existingCombines)
      use.extra_data = use.extra_data or {}
      use.extra_data.fuhui_draw = true
    end
  end,
  after_use = function (self, player, use)
    if use.extra_data and use.extra_data.fuhui_draw and not player.dead then
      player:drawCards(1, fuhui.name)
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      #player:getViewAsCardNames(fuhui.name, Fk:getAllCardNames("bt"), nil, player:getTableMark("fuhui-turn")) > 0
  end,
  enabled_at_nullification = function (self, player, data)
    return #player:getHandlyIds() > 1 and self:enabledAtResponse(player, false)
  end
})

return fuhui
