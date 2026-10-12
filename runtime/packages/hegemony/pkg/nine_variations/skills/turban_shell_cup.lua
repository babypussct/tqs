
local skill = fk.CreateSkill {
  name = "turban_shell_cup_skill&",
  attached_equip = "turban_shell_cup",
}

skill:addEffect("viewas", {
  prompt = "#turban_shell_cup_skill&",
  times = function (self, player)
    return 9 - player:usedSkillTimes(skill.name, Player.HistoryTurn)
  end,
  pattern = "analeptic",
  view_as = function(self, player, cards)
    if #cards ~= 0 then return end
    local c = Fk:cloneCard("analeptic")
    c.skillName = "turban_shell_cup"
    c:addSubcard(Fk:currentRoom().draw_pile[1])
    return c
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(skill.name, Player.HistoryTurn) < 9 and
      #Fk:currentRoom().draw_pile > 0
  end,
  enabled_at_response = function (self, player, response)
    return not response and player:usedSkillTimes(skill.name, Player.HistoryTurn) < 9 and
      #Fk:currentRoom().draw_pile > 0
  end,
})

return skill
