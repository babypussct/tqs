local jilis = fk.CreateSkill{
  name = "ld__jilis",
}
local jilis_spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jilis.name) then
      local x, y = player:getAttackRange(), player:getMark("ld__jilis_times-turn")
      if x >= y then
        local room = player.room
        local logic = room.logic
        local end_id = player:getMark("ld__jilis_record-turn")
        local e = logic:getCurrentEvent()
        if end_id == 0 then
          local turn_event = e:findParent(GameEvent.Turn, false)
          if turn_event == nil then return false end
          end_id = turn_event.id
        end
        room:setPlayerMark(player, "ld__jilis_record-turn", logic.current_event_id)
        local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data
          if use.from == player then
            y = y + 1
          end
        end
        events = logic.event_recorder[GameEvent.RespondCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data
          if use.from == player then
            y = y + 1
          end
        end
        room:setPlayerMark(player, "ld__jilis_times-turn", y)
        return x == y
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getAttackRange(), jilis.name)
  end,
}
jilis:addEffect(fk.CardUsing, jilis_spec)
jilis:addEffect(fk.CardResponding, jilis_spec)

jilis:addTest(function (room, me)
  local comp2 = room.players[2]
  local cards = {room:printCard("qinggang_sword"), room:printCard("axe"),
    room:printCard("halberd"), room:printCard("kylin_bow"), room:printCard("slash")}
  FkTest.setNextReplies(me, {json.encode {
    card = cards[1].id,
    targets = { me.id }
  }, "1", json.encode {
    card = cards[2].id,
    targets = { me.id }
  },"1", json.encode {
    card = cards[3].id,
    targets = { me.id }
  },"1", json.encode {
    card = cards[4].id,
    targets = { me.id }
  },"1", json.encode {
    card = cards[5].id,
    targets = { comp2.id }
  }, "1"})
  FkTest.runInRoom(function ()
    room:handleAddLoseSkills(me, jilis.name)
    room:obtainCard(me, cards)
    me:gainAnExtraTurn()
  end)

  local duel = room:printCard("duel")
  FkTest.setNextReplies(me, {json.encode {
    card = cards[5].id,
    targets = { }
  }, "1"})
  FkTest.setNextReplies(comp2, {json.encode {
    card = duel.id,
    targets = { me.id }
  } })
  FkTest.runInRoom(function ()
    me:throwAllCards("eh")
    room:obtainCard(me, cards[5])
    room:obtainCard(comp2, duel, true)
    comp2:gainAnExtraTurn()
  end)
  lu.assertEquals(me:getHandcardNum(), 1)
end)

Fk:loadTranslationTable{
  ["ld__jilis"] = "蒺藜",
  [":ld__jilis"] = "当你于一回合内使用或打出第X张牌时，你可以摸X张牌（X为你的攻击范围）。",

  ["$ld__jilis1"] = "蒺藜骨朵，威震慑敌！",
  ["$ld__jilis2"] = "看我一招，铁蒺藜骨朵！",
}

return jilis
