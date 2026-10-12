local jihun = fk.CreateSkill {
  name = "ld__jihun",
}

Fk:loadTranslationTable {
  ["ld__jihun"] = "汲魂",
  [":ld__jihun"] = "当你受到伤害后或与你势力不同的角色进入濒死状态被救回后，你可以将一张未加入游戏的武将牌扣置加入到“魂”牌中。",

  ["$ld__jihun1"] = "魂聚则生，魂散则弃。",
  ["$ld__jihun2"] = "魂羽化游，以辅四方。",
}

local U = require "packages.utility.utility"
local H = require "packages.hegemony.util"

local function GetHuashen(player, n)
  local room = player.room
  local generals = room:findGenerals(function() return true end, n)
  local mark = U.getPrivateMark(player, "&ld__hun")
  table.insertTableIfNeed(mark, generals)
    U.setPrivateMark(player, "&ld__hun", mark)
  if #player:getTableMark("ld__yigui_cards") == 0 then
    room:setPlayerMark(player, "ld__yigui_cards", room:getUniversalCards("bt"))
  end
end

jihun:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
      return player:hasSkill(jihun.name) and target == player
  end,
  on_use = function(self, event, target, player, data)
    GetHuashen(player, 1)
  end,
})

jihun:addEffect(fk.AfterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jihun.name) and target and not target.dead and not H.compareKingdomWith(target, player)
        and (target.kingdom ~= "unknown") and (player.kingdom ~= "unknown")
  end,
  on_use = function(self, event, target, player, data)
    GetHuashen(player, 1)
  end,
})


return jihun
