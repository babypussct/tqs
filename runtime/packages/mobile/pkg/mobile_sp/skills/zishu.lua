local zishu = fk.CreateSkill {
  name = "mobile__zishu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__zishu"] = "自书",
  [":mobile__zishu"] = "锁定技，你的回合外，你获得的手牌均会在当前回合结束阶段结束时置入弃牌堆；"..
  "你的回合内，当你不因此技能效果获得手牌时，摸一张牌。",

  ["@@mobile__zishu-inhand-turn"] = "自书",

  ["$mobile__zishu1"] = "我意已决，诸兄何复多言？",
  ["$mobile__zishu2"] = "此去如若不成，吾宁殉志而终。",
}

zishu:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zishu.name) and target ~= player and target.phase == Player.Finish and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@mobile__zishu-inhand-turn") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@mobile__zishu-inhand-turn") > 0
    end)
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zishu.name, nil, true, player)
  end,
})

zishu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zishu.name) and player.room:getCurrent() == player then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.skillName ~= zishu.name then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, zishu.name)
  end,

  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zishu.name, true) and player.room:getCurrent() ~= player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@mobile__zishu-inhand-turn", 1)
          end
        end
      end
    end
  end,
})

return zishu
