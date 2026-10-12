
local skill = fk.CreateSkill {
  name = "#golden_ring_armor_skill",
  tags = { Skill.Compulsory },
  attached_equip = "golden_ring_armor",
}

skill:addEffect(fk.TargetConfirming, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and
      data.card.number > 0 and
      player:usedSkillTimes(skill.name, Player.HistoryTurn) == 0 then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event then
        local yes = false
        player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
          if e.id < use_event.id and e.data.from ~= player then
            if e.data.card.number > 0 and math.abs(e.data.card.number - data.card.number) >= 3 then
              yes = true
            end
            return true
          end
        end, 0, Player.HistoryGame)
        return yes
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data:setNullified(player)
  end,
})

return skill
