local yongjue = fk.CreateSkill {
  name = "os__yongjue",
}

Fk:loadTranslationTable {
  ["os__yongjue"] = "勇决",
  [":os__yongjue"] = "当一名角色于其回合内使用【杀】结算后，若此【杀】为其于此回合内使用的第一张牌，你获得之。",

  ["$os__yongjue1"] = "能救一个是一个！",
  ["$os__yongjue2"] = "扶幼主，成霸业！",
}

yongjue:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yongjue.name) and
      data.card.trueName == "slash" and player.room:getCurrent() == target and
      player.room:getCardArea(data.card) == Card.Processing then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        return e.data.from == target
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(target, data.card, true, fk.ReasonJustMove)
  end,
})

return yongjue
