

local duoshi = fk.CreateSkill{
  name = "ld__lordsunquan_duoshi",
}
local H = require "packages.hegemony.util"
duoshi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(duoshi.name) and player == target and player.phase == Player.Play and not player:prohibitUse(Fk:cloneCard("await_exhausted"))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return
      H.compareKingdomWith(p, player) end)
    room:useVirtualCard("await_exhausted", {}, player, targets, duoshi.name)
  end,
})

Fk:loadTranslationTable{
  ["ld__lordsunquan_duoshi"] = "度势",
  [":ld__lordsunquan_duoshi"] = "出牌阶段开始时，你可以视为使用一张【以逸待劳】。",

  ["$ld__lordsunquan_duoshi1"] = "广施方略，以观其变。",
  ["$ld__lordsunquan_duoshi2"] = "莫慌，观察好局势再做行动。",
}

return duoshi
