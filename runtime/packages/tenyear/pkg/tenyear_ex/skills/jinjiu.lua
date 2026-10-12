local jinjiu = fk.CreateSkill {
  name = "ty_ex__jinjiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__jinjiu"] = "禁酒",
  [":ty_ex__jinjiu"] = "锁定技，你的【酒】视为点数为K的【杀】；你的回合内，其他角色不能使用【酒】。",

  ["$ty_ex__jinjiu1"] = "好酒之徒，难堪大任，不入我营！",
  ["$ty_ex__jinjiu2"] = "饮酒误事，必当严禁！",
}

jinjiu:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(jinjiu.name) and card.name == "analeptic" and
      (table.contains(player:getCardIds("h"), card.id) or isJudgeEvent)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, 13)
  end,
})

jinjiu:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    if Fk:currentRoom().current:hasSkill(jinjiu.name) then
      return player ~= Fk:currentRoom().current and card and card.name == "analeptic"
    end
  end,
})

jinjiu:addTest(function (room, me)
  FkTest.runInRoom(function ()
    room:handleAddLoseSkills(me, jinjiu.name)
  end)
  local comp2 = room.players[2]
  local analeptic = room:printCard("analeptic", Card.Spade, 5)
  FkTest.setNextReplies(me, { json.encode {
    card = analeptic.id,
    targets = { comp2.id }
  } })
  FkTest.runInRoom(function ()
    room:obtainCard(me, analeptic)
    me:gainAnExtraTurn(true, nil, {Player.Play})
  end)
  FkTest.setNextReplies(me, {
    json.encode { card = { skill = "ty_ex__xianzhen", }, targets = { comp2.id } },
    json.encode { card = { subcards = { analeptic.id }, } }
  })
  local card = room:printCard("jink", Card.Spade, 10)
  FkTest.runInRoom(function ()
    room:handleAddLoseSkills(me, "ty_ex__xianzhen")
    room:obtainCard(me, analeptic)
    room:obtainCard(comp2, card)
    me:gainAnExtraTurn(true, nil, {Player.Play})
  end)
  lu.assertEquals(analeptic.number, 5)
  FkTest.runInRoom(function ()
    room:moveCardTo(analeptic, Card.DrawPile)
    room:judge{who = me, pattern = ".", reason = "game_rule"}
  end)
end)

return jinjiu
