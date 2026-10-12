local qinying_viewas = fk.CreateSkill {
  name = "qinying&",
}

Fk:loadTranslationTable{
  ["qinying&"] = "钦英",
  [":qinying&"] = "你可以弃置区域中的一张牌，视为打出一张【杀】。",

  ["#qinying&"] = "你可以弃置区域中的一张牌，视为打出一张【杀】（还剩%arg次！）",
}

qinying_viewas:addEffect("viewas", {
  mute = true,
  pattern = "slash",
  prompt = function (self)
    return "#qinying&:::"..Fk:currentRoom():getBanner("qinying")
  end,
  expand_pile = function (self, player)
    return player:getCardIds("j")
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = function (self, player, to_select, selected)
    if #selected == 0 and not player:prohibitDiscard(to_select) then
      if Fk:currentRoom():getBanner("qinying_prohibit") then
        return not table.contains(Fk:currentRoom():getBanner("qinying_prohibit"), Fk:getCardById(to_select):getTypeString())
      else
        return true
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = "qinying"
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    local banner = room:getBanner("qinying")
    if banner then
      banner = banner -1
      if banner == 0 then
        room:setBanner("qinying", nil)
      else
        room:setBanner("qinying", banner)
      end
    else
      return qinying_viewas.name
    end
    room:throwCard(use.card.fake_subcards, "qinying", player, player)
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function (self, player, response)
    return response and Fk:currentRoom():getBanner("qinying") ~= nil
  end,
})

return qinying_viewas
