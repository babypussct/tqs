
local skill = fk.CreateSkill {
  name = "#yitian_slayer_skill",
  tags = { Skill.Compulsory },
  attached_equip = "yitian_slayer",
}

skill:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and data.by_user and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to == data.to and move.toArea == Card.PlayerHand then
            return true
          end
          if move.from == data.to then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return skill
