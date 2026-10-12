local H = require "packages.hegemony.util"

local alliance = fk.CreateSkill{
  name = "alliance&",
}
alliance:addEffect("active", {
  prompt = "#alliance&",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(alliance.name, Player.HistoryPhase) == 0 and table.find(player:getCardIds("h"), function(id)
      return not not Fk:getCardById(id):hasMark("@@alliance", MarkEnum.CardTempMarkSuffix)
    end)
  end,
  max_card_num = 3,
  min_card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select):hasMark("@@alliance", MarkEnum.CardTempMarkSuffix) and table.contains(player.player_cards[Player.Hand], to_select) and #selected <= 3
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and #selected_cards >= 1 and #selected_cards <= 3 then
      return H.canAlliance(player, to_select)
    end
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local player = effect.from
    local ret = H.compareKingdomWith(target, player, true)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, alliance.name, nil, true, player.id)
    if ret and not player.dead then
      player:drawCards(#effect.cards, alliance.name)
    end
  end
})

Fk:loadTranslationTable{
  ["alliance&"] = "合纵", -- 只要卡牌标记有@@alliance即可
  [":alliance&"] = "出牌阶段限一次，你可将有“合”标记的至多三张手牌交给与你势力不同或未确定势力的一名角色，若你以此法交给与你势力不同的角色牌，你摸等量的牌。",
  ["#alliance&"] = "合纵：你可将至多3张有“合”标记的手牌交给势力不同或无势力的角色，前者你摸等量的牌",
}

return alliance
