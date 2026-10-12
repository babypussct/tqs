local haoshi_viewas = fk.CreateSkill {
  name = "m_shi__haoshi&",
}

Fk:loadTranslationTable{
  ["m_shi__haoshi&"] = "好施",
  [":m_shi__haoshi&"] = "你可以将势鲁肃的手牌如你的手牌般使用或打出。",

  ["#m_shi__haoshi&"] = "好施：使用或打出势鲁肃的手牌",
}

haoshi_viewas:addEffect("viewas", {
  pattern = ".",
  prompt = "#m_shi__haoshi&",
  expand_pile = function(self, player)
    local cards = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if table.contains(p:getTableMark("@[list]m_shi__haoshi"), player) then
        table.insertTable(cards, p:getCardIds("h"))
      end
    end
    return cards
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardOwner(to_select) ~= player then
      local card = Fk:getCardById(to_select)
      if Fk.currentResponsePattern == nil then
        return player:canUse(card) and not player:prohibitUse(card)
      else
        return Exppattern:Parse(Fk.currentResponsePattern):match(card)
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    return Fk:getCardById(cards[1])
  end,
  before_use = function (self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.m_shi__haoshi = player.room:getCardOwner(use.card:getEffectiveId())
  end,
  enabled_at_play = function(self, player)
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if table.contains(p:getTableMark("@[list]m_shi__haoshi"), player) and not p:isKongcheng() then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if table.contains(p:getTableMark("@[list]m_shi__haoshi"), player) and not p:isKongcheng() then
        return true
      end
    end
  end,
})

haoshi_viewas:addAI(nil, "vs_skill")

return haoshi_viewas
