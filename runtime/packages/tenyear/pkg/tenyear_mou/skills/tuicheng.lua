local tuicheng = fk.CreateSkill {
  name = "ty__tuicheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__tuicheng"] = "推诚",
  [":ty__tuicheng"] = "锁定技，当你交给其他角色牌后，其需交给你等量张牌（不能是本回合你交给其的牌），否则你摸等量张牌。",

  ["#ty__tuicheng-give"] = "推诚：交给 %src %arg张牌，或点“取消”其摸%arg张牌",

  ["$ty__tuicheng1"] = "不负人者，必不为人所负。",
  ["$ty__tuicheng2"] = "我以诚待人，不信天下人负我。",
}

tuicheng:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tuicheng.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and move.moveReason == fk.ReasonGive and
          move.toArea == Card.PlayerHand and not move.to.dead then
          return true
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player and move.moveReason == fk.ReasonGive and
        move.toArea == Card.PlayerHand then
        table.insertIfNeed(tos, move.to)
      end
    end
    room:sortByAction(tos)
    for _, to in ipairs(tos) do
      if not player:hasSkill(tuicheng.name) then break end
      if not to.dead then
        event:setCostData(self, {tos = {to}})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player and move.to == to and move.moveReason == fk.ReasonGive and
        move.toArea == Card.PlayerHand then
        n = n + #move.moveInfo
      end
    end
    local ids = table.simpleClone(to:getCardIds("he"))
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from == player and move.to == to and move.moveReason == fk.ReasonGive and
          move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryTurn)
    local cards = room:askToCards(to, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = tuicheng.name,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#ty__tuicheng-give:"..player.id.."::"..n,
      cancelable = true,
    })
    if #cards == n then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, tuicheng.name, nil, false, to)
    else
      player:drawCards(n, tuicheng.name)
    end
  end,
})

return tuicheng
