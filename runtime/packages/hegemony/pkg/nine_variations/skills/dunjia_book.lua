
local skill = fk.CreateSkill {
  name = "dunjia_book_skill&",
  attached_equip = "dunjia_book",
}

local H = require "packages.hegemony.util"

skill:addEffect("active", {
  prompt = "#dunjia_book_skill&",
  times = function (self, player)
    return 2 - player:usedSkillTimes(skill.name, Player.HistoryPhase)
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(skill.name, Player.HistoryPhase) < 2
  end,
  on_use = function(self, room, effect)
    H.transformGeneral(room, effect.from)
  end,
})

return skill
