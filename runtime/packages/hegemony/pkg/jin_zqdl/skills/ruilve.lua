local ruilve = fk.CreateSkill {
  name = "heg__ruilve",
}

Fk:loadTranslationTable {
  ["heg__ruilve"] = "睿略",
  [":heg__ruilve"] = "未确定势力的其他角色回合结束时，你可以获得弃牌堆内本回合进入的所有伤害牌，然后令其摸等量的牌。",

  ["$heg__ruilve1"] = "司马当兴，其兴在吾。",
  ["$heg__ruilve2"] = "吾承父志，故知军事、通谋略。",
}

local H = require "packages.hegemony.util"

ruilve:addEffect(fk.TurnEnd,{
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(ruilve.name) and H.getGeneralsRevealedNum(target) == 0 and target ~= player then
      local room = player.room
      local ids = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end, Player.HistoryTurn)
      local x = #table.filter(ids, function(id)
        return Fk:getCardById(id).is_damage_card
      end)
      if x > 0 then
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).is_damage_card then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    room:moveCardTo({cards}, Player.Hand, player, fk.ReasonJustMove, ruilve.name, nil, true, player)
    if not target.dead then
      target:drawCards(#cards, ruilve.name)
    end
  end,
})

return ruilve
