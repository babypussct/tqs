
local qianxun = fk.CreateSkill{
  name = "hs__qianxun",
  tags = {Skill.Compulsory},
}
qianxun:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qianxun.name) and (data.card.trueName == "snatch") -- or data.card.trueName == "indulgence")
  end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
  end
})

qianxun:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  audio_index = 1,
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(qianxun.name) then return false end
    local id, c
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerJudge then
        for _, info in ipairs(move.moveInfo) do
          id = info.cardId
          c = Fk:getCardById(id)
          if move.virtualEquip and move.virtualEquip:getEffectiveId() == id then
            c = move.virtualEquip
          end
          if c and c.trueName == "indulgence" then
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
      if c and c.trueName == "indulgence" then
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

qianxun:addTest(function (room, me)
  local comp2 = room.players[2]
  FkTest.runInRoom(function () room:handleAddLoseSkills(comp2, qianxun.name) end)
  local card = room:printCard("indulgence")
  FkTest.runInRoom(function ()
    room:obtainCard(comp2, 1)
    room:useVirtualCard("snatch", nil, me, comp2)
    room:obtainCard(me, card)
    room:useCard{
      from = me,
      tos = { comp2 },
      card = card,
    }
  end)
  lu.assertIsFalse(comp2:isKongcheng())
  lu.assertEquals(#comp2:getCardIds("e"), 0)
end)

Fk:loadTranslationTable{
  ["hs__qianxun"] = "谦逊",
  [":hs__qianxun"] = "锁定技，当你成为【顺手牵羊】或【乐不思蜀】的目标时，你取消此目标。",

  ["$hs__qianxun1"] = "儒生脱尘，不为贪逸淫乐之事。",
  ["$hs__qianxun2"] = "谦谦君子，不饮盗泉之水。",
}

return qianxun
