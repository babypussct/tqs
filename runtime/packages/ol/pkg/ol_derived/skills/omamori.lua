local skill = fk.CreateSkill{
  name = "#omamori_skill",
  tags = { Skill.Compulsory },
  attached_equip = "omamori",
}

skill:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Draw and
      #player.room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
        return e.data.killer == player
      end, Player.HistoryGame) > 0
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.room.logic:getEventsOfScope(GameEvent.Death, 999, function (e)
      return e.data.killer == player
    end, Player.HistoryGame)
    player:drawCards(n, skill.name)
  end,
})

return skill
