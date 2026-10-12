local taoluan = fk.CreateSkill {
  name = "changshi__taoluan",
}

Fk:loadTranslationTable{
  ["changshi__taoluan"] = "滔乱",
  [":changshi__taoluan"] = "出牌阶段限一次，你可以将一张牌当任意基本牌或普通锦囊牌使用。",

  ["#changshi__taoluan"] = "滔乱：你可以将一张牌当任意基本牌或普通锦囊牌使用",

  ["$changshi__taoluan1"] = "罗绮朱紫，皆若吾等手中傀儡。",
}

taoluan:addEffect("viewas", {
  pattern = ".",
  prompt = "#changshi__taoluan",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(taoluan.name, all_names, nil, player:getTableMark("@$taoluan"))
    if #names == 0 then return end
    return UI.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = taoluan.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(taoluan.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = Util.FalseFunc,
})

return taoluan
