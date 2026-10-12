local zishu = fk.CreateSkill {
  name = "zishu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zishu"] = "自书",
  [":zishu"] = "锁定技，其他角色回合结束时，将你手牌中所有本回合获得的牌置入弃牌堆；你的回合内，当你不因此技能获得牌后，你摸一张牌。",

  ["@@zishu-inhand-turn"] = "自书",

  ["$zishu1"] = "君子有德，当不以物喜，不以己悲。",
  ["$zishu2"] = "身外之物，应泾渭分明，秋毫无犯。",
}

zishu:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zishu.name) and target ~= player and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@zishu-inhand-turn") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zishu.name, 2)
    room:notifySkillInvoked(player, zishu.name, "negative")
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@zishu-inhand-turn") > 0
    end)
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zishu.name, nil, true, player)
  end,
})

zishu:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zishu.name) and player.room.current == player then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.skillName ~= zishu.name then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zishu.name, 1)
    room:notifySkillInvoked(player, zishu.name, "drawcard")
    player:drawCards(1, zishu.name)
  end,

  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zishu.name, true) and player.room.current ~= player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@zishu-inhand-turn", 1)
          end
        end
      end
    end
  end,
})

return zishu
