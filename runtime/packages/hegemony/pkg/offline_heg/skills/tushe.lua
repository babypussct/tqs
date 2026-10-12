local tushe = fk.CreateSkill {
  name = "ofl_heg__tushe",
}

Fk:loadTranslationTable{
  ["ofl_heg__tushe"] = "图射",
  [":ofl_heg__tushe"] = "当你使用牌指定其他角色为目标时，你可以摸X张牌（X为大势力的存活角色数）。",

  ["$ofl_heg__tushe1"] = "非英杰不图？吾既谋之且射毕！",
  ["$ofl_heg__tushe2"] = "汉室衰微，朝纲祸乱，必图后福。",
}

local H = require "packages.hegemony.util"

tushe:addEffect(fk.TargetSpecifying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tushe.name) and
      data.firstTarget and
      table.find(data.use.tos, function(p)
        return p ~= player
      end) and
      table.find(player.room.alive_players, function(p)
        return H.isBigKingdomPlayer(p)
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#table.filter(player.room.alive_players, function(p)
      return H.isBigKingdomPlayer(p)
    end), tushe.name)
  end,
})

return tushe
