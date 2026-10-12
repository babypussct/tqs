local jixi = fk.CreateSkill {
  name = "ol_ex__jixi",
}

jixi:addEffect("viewas", {
  anim_type = "control",
  pattern = "snatch",
  prompt = "#ol_ex__jixi",
  expand_pile = "ol_ex__dengai_field",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|ol_ex__dengai_field",
  },
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("snatch")
    c.skillName = jixi.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return #player:getPile("ol_ex__dengai_field") > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and #player:getPile("ol_ex__dengai_field") > 0
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__jixi"] = "急袭",
  [":ol_ex__jixi"] = "你可以将一张“田”当【顺手牵羊】使用。",

  ["#ol_ex__jixi"] = "急袭：你可以将一张“田”当【顺手牵羊】使用",

  ["$ol_ex__jixi1"] = "良田为济，神兵天降！",
  ["$ol_ex__jixi2"] = "明至剑阁，暗袭蜀都！",
}

return jixi