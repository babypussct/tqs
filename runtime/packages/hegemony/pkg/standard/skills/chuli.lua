
local chuli = fk.CreateSkill{
  name = "hs__chuli",
}

Fk:loadTranslationTable{
  ["hs__chuli"] = "除疠",
  [":hs__chuli"] = "出牌阶段限一次，你可选择至多三名势力各不相同或未确定势力的其他角色，然后你弃置你和这些角色的各一张牌。被弃置♠牌的角色各摸一张牌。",

  ["#hs__chuli"] = "除疠：选择至多三名势力各不相同或未确定势力的其他角色，弃置你和这些角色的各一张牌",

  ["$hs__chuli1"] = "病去，如抽丝。",
  ["$hs__chuli2"] = "病入膏肓，需下猛药。",
}

local H = require "packages.hegemony.util"

chuli:addEffect("active", {
  prompt = "#hs__chuli",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(chuli.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select ~= player and not to_select:isNude() and #selected < 3 and
      table.every(selected, function(sel) return not H.compareKingdomWith(to_select, sel) end)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.simpleClone(effect.tos)
    table.insert(targets, 1, player)
    room:sortByAction(targets)
    local draw = {}
    for _, tar in ipairs(targets) do
      if not tar:isNude() then
        local c = room:askToChooseCard(player, {
          target = tar,
          flag = "he",
          skill_name = chuli.name,
        })
        room:throwCard({c}, chuli.name, tar, player)
        if Fk:getCardById(c).suit == Card.Spade then
          table.insert(draw, tar)
        end
      end
    end
    for _, tar in ipairs(targets) do
      if table.contains(draw, tar) and not tar.dead then
        tar:drawCards(1, chuli.name)
      end
    end
  end,
})

return chuli
