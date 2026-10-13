local rule = fk.CreateSkill {
  name = "#m_2v2_rule&",
}

--第一个回合的角色摸牌阶段少摸一张牌
rule:addEffect(fk.DrawNCards, {
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local turnevents = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
    if #turnevents == 1 and player:getMark(rule.name) == 0 then
      room:setPlayerMark(player, rule.name, 1)
      data.n = data.n - 1
    end
  end,
})

--四号位多摸一张初始手牌
rule:addEffect(fk.DrawInitialCards, {
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.seat == 4
  end,
  on_refresh = function(self, event, target, player, data)
    data.num = data.num + 1
  end,
})

--一控二模式：队友死后立刻切换视角到活人
rule:addEffect(fk.Death, {
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return target ~= player and target.role == player.role and not player.dead and
      target.room:getBanner("is_2v2_duel") and
      table.contains(target._observers, target.serverplayer) and
      target.serverplayer == player.serverplayer
  end,
  on_refresh = function(self, event, target, player, data)
    -- TODO: 这块啥时候封装个切视角的Server方法
    local controller = player.serverplayer
    table.removeOne(target._observers, controller)
    table.insert(player._observers, controller)

    -- 因为调了Cpp.ServerPlayer的方法必须encode
    player.serverplayer:doNotify("ChangeSelf", cbor.encode(player.id))
  end,
})


return rule
