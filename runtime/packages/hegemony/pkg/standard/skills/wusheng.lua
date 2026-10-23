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

-- Use a red card as Slash only when the resulting target exchange is worth
-- the resource.  During a response request the server has already supplied
-- the Slash pattern, so the strategy only chooses the least valuable legal
-- red card and never invents a target.
wusheng:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local skill = Fk.skills[self.skill_name]
    local is_response = ai.command == "AskForResponseCard"
    local requested = type(ai.data) == "table" and ai.data[2] or ""
    local best, best_value = nil, -100000

    for _, id in ipairs(ai:getEnabledCards()) do
      local card = skill:viewAs(ai.player, { id })
      if card and (not is_response or Exppattern:Parse(requested):match(card)) then
        if is_response then
          local value = 1 - (ai:getCardValue(id, "keep_value") or 0) * 0.01
          if value > best_value then best, best_value = { { id }, {} }, value end
        else
          ai:selectSkill(self.skill_name, true)
          ai:selectCard(id, true)
          for targets in self:searchTargetSelections(ai) do
            local value = ai:getBenefitOfEvents(function(logic)
              logic:useCard{ from = ai.player, tos = targets, card = card }
            end)
            value = value - (ai:getCardValue(id, "keep_value") or 0) * 12
            if value > best_value then best, best_value = { { id }, targets }, value end
          end
          ai:unSelectAll()
        end
      end
    end

    if best and (is_response or best_value > 0) then return best, best_value end
  end,
})

return wusheng
