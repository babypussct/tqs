local aibing = fk.CreateSkill {
  name = "v11__aibing",
}

Fk:loadTranslationTable{
  ["v11__aibing"] = "哀兵",
  [":v11__aibing"] = "当你死亡时，你可以令你下一名武将登场时视为使用一张【杀】。",
}

local U = require "packages.gamemode.pkg.1v1_generals.1v1_util"

aibing:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aibing.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    player.tag["v11__aibing"] = true
  end,
})

aibing:addEffect(U.Debut, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.tag["v11__aibing"]
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player.tag["v11__aibing"] = nil
    room:useVirtualCard("slash", nil, player, player.next, aibing.name, true)
  end,
})

return aibing
