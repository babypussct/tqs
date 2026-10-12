local zujin = fk.CreateSkill{
  name = "zujin",
}

Fk:loadTranslationTable{
  ["zujin"] = "阻进",
  [":zujin"] = "每回合每种牌名限一次，若你未受伤或体力值不为最低，你可以将一张基本牌当【杀】使用或打出；"..
  "若你已受伤，你可以将一张基本牌当【闪】或【无懈可击】使用或打出。",

  ["#zujin-slash"] = "阻进：你可以将一张基本牌当【杀】使用或打出",
  ["#zujin-jink"] = "阻进：你可以将一张基本牌当【闪】或【无懈可击】使用或打出",

  ["$zujin1"] = "静守待援，不可中诱敌之计。",
  ["$zujin2"] = "错估军情，今唯退守狄道矣。",
  ["$zujin3"] = "蜀军远来必疲，今当先发以制。",
}

zujin:addEffect("viewas", {
  mute = true,
  pattern = "slash,jink,nullification",
  prompt = function (self, player)
    if Fk.currentResponsePattern == nil or Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash")) then
      return "#zujin-slash"
    else
      return "#zujin-jink"
    end
  end,
  interaction = function(self, player)
    local all_names = {"slash", "jink", "nullification"}
    local names = player:getViewAsCardNames(zujin.name, all_names, nil, player:getTableMark("zujin-turn"))
    if #names > 0 then
      return UI.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|basic",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = zujin.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    room:addTableMark(player, "zujin-turn", self.interaction.data)
    if self.interaction.data == "slash" then
      player:broadcastSkillInvoke(zujin.name, 3)
      room:notifySkillInvoked(player, zujin.name, "offensive")
    else
      player:broadcastSkillInvoke(zujin.name, table.random{ 1, 2 })
      room:notifySkillInvoked(player, zujin.name, "defensive")
    end
  end,
  enabled_at_play = function(self, player)
    return (not player:isWounded() or table.find(Fk:currentRoom().alive_players, function(p)
        return p.hp < player.hp
      end)) and
      #player:getViewAsCardNames(zujin.name, {"slash"}, nil, player:getTableMark("zujin-turn")) > 0
  end,
  enabled_at_response = function(self, player, response)
    if not player:isWounded() or table.find(Fk:currentRoom().alive_players, function(p)
      return p.hp < player.hp
    end) then
      if #player:getViewAsCardNames(zujin.name, {"slash"}, nil, player:getTableMark("zujin-turn")) > 0 then
        return true
      end
    end
    if player:isWounded() then
      if #player:getViewAsCardNames(zujin.name, {"jink", "nullification"}, nil, player:getTableMark("zujin-turn")) > 0 then
        return true
      end
    end
  end,
  enabled_at_nullification = function (self, player, data)
    return player:isWounded() and #player:getViewAsCardNames(zujin.name, { "nullification" }, nil, player:getTableMark("zujin-turn")) > 0
  end,
})

return zujin
