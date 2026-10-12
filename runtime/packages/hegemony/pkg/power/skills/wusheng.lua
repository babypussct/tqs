local H = require "packages.hegemony.util"

local wusheng = fk.CreateSkill{
  name = "xuanhuo__hs__wusheng",
  dynamic_desc = function(self, player)
    if H.hasHegLordSkill(Fk:currentRoom(), player, "shouyue") then
      return "hs__wusheng_shouyue"
    else
      return "xuanhuo__hs__wusheng"
    end
  end,
}
wusheng:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    return H.hasHegLordSkill(Fk:currentRoom(), player, "shouyue") or Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, player,cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = wusheng.name
    c:addSubcard(cards[1])
    return c
  end,
})

wusheng:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and player:hasSkill(self.name) and skill.trueName == "slash_skill" and card.suit == Card.Diamond
  end
})

Fk:loadTranslationTable{
  ["xuanhuo__hs__wusheng"] = "武圣", -- 动态描述
  [":xuanhuo__hs__wusheng"] = "你可将一张红色牌当【杀】使用或打出。你使用<font color='red'>♦</font>【杀】无距离限制。",
}

return wusheng
