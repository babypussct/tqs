local longdan = fk.CreateSkill {
  name = "ol_ex__longdan",
}

Fk:loadTranslationTable{
  ["ol_ex__longdan"] = "龙胆",
  [":ol_ex__longdan"] = "你可以将一张【杀】当【闪】、【闪】当【杀】、【酒】当【桃】、【桃】当【酒】使用或打出。",

  ["#ol_ex__longdan-viewas"] = "龙胆：将一张【杀】当【闪】、【闪】当【杀】、【酒】当【桃】、【桃】当【酒】使用或打出",

  ["$ol_ex__longdan1"] = "哼，有胆就先接我两招！",
  ["$ol_ex__longdan2"] = "龙游沙场，胆战群雄！",
}

longdan:addEffect("viewas", {
  pattern = "slash,jink,peach,analeptic",
  prompt = "#ol_ex__longdan-viewas",
  handly_pile = true,
  filter_pattern = function (self, player, card_name)
    local vs_pattern = {
      max_num = 1,
      min_num = 1,
      pattern = "slash,jink,peach,analeptic",
    }
    if card_name == "slash" then
      vs_pattern.pattern = "jink"
    elseif card_name == "jink" then
      vs_pattern.pattern = "slash"
    elseif card_name == "peach" then
      vs_pattern.pattern = "analeptic"
    elseif card_name == "analeptic" then
      vs_pattern.pattern = "peach"
    end
    return vs_pattern
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    elseif _c.name == "peach" then
      c = Fk:cloneCard("analeptic")
    elseif _c.name == "analeptic" then
      c = Fk:cloneCard("peach")
    else
      return nil
    end
    c.skillName = longdan.name
    c:addSubcard(cards[1])
    return c
  end,
})

longdan:addAI(nil, "vs_skill")

return longdan
