local lvxian = fk.CreateSkill {
  name = "heg__lvxian",
  tags = { Skill.MainPlace },
}

Fk:loadTranslationTable {
  ["heg__lvxian"] = "履险",
  [":heg__lvxian"] = "主将技，当你每回合首次受到伤害后，若执行上回合的角色不为你，你可以摸X张牌（X为你上回合失去的牌数）。",

  ["@heg__lvxian_record"] = "履险",

  ["$heg__lvxian1"]= "大丈夫生于世，当沙场效忠！",
  ["$heg__lvxian2"]= "骁勇善战，刚毅果断！",
}

lvxian:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(lvxian.name) and player:getMark("heg__lvxian_lastcurrent") == 0 and player:getMark("@heg__lvxian_record") > 0 then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end, Player.HistoryTurn)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("@heg__lvxian_record"), lvxian.name)
  end,
})

lvxian:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(lvxian.name) then
      return true
    elseif target ~= player and player:hasSkill(lvxian.name) and player:getMark("heg__lvxian_lastcurrent") > 0 then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if player:getMark("heg__lvxian_lastcurrent") > 0 then
      player.room:setPlayerMark(player, "heg__lvxian_lastcurrent", 0)
    else
      player.room:setPlayerMark(player, "heg__lvxian_lastcurrent", 1)
    end
  end,
})

lvxian:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(lvxian.name) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      event:setCostData(self, { num = n })
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@heg__lvxian_record", event:getCostData(self).num)
  end,
})

lvxian:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(lvxian.name) and player.phase == Player.Start and
    player:getMark("@heg__lvxian_record") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@heg__lvxian_record", 0)
  end,
})

return lvxian
