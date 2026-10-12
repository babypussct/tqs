local rengou = fk.CreateSkill{
  name = "rengou",
  attached_skill_name = "rengou&",
}

Fk:loadTranslationTable{
  ["rengou"] = "仁彀",
  [":rengou"] = "其他蜀势力角色出牌阶段限一次，其可以弃置1张牌并令你回复1点体力，然后你可以令其发动一次至多摸2张牌的〖烈骧〗。",

  ["$rengou1"] = "万里江山待扫，朕当同卿戮力！",
  ["$rengou2"] = "执天下一诺，此志昭昭可对日月！",
}

rengou:addAcquireEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    if p.kingdom == "shu" then
      room:handleAddLoseSkills(p, "rengou&", nil, false, true)
    else
      room:handleAddLoseSkills(p, "-rengou&", nil, false, true)
    end
  end
end)

rengou:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "shu" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(rengou.name, true)
    end) then
      room:handleAddLoseSkills(player, "rengou&", nil, false, true)
    else
      room:handleAddLoseSkills(player, "-rengou&", nil, false, true)
    end
  end,
})

return rengou
