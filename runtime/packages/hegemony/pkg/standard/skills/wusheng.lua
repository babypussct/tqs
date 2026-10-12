local H = require "packages.hegemony.util"

local wusheng = fk.CreateSkill{
  name = "hs__wusheng",
  dynamic_desc = function(self, player)
    if H.hasHegLordSkill(Fk:currentRoom(), player, "shouyue") then
      return "hs__wusheng_shouyue"
    else
      return "hs__wusheng"
    end
  end,
}

Fk:loadTranslationTable{
  ["hs__wusheng"] = "武圣",
  [":hs__wusheng"] = "你可以将一张红色牌当【杀】使用或打出。你使用的<font color='red'>♦</font>【杀】无距离限制。",

  [":hs__wusheng_shouyue"] = "你可以将一张牌当【杀】使用或打出。你使用的<font color='red'>♦</font>【杀】无距离限制。",

  ["#hs__wusheng"] = "武圣：将一张牌当【杀】使用或打出",

  ["$hs__wusheng1"] = "关羽在此，尔等受死！",
  ["$hs__wusheng2"] = "看尔乃插标卖首！",
}

wusheng:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#hs__wusheng",
  filter_pattern = function (self, player, card_name, selected)
    if H.hasHegLordSkill(Fk:currentRoom(), player, "shouyue") then
      return {
        min_num = 1,
        max_num = 1,
        pattern = ".",
      }
    else
      return {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|red",
      }
    end
  end,
  handly_pile = true,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = wusheng.name
    c:addSubcards(cards)
    return c
  end,
})

wusheng:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(wusheng.name) and card and card.trueName == "slash" and card.suit == Card.Diamond
  end
})

return wusheng
