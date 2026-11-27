
local skill = fk.CreateSkill{
  name = "#dragon_nunchaku_skill",
  attached_equip = "dragon_nunchaku",
  tags = { Skill.Compulsory },
}

skill:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and #data.tos > 0 and not data.tos[1].dead then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event then
        return #use_event:searchEvents(GameEvent.UseCard, 1, function (e)
          return e.data.from == data.tos[#data.tos] and
            e.data.responseToEvent and e.data.responseToEvent.from == player
        end) > 0
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { data.tos[1] } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage {
      from = player,
      to = data.tos[1],
      damage = 1,
      skillName = skill.name,
    }
  end,
})

return skill
