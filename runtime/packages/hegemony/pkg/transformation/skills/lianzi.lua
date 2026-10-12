local lianzi = fk.CreateSkill{
  name = "lianzi",
  related_skills = { "lord__zhiheng" },
}

Fk:loadTranslationTable{
  ["lianzi"] = "敛资",
  [":lianzi"] = "出牌阶段限一次，你可以弃置一张手牌并展示牌堆顶X张牌（X为吴势力角色装备区内牌数与“烽火”数之和），" ..
    "你获得其中与你弃置的牌类型相同的牌，将其余牌置入弃牌堆，然后若你因此获得至少四张牌，你失去〖敛资〗，获得〖制衡〗。",

  ["#lianzi-active"] = "敛资：你可以弃置一张手牌，然后亮出牌堆顶%arg张牌，获得其中与你弃置的牌类型相同的牌",

  ["$lianzi1"] = "税以足食，赋以足兵。",
  ["$lianzi2"] = "府库充盈，国家方能强盛！",
}

local H = require "packages.hegemony.util"

lianzi:addEffect("active", {
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  prompt = function(self, player)
    local show_num = #player:getPile("lord_fenghuo")
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if H.compareKingdomWith(p, player) then
        show_num = show_num + #p.player_cards[Player.Equip]
      end
    end
    return "#lianzi-active:::" .. show_num
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(lianzi.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select) and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local cardType = Fk:getCardById(effect.cards[1]).type
    room:throwCard(effect.cards, lianzi.name, player)
    if player.dead then return end
    local show_num = #player:getPile("lord_fenghuo")
    for _, p in ipairs(room.alive_players) do
      if H.compareKingdomWith(p, player) then
        show_num = show_num + #p:getCardIds("e")
      end
    end
    if show_num == 0 then return end
    local cards = room:getNCards(show_num)
    room:turnOverCardsFromDrawPile(player, cards, lianzi.name)
    local to_get = table.filter(cards, function (id)
      return Fk:getCardById(id, true).type == cardType
    end)
    if #to_get > 0 then
      room:obtainCard(player, to_get, true, fk.ReasonJustMove)
      if #to_get > 3 then
        room:handleAddLoseSkills(player, "lord__zhiheng|-lianzi", nil)
      end
    end
    room:cleanProcessingArea(cards, lianzi.name)
  end,
})

return lianzi
