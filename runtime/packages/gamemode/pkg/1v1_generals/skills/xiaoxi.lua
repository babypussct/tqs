local xiaoxi = fk.CreateSkill {
  name = "v11__xiaoxi",
}

Fk:loadTranslationTable{
  ["v11__xiaoxi"] = "骁袭",
  [":v11__xiaoxi"] = "当你登场时，你可以视为使用一张【杀】。",
}

local U = require "packages.gamemode.pkg.1v1_generals.1v1_util"

xiaoxi:addEffect(U.Debut, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xiaoxi.name) and
      player:canUse(Fk:cloneCard("slash"), {bypass_distances = true, bypass_times = true})
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, player, player.next, xiaoxi.name)
  end,
})

return xiaoxi
