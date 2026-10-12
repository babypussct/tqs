local huoji = fk.CreateSkill {
  name = "jj__huoji",
}

Fk:loadTranslationTable{
  ["jj__huoji"] = "火计",
  [":jj__huoji"] = "你可以将一张红色手牌当【火攻】使用（每回合限三次）。",
}

huoji:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "fire_attack",
  prompt = "#huoji",
  times = function(self, player)
    return 3 - player:usedSkillTimes(huoji.name, Player.HistoryTurn)
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|red|^equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = huoji.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(huoji.name, Player.HistoryTurn) < 3
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

return huoji
