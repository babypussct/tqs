local duanliang = fk.CreateSkill{
  name = "m_ex__duanliang",
}

Fk:loadTranslationTable{
  ["m_ex__duanliang"] = "断粮",
  [":m_ex__duanliang"] = "你可以将一张黑色非锦囊牌当【兵粮寸断】使用。你对手牌数不小于你的角色使用【兵粮寸断】无距离限制。",

  ["#m_ex__duanliang"] = "断粮：你可以将一张黑色非锦囊牌当【兵粮寸断】使用",

  ["$m_ex__duanliang1"] = "粮不三载，敌军已犯行军大忌。",
  ["$m_ex__duanliang2"] = "断敌粮秣，此战可胜。",
}

duanliang:addEffect("viewas", {
  anim_type = "control",
  pattern = "supply_shortage",
  prompt = "#m_ex__duanliang",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|black|.|.|basic,equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
})
duanliang:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(duanliang.name) and skill.name == "supply_shortage_skill" and
      to:getHandcardNum() >= player:getHandcardNum()
  end,
})

return duanliang
