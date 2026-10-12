local weilu = fk.CreateSkill {
  name = "weilu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["weilu"] = "威虏",
  [":weilu"] = "锁定技，当你受到其他角色造成的伤害后，伤害来源在你下回合出牌阶段开始时失去体力至1，此阶段结束时其回复以此法失去的体力值。",

  ["@@weilu"] = "威虏",

  ["$weilu1"] = "贼人势大，需从长计议。",
  ["$weilu2"] = "时机未到，先行撤退。",
}

weilu:addLoseEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    room:removeTableMark(p, "@@weilu", player.id)
    room:setPlayerMark(p, "weilu_record-phase", 0)
  end
end)

weilu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weilu.name) and
      data.from and not data.from.dead and data.from ~= player
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.from}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(data.from, "@@weilu", player.id)
    room:addTableMarkIfNeed(data.from, "weilu-turn", player.id)
  end,
})
weilu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      table.find(player.room.alive_players, function (p)
        return
          table.contains(p:getTableMark("@@weilu"), player.id) and
          not table.contains(p:getTableMark("weilu-turn"), player.id)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player), function (p)
      return
        table.contains(p:getTableMark("@@weilu"), player.id) and
        not table.contains(p:getTableMark("weilu-turn"), player.id)
    end)
    if #targets == 0 then
      return false
    end

    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead and table.contains(p:getTableMark("@@weilu"), player.id) then
        room:removeTableMark(p, "@@weilu", player.id)
        local n = p.hp - 1
        if n > 0 then
          room:loseHp(p, n, weilu.name)
          room:setPlayerMark(p, "weilu_record-phase", n)
        end
      end
    end
  end,
})

weilu:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("weilu_record-phase") ~= 0 and player:isAlive() and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = player:getMark("weilu_record-phase"),
      skillName = weilu.name,
    }
  end,
})

weilu:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      table.find(player.room.alive_players, function (p)
        return
          table.contains(p:getTableMark("@@weilu"), player.id) and
          not table.contains(p:getTableMark("weilu-turn"), player.id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function (p)
      return
        table.contains(p:getTableMark("@@weilu"), player.id) and
        not table.contains(p:getTableMark("weilu-turn"), player.id)
    end)
    if #targets == 0 then
      return false
    end

    for _, p in ipairs(targets) do
      player.room:removeTableMark(p, "@@weilu", player.id)
    end
  end,
})

return weilu
