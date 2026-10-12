local skill = fk.CreateSkill {
  name = "#eq_sanshou_skill",
  attached_equip = "eq_sanshou",
}

skill:addEffect(fk.DetermineDamageInflicted, {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cards, skill.name)
    local mark = player:getTableMark("eq_sanshou-turn")
    if #mark ~= 3 then
      mark = {0, 0, 0}
    end
    if not table.every(mark, function (value)
      return value == 1
    end) and
      player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true) ~= nil then
      local mark_change = false
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if mark[use.card.type] == 0 then
          mark_change = true
          mark[use.card.type] = 1
        end
      end, Player.HistoryTurn)
      if mark_change then
        room:setPlayerMark(player, "eq_sanshou-turn", mark)
      end
    end
    local yes = false
    for _, id in ipairs(cards) do
      if mark[Fk:getCardById(id).type] == 0 then
        room:setCardEmotion(id, "judgegood")
        yes = true
      else
        room:setCardEmotion(id, "judgebad")
      end
    end
    if yes then
      data:preventDamage()
    end
    room:delay(1000)
    room:cleanProcessingArea(cards)
  end,
})

return skill
