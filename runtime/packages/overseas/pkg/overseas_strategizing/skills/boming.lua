local boming = fk.CreateSkill {
  name = "os__boming",
}

Fk:loadTranslationTable{
  ["os__boming"] = "博名",
  [":os__boming"] = "出牌阶段限两次，你可以将一张牌交给一名其他角色。结束阶段，若其他角色于此回合内获得的牌数大于1，你摸两张牌。",

  ["#os__boming"] = "博名：你可以将一张牌交给一名其他角色",

  ["$os__boming1"] = "先载附从，吾后行即可。",
  ["$os__boming2"] = "诸位速速上船，靖随后便至。",
}

boming:addEffect("active", {
  anim_type = "support",
  prompt = "#os__boming",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) < 2
  end,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  on_use = function(self, room, effect)
    room:moveCardTo(effect.cards, Player.Hand, effect.tos[1], fk.ReasonGive, boming.name, nil, false, effect.from)
  end,
})

boming:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(boming.name) and player.phase == Player.Finish then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.to and move.to ~= player and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
        end
        return n > 1
      end
      end, Player.HistoryTurn)
      return n > 1
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, boming.name)
  end,
})

return boming
