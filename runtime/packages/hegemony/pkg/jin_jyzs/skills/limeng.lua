local limeng = fk.CreateSkill{
  name = "heg__limeng",
}

Fk:loadTranslationTable {
  ["heg__limeng"] = "离梦",
  [":heg__limeng"] = "结束阶段，你可以弃置一张非基本牌并选择场上两张珠联璧合的武将牌，" ..
  "若不为同一名角色的武将，则这些角色分别对另一名角色造成1点伤害。",

  ["#heg__limeng-invoke"] = "离梦：弃置一张牌并选择两张珠联璧合武将牌，若不为同一名角色，则这些角色分别对另一名角色造成1点伤害",
  ["heg__limeng_tip_1"] = "确认则无事",
  ["heg__limeng_tip_2"] = "造成伤害",

  ["$heg__limeng1"] = "得一人知情识趣，何妨同甘共苦。",
  ["$heg__limeng2"] = "临千军而不改其静，御心无波尔。",
}

limeng:addAuxActiveSkill("#heg__limeng_active", {
  can_use = Util.FalseFunc,
  card_num = 1,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected == 2 then return false end
    local room = Fk:currentRoom()
    local generals = {} ---@type table<Player, General[]>
    table.forEach(room.alive_players, function(p)
      generals[p] = {Fk.generals[p.general], Fk.generals[p.deputyGeneral]}
    end)
    if #selected == 0 then
      for p, gs in pairs(generals) do
        for _, g in ipairs(gs) do
          for _p, _gs in pairs(generals) do
            for _, _g in ipairs(_gs) do
              if g:isCompanionWith(_g) then
                if p == to_select or _p == to_select then return true end
              end
            end
          end
        end
      end
    else
      local tar = selected[1]
      local gs = generals[tar]
      for _, g in ipairs(gs) do
        for p, _gs in pairs(generals) do
          if tar ~= p then
            for _, _g in ipairs(_gs) do
              if g:isCompanionWith(_g) then
                if to_select == p then return true end
              end
            end
          end
        end
      end
    end
    return false
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if #selected_cards ~= 1 then return false end
    if #selected == 2 then return true
    elseif #selected == 1 then
      local tar = selected[1]
      return Fk.generals[tar.general]:isCompanionWith(Fk.generals[tar.deputyGeneral])
    end
    return false
  end,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    if #selected > 0 then
      if #selected == 1 and selected[1] == to_select and self:feasible(player, selected, selected_cards) then
        return "heg__limeng_tip_1"
      else
        return "heg__limeng_tip_2"
      end
    end
  end,
})

limeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name) and player.phase == Player.Finish
      and not player:isNude()) then return false end
    local generals = {} ---@type table<Player, General[]>
    table.forEach(player.room.alive_players, function(p)
      generals[p] = {Fk.generals[p.general], Fk.generals[p.deputyGeneral]}
    end)
    for p, gs in pairs(generals) do
      for _, g in ipairs(gs) do
        for _p, _gs in pairs(generals) do
          for _, _g in ipairs(_gs) do
            if g:isCompanionWith(_g) then return true end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local _, ret = room:askToUseActiveSkill(player, {
      skill_name = "#heg__limeng_active",
      skip = true,
      prompt = "#heg__limeng-invoke",
      extra_data = {skillName = limeng.name}
    })
    if ret then
      event:setCostData(self, {tos = ret.targets, cards = ret.cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local costData = event:getCostData(self)
    local tos, cards = costData.tos, costData.cards
    local room = player.room
    room:throwCard(cards, limeng.name, player, player)
    if #tos < 2 then return end
    room:sortByAction(tos)
    for i = 1, 2, 1 do
      local to1, to2 = tos[i], tos[3-i]
      if to1:isAlive() and to2:isAlive() then
        room:damage{
          from = to1,
          to = to2,
          damage = 1,
        }
      end
    end
  end
})

limeng:addTest(function (room, me)
  FkTest.runInRoom(function ()
    room:handleAddLoseSkills(me, limeng.name)
  end)
  local comp2, comp3 = room.players[2], room.players[3]
  FkTest.setRoomBreakpoint(me, "AskForUseActiveSkill")
  local card = room:printCard("dilu")

  FkTest.runInRoom(function ()
    room:obtainCard(me, card)
    room:changeHero(comp2, "hs__zhouyu") -- comp2和3是珠联璧合，comp2自己也是珠联璧合
    room:changeHero(comp2, "hs__xiaoqiao", nil, true)
    room:changeHero(comp3, "hs__huanggai")
    room:changeHero(comp3, "hs__zhoutai", nil, true)
    me:gainAnExtraPhase(Player.Finish)
  end)

  local handler = ClientInstance.current_request_handler --[[@as ReqActiveSkill]]
  -- 验证只能选comp2和3
  lu.assertIsFalse(handler:targetValidity(me.id))
  lu.assertIsTrue(handler:targetValidity(comp2.id))
  lu.assertIsTrue(handler:targetValidity(comp3.id))
  for i = 4, 8 do
    lu.assertIsFalse(handler:targetValidity(room.players[i].id))
  end
  handler:selectCard(card.id, {selected = true})
  -- 只选comp2，可以确定，可以选comp3
  handler:selectTarget(comp2.id, {selected = true})
  lu.assertIsTrue(handler:targetValidity(comp3.id))
  lu.assertIsTrue(handler:feasible())

  -- 再选comp3，可以确定
  handler:selectTarget(comp3.id, {selected = true})
  lu.assertIsTrue(handler:feasible())

  -- 取消comp2，不可以确定，可以选comp2
  handler:selectTarget(comp2.id, {selected = false})
  lu.assertIsTrue(handler:targetValidity(comp2.id))
  lu.assertIsFalse(handler:feasible())

  FkTest.setNextReplies(me, {
    FkTest.replyUseSkill("#heg__limeng_active", {comp2, comp3}, {card.id})
  })
  FkTest.resumeRoom()
  lu.assertEquals(comp2.hp, 2) -- 周瑜小乔 max 3
  lu.assertEquals(comp3.hp, 3)

  FkTest.setNextReplies(me, {
    FkTest.replyUseSkill("#heg__limeng_active", {comp2}, {card.id})
  })
  FkTest.runInRoom(function ()
    room:obtainCard(me, card)
    me:gainAnExtraPhase(Player.Finish)
  end)
  lu.assertEquals(comp2.hp, 2)
end)

return limeng
