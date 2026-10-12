local huimin = fk.CreateSkill {
  name = "ol_ex__huimin",
}

Fk:loadTranslationTable {
  ["ol_ex__huimin"] = "惠民",
  [":ol_ex__huimin"] = "出牌阶段限一次，你可以令你与任意名手牌数不大于体力值的角色各摸一张牌，然后你的手牌上限+X直到你下回合开始"..
  "（X为这些角色数）。",

  ["#ol_ex__huimin"] = "惠民：令任意名手牌数不大于体力值的角色各摸一张牌",

  ["$ol_ex__huimin1"] = "百姓饥馑，吾岂安心见之？",
  ["$ol_ex__huimin2"] = "汉泽惠布，分赈仓廪以济民乏。",
}

huimin:addEffect("active", {
  anim_type = "support",
  prompt = "#ol_ex__huimin",
  max_phase_use_time = 1,
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(huimin.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return to_select == player or to_select.hp >= to_select:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    for _, p in ipairs(effect.tos) do
      if not p.dead then
        p:drawCards(1, huimin.name)
      end
    end
    if not player.dead then
      room:addPlayerMark(player, huimin.name, #effect.tos)
    end
  end,
})

huimin:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, huimin.name, 0)
  end,
})

huimin:addEffect("maxcards", {
  correct_func = function (self, player)
    return player:getMark(huimin.name)
  end,
})

return huimin
