local shixi = fk.CreateSkill {
  name = "shixi",
}

Fk:loadTranslationTable{
  ["shixi"] = "拾昔",
  [":shixi"] = "你首次使用一个花色的单目标普通锦囊牌时，记录牌名和花色。当你需要使用记录牌时，你可以将对应其一个花色的所有牌置入弃牌堆，视为使用之。",

  ["@$shixi"] = "拾昔",
  ["#shixi"] = "拾昔：将一个花色的所有牌置入弃牌堆，视为使用对应的普通锦囊牌",
  ["#shixi-use"] = "拾昔：将所有%arg牌置入弃牌堆，视为使用【%arg2】",

  ["$shixi1"] = "满枝橘子香，小女窗前贴花黄。",
  ["$shixi2"] = "提裙扑流萤，囊灯一盏照夜读。",
}

shixi:addEffect("viewas", {
  pattern = ".|.|.|.|.|normal_trick",
  prompt = function(self, player, selected_cards, selected)
    if #selected_cards > 0 then
      local card = Fk:getCardById(selected_cards[1])
      return "#shixi-use:::"..card:getSuitString(true)..":"..card.name
    end
    return "#shixi"
  end,
  update_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local dat = self.interaction.data
    self.interaction.spec.UIrequest = table.simpleClone(dat)
    if dat.elemType == "OptionBox" then
      self.interaction.spec.result = self.interaction.spec.result or {}
      self.interaction.spec.result.option = dat.option
    elseif dat.elemType == "ExpandItem" then
      self.interaction.spec.result = self.interaction.spec.result or {}
      if self.interaction.spec.result.name == dat.name then
        self.interaction.spec.result.name = nil
        self.interaction.spec.pendings = {}
      else
        self.interaction.spec.result.name = dat.name
        self.interaction.spec.pendings = { dat.cid }
      end
    end
    self.interaction.data = self.interaction.spec.result
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local refresh_data = {}
    local dat = self.interaction.spec.UIrequest or {}
    if dat.elemType == "OptionBox" then
      local items = {}
      local i = 1
      for _, id in ipairs(player:getTableMark("@$shixi")) do
        local card = Fk:getCardById(id)
        if card:getSuitString(true) == dat.option then
          card = Fk:cloneCard(card.name, Card.NoSuit, 0, shixi.name)
          table.insert(items, {
            prop = {
              type = "card",
              card = card,
              additional_prop = { selectable = player:canUseOrResponseInCurrent(card) }
            },
            name = card.name,
            cid = i,
          })
          i = i + 1
        end
      end
      refresh_data.expandItems = items
    elseif dat.elemType == "ExpandItem" then
      refresh_data.pendings = self.interaction.spec.pendings
    end
    if self.interaction.spec.result == nil then
      local spec = {   ---@class OptionBoxParams
        options = {},
        all_options = {},
      }
      for _, id in ipairs(player:getTableMark("@$shixi")) do
        local c = Fk:getCardById(id)
        table.insert(spec.all_options, c:getSuitString(true))
        local suit = c.suit
        if player:canUseOrResponseInCurrent(Fk:cloneCard(c.name, Card.NoSuit, 0, shixi.name)) and
          table.find(player:getCardIds("he"), function(id2)
            return Fk:getCardById(id2).suit == suit
          end) then
          table.insert(spec.options, c:getSuitString(true))
        end
      end
      refresh_data.optionBox = UI.OptionBox(spec)
    end
    return refresh_data
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = ".",
  },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local dat = self.interaction.data or {}
    if type(dat) ~= "table" or Fk.all_card_types[dat.name] == nil then return end
    local card = Fk:cloneCard(dat.name, Card.NoSuit, 0, shixi.name)
    card:addFakeSubcards(table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id):getSuitString(true) == dat.option
    end))
    return card
  end,
  before_use = function(self, player, use)
    player.room:moveCardTo(use.card.fake_subcards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile,
      shixi.name, nil, true, player)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@$shixi") ~= 0
  end,
  enabled_at_response = function(self, player, response)
    if not response and Fk.currentResponsePattern then
      local names = table.map(player:getTableMark("@$shixi"), function(id)
        return Fk:getCardById(id).trueName
      end)
      if #names > 0 then
        return Exppattern:Parse(table.concat(names, ",")):matchExp(Fk.currentResponsePattern)
      end
    end
  end,
  enabled_at_nullification = Util.FalseFunc,
})

shixi:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(shixi.name) and
      data.card:isCommonTrick() and not data.card.multiple_targets and not data.card.is_passive and
      data.card.suit ~= Card.NoSuit and table.every(player:getTableMark("@$shixi"), function(id)
        return Fk:getCardById(id).suit ~= data.card.suit
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "@$shixi", room:printCard(data.card.name, data.card.suit, 0).id)
  end,
})

return shixi
