local xunyi = fk.CreateSkill {
  name = "xunyi",
}

Fk:loadTranslationTable{
  ["xunyi"] = "殉义",
  [":xunyi"] = "游戏开始时，你选择一名其他角色，令其获得“义”标记。<br>当你或有“义”的角色受到1点伤害后，若伤害来源不为另一方，"..
  "另一方弃置一张牌。<br>当你或有“义”的角色造成1点伤害后，若受伤角色不为另一方，另一方摸一张牌。<br>当有“义”的角色死亡时，你可以转移“义”标记。",

  ["@@xunyi"] = "义",
  ["#xunyi-choose"] = "殉义：选择一名角色获得“义”标记",

  ["$xunyi1"] = "古有死恩之士，今有殉义之人！",
  ["$xunyi2"] = "舍身殉义，为君效死！",
}

xunyi:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if player:getMark(xunyi.name) ~= 0 then
    local to = room:getPlayerById(player:getMark(xunyi.name))
    room:setPlayerMark(player, xunyi.name, 0)
    if table.every(room.alive_players, function (p)
      return p:getMark(xunyi.name) ~= to.id
    end) then
      room:setPlayerMark(to, "@@xunyi", 0)
    end
  end
end)

xunyi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xunyi.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = xunyi.name,
      prompt = "#xunyi-choose",
      cancelable = false,
    })[1]
    room:setPlayerMark(to, "@@xunyi", 1)
    room:setPlayerMark(player, xunyi.name, to.id)
  end,
})
xunyi:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(xunyi.name) and player:getMark(xunyi.name) ~= 0 then
      if target == player then
        local to = player.room:getPlayerById(player:getMark(xunyi.name))
        return data.from ~= to and not to.dead
      else
        return player:getMark(xunyi.name) == target.id and data.from ~= player
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = target ~= player and player or room:getPlayerById(player:getMark(xunyi.name))
    room:askToDiscard(to, {
      min_num = data.damage,
      max_num = data.damage,
      include_equip = true,
      skill_name = xunyi.name,
      cancelable = false,
    })
  end,
})
xunyi:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if target and player:hasSkill(xunyi.name) and player:getMark(xunyi.name) ~= 0 then
      if target == player then
        local to = player.room:getPlayerById(player:getMark(xunyi.name))
        return data.to ~= to and not to.dead
      else
        return player:getMark(xunyi.name) == target.id and data.to ~= player
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = target ~= player and player or room:getPlayerById(player:getMark(xunyi.name))
    to:drawCards(data.damage, xunyi.name)
  end,
})
xunyi:addEffect(fk.Death, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(xunyi.name) and player:getMark(xunyi.name) == target.id and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = xunyi.name,
      prompt = "#xunyi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(to, "@@xunyi", 1)
    room:setPlayerMark(player, xunyi.name, to.id)
  end,
})

return xunyi
