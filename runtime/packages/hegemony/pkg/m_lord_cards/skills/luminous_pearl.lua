
local skill = fk.CreateSkill {
  name = "#mobile__luminous_pearl_skill",
  attached_equip = "mobile__luminous_pearl",
}

skill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and
      player:usedSkillTimes(skill.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, skill.name)
  end,
})

return skill
