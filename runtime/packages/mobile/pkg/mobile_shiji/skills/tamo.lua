local tamo = fk.CreateSkill {
  name = "tamo",
}

Fk:loadTranslationTable{
  ["tamo"] = "榻谟",
  [":tamo"] = "游戏开始时，你可以重新分配所有角色的座次（若为身份模式，则改为除主公外的所有角色；若为斗地主，则改为除三号位外的所有角色）。",

  ["#tamo-invoke"] = "榻谟：你可以重新分配场上角色的座次",
  ["$TaMo"] = "榻谟",
  ["click to exchange"] = "点击交换",

  ["$tamo1"] = "天下分崩，乱之已极，肃竭浅智，窃为君计。",
  ["$tamo2"] = "天下易主，已为大势，君当据此，以待其时。",
}

tamo:addEffect(fk.GameStart, {
  priority = 2,
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tamo.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player,{
      skill_name = tamo.name,
      prompt = "#tamo-invoke"
    }) then
      local availablePlayerIds = table.map(table.filter(room.players, function(p)
        return p.rest > 0 or not p.dead
      end), Util.IdMapper)
      local disabledPlayerIds = {}
      if room:isGameMode("role_mode") then
        disabledPlayerIds = table.filter(availablePlayerIds, function(pid)
          local p = room:getPlayerById(pid)
          return p.role_shown and p.role == "lord"
        end)
      elseif room:isGameMode("1v2_mode") then
        local seat3Player = room:getPlayerBySeat(3)
        disabledPlayerIds = { seat3Player.id }
      end
      local result = room:askToCustomDialog(player, {
        skill_name = tamo.name,
        component = {
          url = "packages/mobile/qml/TaMoBox.qml",
          prop = {
            allPlayerIds = availablePlayerIds,
            disabledPlayerIds = disabledPlayerIds,
            titleName = "$TaMo",
          },
        }
      })
      if result ~= "" then
        event:setCostData(self, {extra_data = result})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local players = table.simpleClone(room.players)
    for seat, playerId in pairs(event:getCostData(self).extra_data) do
      players[seat] = room:getPlayerById(playerId)
    end
    room.players = players
    local player_circle = {}
    for i = 1, #room.players do
      room.players[i].seat = i
      table.insert(player_circle, room.players[i].id)
    end
    for i = 1, #room.players - 1 do
      room.players[i].next = room.players[i + 1]
    end
    room.players[#room.players].next = room.players[1]
    room:setCurrent(room.players[1])
    room:doBroadcastNotify("ArrangeSeats", player_circle)
  end,
})

return tamo
