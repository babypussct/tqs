local weimu = fk.CreateSkill{
  name = "hs__weimu",
  tags = {Skill.Compulsory},
}
weimu:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.skeleton.name) and data.card.color == Card.Black and data.card.type == Card.TypeTrick
  end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
  end
})
weimu:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self.skeleton.name) then return false end
    local id = 0
    local c
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerJudge then
        for _, info in ipairs(move.moveInfo) do
          id = info.cardId
          c = Fk:getCardById(id)
          if move.virtualEquip and move.virtualEquip:getEffectiveId() == id then
            c = move.virtualEquip
          end
          if c and c.sub_type == Card.SubtypeDelayedTrick and c.color == Card.Black then
            return true
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local mirror_moves = {}
    player.room:cancelMove(data, nil, function (move, info)
      local c = Fk:getCardById(info.cardId)
      if move.virtualEquip and move.virtualEquip:getEffectiveId() == info.cardId then
        c = move.virtualEquip
      end
      if c and c.sub_type == Card.SubtypeDelayedTrick and c.color == Card.Black then
        local mirror_move = move:copy()
        mirror_move.to = nil
        mirror_move.toArea = Card.DiscardPile
        mirror_move.moveInfo = {info}
        mirror_move.moveReason = fk.ReasonJustMove
        mirror_move.skillName = self.skeleton.name
        table.insert(mirror_moves, mirror_move)
        return true
      end
      return false
    end)
    table.insertTable(data, mirror_moves)
  end
})

weimu:addTest(function (room, me)
  local comp2 = room.players[2]
  FkTest.runInRoom(function () room:handleAddLoseSkills(comp2, weimu.name) end)
  local card = room:printCard("duel", Card.Black, 3)
  FkTest.runInRoom(function ()
    room:useCard{
      from = me,
      tos = { comp2 },
      card = card,
    }
  end)
  lu.assertEquals(comp2.hp, 4)

  card = room:printCard("indulgence", Card.Black, 3)
  local place
  FkTest.runInRoom(function ()
    room:useCard{
      from = me,
      tos = { comp2 },
      card = card,
    }
    place = room:getCardArea(card)
  end)
  lu.assertEquals(#comp2:getCardIds("e"), 0) -- player_cards
  lu.assertEquals(place, Card.DiscardPile) -- card_place
  card = room:printCard("lightning", Card.Black, 3)
  FkTest.runInRoom(function ()
    room:useCard{
      from = me,
      tos = { me },
      card = card,
    }
    me:gainAnExtraTurn()
    comp2:gainAnExtraTurn()
    place = room:getCardArea(card)
  end)
  lu.assertEquals(place, Card.DiscardPile)
end)

Fk:loadTranslationTable{
  ["hs__weimu"] = "帷幕",
  [":hs__weimu"] = "锁定技，当你成为黑色锦囊牌的目标时，取消之。",

  ["$hs__weimu1"] = "此计伤不到我。",
  ["$hs__weimu2"] = "你奈我何！",
}

return weimu
