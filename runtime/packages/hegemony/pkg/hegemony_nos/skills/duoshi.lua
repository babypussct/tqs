local duoshi = fk.CreateSkill {
  name = "nos_heg__duoshi",
}

Fk:loadTranslationTable{
  ["nos_heg__duoshi"] = "度势",
  [":nos_heg__duoshi"] = "出牌阶段限四次，你可以将一张红色手牌当【以逸待劳】使用。",

  ["#nos_heg__duoshi"] = "度势：将一张红色手牌当【以逸待劳】使用",

  ["$nos_heg__duoshi1"] = "以今日之大势，当行此计。",
  ["$nos_heg__duoshi2"] = "国之大计，审势为先。",
}

duoshi:addEffect("viewas", {
  anim_type = "control",
  handly_pile = true,
  prompt = "#nos_heg__duoshi",
  times = function(self, player)
    return player.phase == Player.Play and 4 - player:usedSkillTimes(duoshi.name, Player.HistoryPhase) or -1
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|red|^equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("await_exhausted")
    card.skillName = duoshi.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(duoshi.name, Player.HistoryPhase) < 4
  end,
})

return duoshi
