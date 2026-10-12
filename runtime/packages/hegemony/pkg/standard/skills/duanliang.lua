local duanliang = fk.CreateSkill{
  name = "hs__duanliang",
}

Fk:loadTranslationTable{
  ["hs__duanliang"] = "断粮",
  [":hs__duanliang"] = "出牌阶段，你可以将一张黑色基本牌或黑色装备牌当一张无距离限制的【兵粮寸断】使用；" ..
  "若你至目标角色的距离大于2，此技能本回合失效。",

  ["$hs__duanliang1"] = "截其源，断其粮，贼可擒也。",
  ["$hs__duanliang2"] = "人是铁，饭是钢。",
}

duanliang:addEffect("viewas", {
  anim_type = "control",
  pattern = "supply_shortage",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|black|.|.|basic,equip",
  },
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = duanliang.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player, use)
    local targets = use.tos
    if #targets == 0 then return end
    for _, t in ipairs(targets) do
      if player:distanceTo(t) > 2 then
        player.room:invalidateSkill(player, duanliang.name, "-turn")
        break
      end
    end
  end
})

duanliang:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(duanliang.name) and skill.trueName == "supply_shortage_skill"
  end
})

return duanliang
