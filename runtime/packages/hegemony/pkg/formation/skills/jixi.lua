local jixi = fk.CreateSkill{
  name = "ld__jixi",
  tags = { Skill.MainPlace } ,
}

Fk:loadTranslationTable{
  ["ld__jixi"] = "急袭",
  [":ld__jixi"] = "主将技，你计算体力上限时减少一个单独的阴阳鱼。你可以将一张“田”当【顺手牵羊】使用。",

  ["#ld__jixi"] = "急袭：你可以将一张“田”当【顺手牵羊】使用",

  ["$ld__jixi1"] = "谁占到先机，谁就胜了。",
  ["$ld__jixi2"] = "哪里走！！",
}

jixi:addEffect("viewas", {
  anim_type = "control",
  pattern = "snatch",
  prompt = "#ld__jixi",
  expand_pile = "ld__dengai_field",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|ld__dengai_field",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("snatch")
    card.skillName = jixi.name
    card:addSubcards(cards)
    return card
  end,
  enabled_at_play = function(self, player)
    return #player:getPile("ld__dengai_field") > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and #player:getPile("ld__dengai_field") > 0
  end,
})

return jixi
