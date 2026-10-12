local rumo = fk.CreateSkill {
  name = "#rumo",
}

Fk:loadTranslationTable{
  ["#rumo"] = "入魔",
  ["@@rumo-noclear"] = "入魔",
}

rumo:addEffect(fk.RoundEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return
      player:hasSkill(rumo.name, true) and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryRound) == 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, rumo.name)
  end,
})

rumo:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@@rumo-noclear", 1)
end)

rumo:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "@@rumo-noclear", 0)
  end
end)

return rumo
