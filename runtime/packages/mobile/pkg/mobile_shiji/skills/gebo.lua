local gebo = fk.CreateSkill {
  name = "gebo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gebo"] = "戈帛",
  [":gebo"] = "锁定技，一名角色回复体力后，你从牌堆顶将一张牌置于<a href='RenPile_href'>“仁”区</a>中。",

  ["$gebo1"] = "握手言和，永罢刀兵。",
  ["$gebo2"] = "重归于好，摒弃前仇。",
}

local U = require "packages.utility.utility"

gebo:addEffect(fk.HpRecover, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gebo.name)
  end,
  on_use = function (self, event, target, player, data)
    U.AddToRenPile(player, player.room:getNCards(1), gebo.name)
  end,
})

return gebo
