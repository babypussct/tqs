local jingce = fk.CreateSkill {
  name = "m_ex__jingce",
}

Fk:loadTranslationTable{
  ["m_ex__jingce"] = "精策",
  [":m_ex__jingce"] = "结束阶段，若本回合因使用或打出进入弃牌堆的牌数不小于你的体力值，你可以摸两张牌。",

  ["$m_ex__jingce1"] = "夺敌所爱，抢占要地！",
  ["$m_ex__jingce2"] = "上将之道，料敌制胜！",
}

jingce:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jingce.name) and player.phase == Player.Finish then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse) and
            move.toArea == Card.DiscardPile then
            n = n + #move.moveInfo
          end
        end
      end, Player.HistoryTurn)
      return n >= player.hp
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, jingce.name)
  end,
})

return jingce
