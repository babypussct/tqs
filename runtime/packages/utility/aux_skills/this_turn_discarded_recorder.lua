local skel = fk.CreateSkill{
  name = "#ThisTurnDiscardedRecorder",
}

skel:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return #data > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local this_turn_discarded = room:getBanner("ThisTurnDiscarded-turn") or {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insertIfNeed(this_turn_discarded, info.cardId)
          end
        end
      else
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DiscardPile then
            table.removeOne(this_turn_discarded, info.cardId)
          end
        end
      end
    end
    if not next(this_turn_discarded) then this_turn_discarded = nil end
    room:setBanner("ThisTurnDiscarded-turn", this_turn_discarded)
  end
})

skel:addEffect(fk.AfterDrawPileShuffle, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setBanner("ThisTurnDiscarded-turn", nil)
  end
})

-- 本回合弃牌堆计数（洗牌后清零）
MarkEnum.ThisTurnDiscarded = "ThisTurnDiscarded-turn"

return skel
