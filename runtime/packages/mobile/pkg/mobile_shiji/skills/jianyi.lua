local jianyi = fk.CreateSkill {
  name = "jianyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jianyi"] = "俭衣",
  [":jianyi"] = "锁定技，其他角色回合结束时，若弃牌堆中有本回合弃置的防具牌，则你选择其中一张获得。",

  ["$jianyi1"] = "今虽富贵，亦不可浪费。",
  ["$jianyi2"] = "缩衣克俭，才是兴家之道。",
}

jianyi:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(jianyi.name) and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).sub_type == Card.SubtypeArmor and
                table.contains(player.room.discard_pile, info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).sub_type == Card.SubtypeArmor and table.contains(room.discard_pile, info.cardId) then
              table.insert(ids, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local cards = room:askToChooseCard(player, {
      target = player,
      flag = {
        card_data = {{"pile_discard", ids}}
      },
      skill_name = jianyi.name,
    })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, jianyi.name, nil, true, player)
  end,
})

return jianyi
