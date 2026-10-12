local zhilu = fk.CreateSkill{
  name = "qin__zhilu",
}

Fk:loadTranslationTable{
  ["qin__zhilu"] = "指鹿",
  [":qin__zhilu"] = "你可以将一张红色/黑色手牌当【闪】/【杀】使用或打出。",

  ["#qin__zhilu"] = "指鹿：你可以将一张红色手牌当【闪】、黑色手牌当【杀】使用或打出",

  ["$qin__zhilu"] = "看清楚了，这可是马。",
}

zhilu:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#qin__zhilu",
  handly_pile = true,
  filter_pattern = function (self, player, card_name)
    local vs_pattern = {
      max_num = 1,
      min_num = 1,
      pattern = ".|.|.|^equip",
    }
    if card_name == "slash" then
      vs_pattern.pattern = ".|.|black|^equip"
    elseif card_name == "jink" then
      vs_pattern.pattern = ".|.|red|^equip"
    end
    return vs_pattern
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.color == Card.Red then
      c = Fk:cloneCard("jink")
    elseif _c.color == Card.Black then
      c = Fk:cloneCard("slash")
    else
      return nil
    end
    c.skillName = zhilu.name
    c:addSubcard(cards[1])
    return c
  end,
})

return zhilu
