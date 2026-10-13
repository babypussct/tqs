local huwei = fk.CreateSkill {
  name = "v11__huwei",
}

Fk:loadTranslationTable{
  ["v11__huwei"] = "虎威",
  [":v11__huwei"] = "当你登场时，你可以视为对对手使用一张【水淹七军】。",

  ["$v11__huwei1"] = "传令，发动水计！",
  ["$v11__huwei2"] = "来人，引水对敌！",
}

local U = require "packages.gamemode.pkg.1v1_generals.1v1_util"

huwei:addEffect(U.Debut, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(huwei.name) and player:canUse(Fk:cloneCard("drowning"))
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("drowning", nil, player, player.next, huwei.name)
  end,
})

return huwei
