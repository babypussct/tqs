local duoshi = fk.CreateSkill {
  name = "m_heg__duoshi",
}

Fk:loadTranslationTable{
  ["m_heg__duoshi"] = "度势",
  [":m_heg__duoshi"] = "出牌阶段限一次，你可以选择一项：1.将一张红色手牌当【以逸待劳】使用；"..
  "2.将三张“节”置入弃牌堆，视为使用一张造成火焰伤害的牌。",

  ["#m_heg__duoshi-await_exhausted"] = "度势：将一张红色手牌当【以逸待劳】使用",
  ["#m_heg__duoshi-fire"] = "度势：将三张“节”置入弃牌堆，视为使用一张造成火焰伤害的牌",

  ["$m_heg__duoshi1"] = "以今日之大势，当行此计。",
  ["$m_heg__duoshi2"] = "国之大计，审势为先。",
}

duoshi:addEffect("viewas", {
  anim_type = "offensive",
  handly_pile = true,
  expand_pile = "$m_heg__qianxun",
  prompt = function (self, player, selected, selected_cards)
    if self.interaction.data == "await_exhausted" then
      return "#m_heg__duoshi-await_exhausted"
    else
      return "#m_heg__duoshi-fire"
    end
  end,
  interaction = function(self, player)
    local all_names = { "await_exhausted" }
    if #player:getPile("$m_heg__qianxun") > 2 then
      table.insertTable(all_names, { "fire__slash", "fire_attack", "burning_camps" })
    end
    local names = player:getViewAsCardNames(duoshi.name, all_names)
    if #names == 0 then return end
    return UI.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data == "await_exhausted" then
      return #selected == 0 and table.contains(player:getHandlyIds(), to_select) and
        Fk:getCardById(to_select).color == Card.Red
    else
      return #selected < 3 and table.contains(player:getPile("$m_heg__qianxun"), to_select)
    end
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == "await_exhausted" then
      if #cards ~= 1 then return end
      local c = Fk:cloneCard("await_exhausted")
      c.skillName = duoshi.name
      c:addSubcard(cards[1])
      return c
    else
      if #cards ~= 3 then return end
      local c = Fk:cloneCard(self.interaction.data)
      c.skillName = duoshi.name
      c:addFakeSubcards(cards)
      return c
    end
  end,
  before_use = function (self, player, use)
    if #use.card.fake_subcards > 0 then
      player.room:moveCardTo(use.card.fake_subcards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, duoshi.name, nil, true, player)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(duoshi.name, Player.HistoryPhase) == 0
  end,
})

return duoshi
