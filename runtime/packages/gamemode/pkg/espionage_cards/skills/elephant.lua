local skill = fk.CreateSkill {
  name = "#elephant_skill",
  tags = { Skill.Compulsory },
  attached_equip = "elephant",
}

Fk:loadTranslationTable{
  ["#elephant_skill"] = "战象",
}

local U = require "packages.utility.utility"

skill:addEffect(U.BeforePresentCard, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(skill.name) and data.from ~= player and data.to == player
  end,
  on_use = function (self, event, target, player, data)
    data.fail = true
  end,
})

skill:addEffect("distance", {
  correct_func = function (self, from, to)
    if to:hasSkill(skill.name) then
      return 1
    end
  end,
})

return skill
