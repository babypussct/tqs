local wenxi = fk.CreateSkill {
  name = "peixiu_wenxi",
}

Fk:loadTranslationTable {
  ["peixiu_wenxi"] = "闻喜",
  [":peixiu_wenxi"] = "你每回合首次使用一个花色的牌后，你摸一张牌。",
}

wenxi:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(wenxi.name) and not player:isNude() then
      local room = player.room
      local use_event = room.logic:getCurrentEvent()
      local mark_name = "peixiu_wenxi_" .. data.card:getSuitString() .. "-turn"
      local mark = player:getMark(mark_name)
      if mark == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data
          if last_use.from == player and last_use.card:compareSuitWith(data.card) then
            mark = e.id
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryTurn)
      end
      return mark == use_event.id
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, wenxi.name)
  end,
})

return wenxi
