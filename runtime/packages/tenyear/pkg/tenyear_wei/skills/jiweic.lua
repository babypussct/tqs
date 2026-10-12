local jiweic = fk.CreateSkill{
  name = "jiweic",
  attached_skill_name = "jiweic&",
}

Fk:loadTranslationTable{
  ["jiweic"] = "极威",
  [":jiweic"] = "其他魏势力角色的出牌阶段限一次，其可以交给你一张手牌，然后你可以令其发动一次至多弃置3张牌的〖典论〗。",

  ["$jiweic1"] = "法儒圣，效兵威，朕当为大魏始皇！",
  ["$jiweic2"] = "朕承天命，御极四方，当系天下之颈。",
}

jiweic:addAcquireEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    if p.kingdom == "wei" then
      room:handleAddLoseSkills(p, "jiweic&", nil, false, true)
    else
      room:handleAddLoseSkills(p, "-jiweic&", nil, false, true)
    end
  end
end)

jiweic:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "wei" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(jiweic.name, true)
    end) then
      room:handleAddLoseSkills(player, "jiweic&", nil, false, true)
    else
      room:handleAddLoseSkills(player, "-jiweic&", nil, false, true)
    end
  end,
})

return jiweic
