local tuwei = fk.CreateSkill {
  name = "ol__tuwei",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = {"wei"},
}

Fk:loadTranslationTable{
  ["ol__tuwei"] = "突围",
  [":ol__tuwei"] = "魏势力技，出牌阶段开始时，你可以获得攻击范围内任意名角色各一张牌，"..
    "然后回合结束时，其中本回合未受到伤害的角色各获得你的一张牌。",

  ["#ol__tuwei-choose"] = "突围：你可以获得攻击范围内任意名角色各一张牌",

  ["$ol__tuwei1"] = "成败之机，在此一战！",
  ["$ol__tuwei2"] = "一相与一，勇者得前！",
}

tuwei:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuwei.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return player:inMyAttackRange(p) and not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return player:inMyAttackRange(p) and not p:isNude()
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#ol__tuwei-choose",
      skill_name = tuwei.name,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("tuwei-turn")
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead and not p:isNude() then
        table.insertIfNeed(mark, p)
        local card = room:askToChooseCard(player, {
          target = p,
          flag = "he",
          skill_name = tuwei.name
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, tuwei.name, nil, false, player)
      end
      if player.dead then return end
    end
    room:setPlayerMark(player, "tuwei-turn", mark)
  end,
})

tuwei:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tuwei.name) and player:getMark("tuwei-turn") ~= 0 and not player:isNude() and
      player:getMark("zhengbingExtraPhase-turn") == 0 then --幽默本意
      local tos = table.filter(player:getMark("tuwei-turn"), function(p)
        return not p.dead
      end)
      if #tos == 0 then return end
      player.room.logic:getActualDamageEvents(1, function(e)
        if table.removeOne(tos, e.data.to) and #tos == 0 then
          return true
        end
      end, Player.HistoryTurn)
      if #tos > 0 then
        player.room:sortByAction(tos)
        event:setCostData(self, { tos = tos })
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos ---@type ServerPlayer[]
    for _, p in ipairs(tos) do
      if player.dead or player:isNude() then return end
      if not p.dead then
        local card = room:askToChooseCard(p, {
          target = player,
          flag = "he",
          skill_name = tuwei.name,
        })
        room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonPrey, tuwei.name, nil, false, p)
      end
    end
  end,
})

return tuwei
