local dianbu = fk.CreateSkill{
  name = "dianbu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dianbu"] = "点簿",
  [":dianbu"] = "锁定技，你的首个回合开始时，你获得13张牌。当你每个回合内首次打出一种〖拘魂〗组合后，你视为使用一张【无中生有】，"..
  "且因此获得的牌不计入手牌上限。若为炸弹，刷新此技能。",

  ["$dianbu1"] = "孟婆汤，尽情地享受吧！倒满吧！",
  ["$dianbu2"] = "生死簿一翻，牛马今天不一般。",
}

dianbu:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dianbu.name) and
      player:usedEffectTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(room:getNCards(13), Card.PlayerHand, player, fk.ReasonJustMove, dianbu.name, nil, false, player)
  end,
})

dianbu:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand and move.skillName == "ex_nihilo_skill" then
        return true
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local effect_event = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if effect_event and table.contains(effect_event.data.card.skillNames, dianbu.name) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand and move.skillName == "ex_nihilo_skill" then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              room:setCardMark(Fk:getCardById(info.cardId), "dianbu-inhand", 1)
            end
          end
        end
      end
    end
  end,
})

dianbu:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("dianbu-inhand") > 0
  end,
})
return dianbu
