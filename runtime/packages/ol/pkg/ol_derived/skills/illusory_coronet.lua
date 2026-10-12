local skill = fk.CreateSkill {
  name = "#illusory_coronet_skill",
  tags = { Skill.Compulsory },
  attached_equip = "illusory_coronet",
}

skill:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name)
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})
skill:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(skill.name) then
      return -1
    end
  end,
})

return skill
