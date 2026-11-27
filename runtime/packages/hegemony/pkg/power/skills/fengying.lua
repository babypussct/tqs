
local fengying = fk.CreateSkill{
  name = "ld__fengying",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ld__fengying"] = "奉迎",
  [":ld__fengying"] = "限定技，出牌阶段，你可以将所有手牌当【挟天子以令诸侯】（无视大势力限制）使用，然后所有与你势力相同的角色将手牌补至其体力上限。",

  ["#ld__fengying"] = "奉迎：将所有手牌当【挟天子以令诸侯】使用！",

  ["$ld__fengying1"] = "二臣恭奉，以迎皇嗣。",
  ["$ld__fengying2"] = "奉旨典选，以迎忠良。",
}

local H = require "packages.hegemony.util"

fengying:addEffect("active", {
  anim_type = "support",
  prompt = "#ld__fengying",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(fengying.name, Player.HistoryGame) == 0 and
      not player:isKongcheng() and not player:prohibitUse(Fk:cloneCard("threaten_emperor"))
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:useVirtualCard("threaten_emperor", player:getCardIds("h"), player, player, fengying.name)
    local targets = table.filter(room:getAlivePlayers(), function(p)
      return H.compareKingdomWith(p, player)
    end)
    for _, p in ipairs(targets) do
      if not p.dead and p.maxHp > p:getHandcardNum() then
        p:drawCards(p.maxHp - p:getHandcardNum(), fengying.name)
      end
    end
  end,
})

return fengying
