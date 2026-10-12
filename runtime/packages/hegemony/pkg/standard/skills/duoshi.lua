

local duoshi = fk.CreateSkill{
  name = "duoshi",
}

Fk:loadTranslationTable{
  ["duoshi"] = "度势",
  [":duoshi"] = "出牌阶段开始时，你可以视为使用一张【以逸待劳】。",

  ["$duoshi1"] = "以今日之大势，当行此计。",
  ["$duoshi2"] = "国之大计，审势为先。",
}

local H = require "packages.hegemony.util"

duoshi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(duoshi.name) and player == target and player.phase == Player.Play and
      player:canUse(Fk:cloneCard("await_exhausted", nil, nil, duoshi.name))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return
      H.compareKingdomWith(p, player) end)
    room:useVirtualCard("await_exhausted", {}, player, targets, duoshi.name)
  end,
})

return duoshi
