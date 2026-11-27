
local bushi = fk.CreateSkill {
  name = "ld__bushi",
}

Fk:loadTranslationTable {
  ["ld__bushi"] = "布施",
  [":ld__bushi"] = "出牌阶段限一次，你可以获得一个势力所有角色各一张牌，然后将这些牌任意分配给该势力的角色。",

  ["#ld__bushi"] = "布施：选择一名角色，获得所有其势力角色各一张牌，然后将这些牌分配给该势力角色",
  ["#ld__bushi-give"] = "布施：请分配这些牌",

  ["$ld__bushi1"] = "争斗，永远没有赢家。",
  ["$ld__bushi2"] = "和平，永远没有输家。",
}

local H = require "packages.hegemony.util"

bushi:addEffect("active", {
  anim_type = "control",
  prompt = "#ld__bushi",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(bushi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select.kingdom ~= "none"
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local kingdom = H.getKingdom(effect.tos[1])
    local cards = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if H.getKingdom(p) == kingdom and not p:isNude() then
        local card = room:askToChooseCard(player, {
          target = p,
          flag = p == player and "e" or "he",
          skill_name = bushi.name,
        })
        if card then
          table.insert(cards, card)
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, bushi.name, nil, false, player)
          if player.dead then return end
        end
      end
    end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    local targets = table.filter(room:getAlivePlayers(false), function (p)
      return H.getKingdom(p) == kingdom
    end)
    if #targets == 0 then return end
    room:askToYiji(player, {
      targets = targets,
      cards = cards,
      skill_name = bushi.name,
      min_num = #cards,
      max_num = #cards,
      prompt = "#ld__bushi-give",
    })
  end,
})

return bushi
