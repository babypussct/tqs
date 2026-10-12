local chongjian = fk.CreateSkill {
  name = "ofl_heg__chongjian",
  tags = { Skill.DeputyPlace },
}

Fk:loadTranslationTable{
  ["ofl_heg__chongjian"] = "冲坚",
  [":ofl_heg__chongjian"] = "副将技，你可以将一张装备牌当无次数限制的【杀】或【酒】使用或打出。",

  ["#ofl_heg__chongjian"] = "冲坚：将一张装备牌当【杀】或【酒】使用或打出（无次数限制）",

  ["$ofl_heg__chongjian1"] = "尔等良将，于我不堪一击！",
  ["$ofl_heg__chongjian2"] = "此等残兵，破之何其易也！",
}

chongjian:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#ofl_heg__chongjian",
  pattern = "slash,analeptic",
  interaction = function(self, player)
    local all_names = { "slash", "analeptic" }
    local names = player:getViewAsCardNames(chongjian.name, all_names, nil, nil, { bypass_times = true })
    if #names == 0 then return end
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = chongjian.name
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
})

chongjian:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, chongjian.name)
  end,
})

return chongjian
