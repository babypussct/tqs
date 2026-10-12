local qishe = fk.CreateSkill {
  name = "qishe",
}

Fk:loadTranslationTable{
  ["qishe"] = "骑射",
  [":qishe"] = "你可以将一张装备牌当【酒】使用；你的手牌上限+X（X为你装备区里的牌数）。",

  ["#qishe"] = "骑射：你可以将一张装备牌当【酒】使用",

  ["$qishe1"] = "诱敌之计已成，吾且拈弓搭箭！",
  ["$qishe2"] = "关羽即至吊桥，既已控弦，如何是好？",
}

qishe:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "analeptic",
  prompt = "#qishe",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("analeptic")
    c.skillName = qishe.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})
qishe:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(qishe.name) then
      return #player:getCardIds("e")
    end
  end,
})

return qishe
