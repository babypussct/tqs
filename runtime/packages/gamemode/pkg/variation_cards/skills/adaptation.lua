local skill = fk.CreateSkill {
  name = "adaptation_skill",
}


skill:addEffect("cardskill", {
  can_use = Util.FalseFunc,
})

skill:addEffect("filter", {
  global = true,
  mute = true,
  card_filter = function(self, card, player)
    return card and card.name == "adaptation" and player:getMark("adaptation-turn") ~= 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard(player:getMark("adaptation-turn"), card.suit, card.number)
  end,
})

local spec = {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "adaptation-turn", data.card.name)
  end,
}

skill:addEffect(fk.PreCardUse, spec)
skill:addEffect(fk.PreCardRespond, spec)

skill:addTest(function (room, me)
  local comp2 = room.players[2]

  local card = room:printCard("adaptation", Card.Spade, 2)
  local duel = room:printCard("duel", Card.Spade, 13)
  FkTest.setNextReplies(me, { json.encode {
    card = duel.id, targets = { comp2.id },
  }, json.encode {
    card = card.id, targets = { comp2.id },
  } })
  FkTest.runInRoom(function ()
    room:obtainCard(me, card)
    room:obtainCard(me, duel)
    me:gainAnExtraPhase(Player.Play)
  end)
  lu.assertEquals(comp2.hp, 2)

  local nullification = room:printCard("nullification", Card.Spade, 3)
  local nullification2 = room:printCard("nullification", Card.Spade, 4)
  local nullification3 = room:printCard("nullification", Card.Spade, 5)
  FkTest.setNextReplies(me, { "", json.encode {
    card = nullification.id,
  }, "", "", json.encode {
    card = card.id,
  } })
  FkTest.setNextReplies(comp2, { json.encode {
    card = nullification2.id,
  }, "", "", "", json.encode {
    card = nullification3.id,
  }, "" })
  FkTest.runInRoom(function ()
    room:obtainCard(me, card)
    room:obtainCard(me, nullification)
    room:obtainCard(comp2, nullification2)
    room:obtainCard(comp2, nullification3)
    room:useVirtualCard("duel", nil, me, comp2)
  end)
  lu.assertEquals(comp2.hp, 1)
end)

return skill
