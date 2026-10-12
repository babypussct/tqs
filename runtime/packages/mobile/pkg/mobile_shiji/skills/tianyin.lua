local tianyin = fk.CreateSkill {
  name = "tianyin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tianyin"] = "天音",
  [":tianyin"] = "锁定技，结束阶段，你从牌堆中获得你本回合未使用过类型的牌各一张。",

  ["$tianyin1"] = "抚琴体清心远，方成自然之趣。",
  ["$tianyin2"] = "心怀雅正，天音自得。",
}

tianyin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tianyin.name) and player.phase == Player.Finish then
      local types = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data
        if use.from == player then
          table.insertIfNeed(types, use.card:getTypeString())
        end
      end, Player.HistoryTurn)
      return #types < 3
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data
      if use.from == player then
        table.removeOne(types, use.card:getTypeString())
      end
    end, Player.HistoryTurn)
    local cards = {}
    for _, type in ipairs(types) do
      local card = room:getCardsFromPileByRule(".|.|.|.|.|"..type)
      if card then
        table.insert(cards, card[1])
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, tianyin.name, nil, false, player)
    end
  end,
})

return tianyin
