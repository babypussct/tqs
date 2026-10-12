
local liudu = fk.CreateSkill {
  name = "heg__liudu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["heg__liudu"] = "流毒",
  [":heg__liudu"] = "锁定技，当你死亡后，进入鏖战。",
}

local H = require "packages.hegemony.util"

liudu:addEffect(fk.Deathed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liudu.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    H.enterBattleRoyalMode(player.room)
  end,
})

return liudu
