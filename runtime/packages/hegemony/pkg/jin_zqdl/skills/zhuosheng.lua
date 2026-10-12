local zhuosheng = fk.CreateSkill{
  name = "heg__zhuosheng",
}

zhuosheng:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(zhuosheng.name) then return end
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@@heg__zhuosheng-turn", 1)
  end,
})

zhuosheng:addEffect(fk.PreCardUse, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("@@heg__zhuosheng-turn") ~= 0 and target == player
  end,
  on_use = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    player.room:setPlayerMark(player, "@@heg__zhuosheng-turn", 0)
  end
})

zhuosheng:addTest(function (room, me)
  local comp2 = room.players[2]
  FkTest.setNextReplies(me, {"1"})
  FkTest.runInRoom(function ()
    room:handleAddLoseSkills(me, zhuosheng.name)
    room:obtainCard(me, 1)
    room:useCard{
      from = me,
      tos = {comp2},
      card = Fk:getCardById(1),
    }
  end)
  lu.assertEquals(comp2.hp, 2)

  FkTest.setNextReplies(me, {"1", "1"})
  FkTest.runInRoom(function ()
    room:obtainCard(me, 1)
    room:obtainCard(me, 2)
    room:useCard{
      from = me,
      tos = {comp2},
      card = Fk:getCardById(1),
    }
  end)
  lu.assertEquals(comp2.hp, 0)
end)

Fk:loadTranslationTable{
  ["heg__zhuosheng"] = "擢升",
  [":heg__zhuosheng"] = "当你得到牌后，你可以令你本回合使用的下一张牌的伤害值基数+1（不能叠加）。",

  ["@@heg__zhuosheng-turn"] = "擢升",

  ["$heg__zhuosheng1"] = "才经世务，干用之绩。",
  ["$heg__zhuosheng2"] = "器量之远，当至公辅。",
}

return zhuosheng
