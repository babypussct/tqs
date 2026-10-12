local sanou = fk.CreateSkill {
  name = "sanou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["sanou"] = "三殴",
  [":sanou"] = "锁定技，当其他角色受到你造成的伤害后或猜错“花拳”的效果后，你摸一张牌并令其获得一枚“击倒”标记，然后若其拥有至少三枚“击倒”标记，" ..
  "其移去所有“击倒”标记并进入“击倒”状态，直到有10张牌离开牌堆或进入弃牌堆后。处于“击倒”状态的角色跳过其出牌阶段。",

  ["@sanou_knockout"] = "击倒",
  ["@sanou_countdown"] = "已击倒",

  ["$sanou1"] = "初平元年，第一次在洛阳打自由搏击，便一举夺魁！",
  ["$sanou2"] = "扫腿直拳十字锁，裸绞肘击断头台！",
}

sanou:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target:isAlive() and data.from == player and player:hasSkill(sanou.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    player:drawCards(1, sanou.name)
    room:addPlayerMark(target, "@sanou_knockout")
    if target:getMark("@sanou_knockout") >= 3 then
      room:setPlayerMark(target, "@sanou_knockout", 0)
      if target:getMark("@sanou_countdown") == 0 then
        room:setPlayerMark(target, "@sanou_countdown", 10)
      end
    end
  end,
})

sanou:addEffect(fk.EventPhaseChanging, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.phase == Player.Play and not data.skipped and player:getMark("@sanou_countdown") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.skipped = true
  end,
})

sanou:addEffect(fk.AfterCardsMove, {
  is_delay_effect = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return table.find(data,
      function(move)
        return
          move.toArea == Card.DiscardPile or
          (
            move.toArea ~= Card.DrawPile and
            table.find(move.moveInfo,
              function(moveInfo) return moveInfo.fromArea == Card.DrawPile
            end) ~= nil
          )
      end
    )
  end,
  on_refresh = function(self, event, target, player, data)
    local decreaseCountDown = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        decreaseCountDown = decreaseCountDown + #move.moveInfo
      elseif move.toArea ~= Card.DrawPile then
        for _, moveInfo in ipairs(move.moveInfo) do
          if moveInfo.fromArea == Card.DrawPile then
            decreaseCountDown = decreaseCountDown + 1
          end
        end
      end
    end

    player.room:removePlayerMark(player, "@sanou_countdown", decreaseCountDown)
  end,
})

sanou:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if not table.find(room.alive_players, function (p)
    return p:hasSkill(sanou.name, true)
  end) then
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@sanou_knockout", 0)
    end
  end
end)

return sanou
