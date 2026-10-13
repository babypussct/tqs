local pianyi = fk.CreateSkill {
  name = "v11__pianyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["v11__pianyi"] = "翩仪",
  [":v11__pianyi"] = "锁定技，当你登场时，若此时是对手的回合，对手结束此回合。",

  ["$v11__pianyi1"] = "呵呵~不能动了吧。",
  ["$v11__pianyi2"] = "将军看呆了吗？",
}

local U = require "packages.gamemode.pkg.1v1_generals.1v1_util"

pianyi:addEffect(U.Debut, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pianyi.name) and player.room.current ~= player
  end,
  on_use = function(self, event, target, player, data)
    player.room:endTurn()
  end,
})

return pianyi
