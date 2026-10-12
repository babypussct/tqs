local zaoyun = fk.CreateSkill {
  name = "zaoyun",
}

Fk:loadTranslationTable {
  ["zaoyun"] = "凿运",
  [":zaoyun"] = "出牌阶段限一次，你可选择一名与你势力不同且你至其距离大于1的角色并弃置X张手牌（X为你至其的距离-1），令你至其的距离此回合视为1，然后你对其造成1点伤害。",

  ["#zaoyun-discard"] = "凿运：弃置 %arg 张手牌（你至%src的距离-1）",
  ["#zaoyun"] = "凿运：选择任意张手牌弃置，再选择一名与你势力不同且你至其距离为弃置手牌数+1的角色",
  ["zaoyun_num"] = "弃置%arg张牌",

  ["$zaoyun1"] = "开渠输粮，振军之心，破敌之胆！",
  ["$zaoyun2"] = "兵精粮足，胜局已定！",
}

local H = require "packages.hegemony.util"

zaoyun:addEffect("active", {
  anim_type = "offensive",
  prompt = "#zaoyun",
  can_use = function(self, player)
    return player:usedSkillTimes(zaoyun.name, Player.HistoryPhase) == 0 and player.kingdom ~= "unknown"
  end,
  min_card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Player.Hand and
    not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and H.compareKingdomWith(to_select, player, true)
        and player:distanceTo(to_select) - 1 == #selected_cards and #selected_cards > 0
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not H.compareKingdomWith(to_select, player, true) then return end
    local n = player:distanceTo(to_select) - 1
    if n < 1 then
      return -- { {content = "zaoyun_unable", type = "warning"} }
    elseif n == #selected_cards or #selected_cards == 0 then
      return { { content = "zaoyun_num:::" .. n, type = "normal" } }
    else
      return { { content = "zaoyun_num:::" .. n, type = "warning" } }
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, zaoyun.name, player, player)
    if not player.dead and not target.dead then
      room:setPlayerMark(player, "_zaoyun_distance-turn", target.id)
      room:damage { from = player, to = target, damage = 1, skillName = zaoyun.name }
    end
  end,
})
zaoyun:addEffect("distance", {
  fixed_func = function(self, from, to)
    if from:getMark("_zaoyun_distance-turn") == to.id then
      return 1
    end
  end,
})

return zaoyun
