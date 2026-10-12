local lirang = fk.CreateSkill {
  name = "mobile__lirang",
}

Fk:loadTranslationTable{
  ["mobile__lirang"] = "礼让",
  [":mobile__lirang"] = "其他角色摸牌阶段开始时，若你没有“谦”标记，你可以获得“谦”标记并令其多摸两张牌，若如此做，此回合弃牌阶段结束时，"..
  "你获得其于此阶段弃置的至多两张牌。摸牌阶段开始前，若你有“谦”标记，你跳过此阶段并移去“谦”标记。",

  ["@@mobile__kongrong_qian"] = "谦",
  ["#mobile__lirang-invoke"] = "礼让：你可以获得“谦”标记，令 %dest 摸牌数+2",
  ["#mobile__lirang-get"] = "礼让：获得 %dest 本阶段弃置的至多两张牌",

  ["$mobile__lirang1"] = "人之所至，礼之所及。",
  ["$mobile__lirang2"] = "施之以礼，还之以德。",
}

lirang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:hasSkill(lirang.name) and target.phase == Player.Draw and
      player:getMark("@@mobile__kongrong_qian") == 0 and not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = lirang.name,
      prompt = "#mobile__lirang-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@mobile__kongrong_qian", 1)
  end,
})
lirang:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target.phase == Player.Discard and player:usedSkillTimes(lirang.name, Player.HistoryTurn) > 0 and not player.dead then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from and move.from == target and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from and move.from == target and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryPhase)
    ids = table.filter(ids, function(id)
      return table.contains(player.room.discard_pile, id)
    end)
    local cards = room:askToChooseCards(player, {
      target = player,
      min = 1,
      max = 2,
      flag = {
        card_data = {{lirang.name, ids}}
      },
      skill_name = lirang.name,
      prompt = "#mobile__lirang-get::"..target.id
    })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, lirang.name, nil, true, player)
  end,
})
lirang:addEffect(fk.EventPhaseChanging, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.phase == Player.Draw and
      player:getMark("@@mobile__kongrong_qian") > 0 and not data.skipped
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@mobile__kongrong_qian", 0)
    data.skipped = true
  end,
})
lirang:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return player:usedSkillTimes(lirang.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

return lirang
