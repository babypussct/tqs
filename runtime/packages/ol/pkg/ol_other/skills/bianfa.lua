local bianfa = fk.CreateSkill{
  name = "qin__bianfa",
}

Fk:loadTranslationTable{
  ["qin__bianfa"] = "变法",
  [":qin__bianfa"] = "出牌阶段限一次，你可以将一张普通锦囊牌当<a href=':shangyang_reform'>【商鞅变法】</a>使用。",

  ["#qin__bianfa"] = "变法：你可以将一张普通锦囊牌当【商鞅变法】使用",

  ["$qin__bianfa"] = "前世不同教，何古之法？",
}

bianfa:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#qin__bianfa",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|normal_trick",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("shangyang_reform")
    c.skillName = bianfa.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(bianfa.name, Player.HistoryPhase) == 0
  end,
})

return bianfa
