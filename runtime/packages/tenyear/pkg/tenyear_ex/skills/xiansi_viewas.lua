local xiansi_viewas = fk.CreateSkill {
  name = "ty_ex__xiansi&",
}

Fk:loadTranslationTable{
  ["ty_ex__xiansi&"] = "陷嗣",
  [":ty_ex__xiansi&"] = "当你需使用【杀】时，你可以移去刘封的两张“逆”，视为对其使用一张【杀】。",

  ["#ty_ex__xiansi&"] = "陷嗣：你可以移去刘封的两张“逆”，视为对其使用一张【杀】",
}

xiansi_viewas:addEffect("viewas", {
  mute = true,
  pattern = "slash",
  prompt = "#ty_ex__xiansi&",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  expand_pile = function (self, player)
    local ids = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("ty_ex__xiansi") and #p:getPile("ty_ex__xiansi_ni") > 1 then
        table.insertTable(ids, p:getPile("ty_ex__xiansi_ni"))
      end
    end
    return ids
  end,
  card_filter = function (self, player, to_select, selected)
    if #selected < 2 then
      local owner = Fk:currentRoom():getCardOwner(to_select)
      return owner and owner ~= player and owner:hasSkill("ty_ex__xiansi") and
        table.contains(owner:getPile("ty_ex__xiansi_ni"), to_select)
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = xiansi_viewas.name
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
  ---@type ServerPlayer
    local src = room:getCardOwner(use.card.fake_subcards[1])
    if src == nil then return "" end
    src:broadcastSkillInvoke("ty_ex__xiansi")
    room:notifySkillInvoked(src, "ty_ex__xiansi", "negative")
    room:moveCardTo(use.card.fake_subcards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, "ty_ex__xiansi", nil, true, player)
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("ty_ex__xiansi") and #p:getPile("ty_ex__xiansi_ni") > 1
    end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("ty_ex__xiansi") and #p:getPile("ty_ex__xiansi_ni") > 1
    end)
  end,
})

xiansi_viewas:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and table.contains(card.skillNames, xiansi_viewas.name) and to and
      not (to:hasSkill("ty_ex__xiansi") and #to:getPile("ty_ex__xiansi_ni") > 1)
  end,
})

return xiansi_viewas
