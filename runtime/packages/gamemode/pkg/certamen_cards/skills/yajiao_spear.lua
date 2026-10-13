local skill = fk.CreateSkill {
  name = "#yajiao_spear_skill",
  attached_equip = "yajiao_spear",
}

Fk:loadTranslationTable{
  ["#yajiao_spear_skill"] = "涯角枪",
}

skill:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and player.room.current ~= player and
      data.card.color == Card.Black and player.room:getCardArea(data.card) == Card.Processing then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.card.color == Card.Black and use.from == player
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, skill.name, nil, true, player)
  end,
})

return skill
