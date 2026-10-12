local duoqi = fk.CreateSkill{
  name = "duoqi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["duoqi"] = "夺炁",
  [":duoqi"] = "锁定技，一号位首个回合开始前，你执行一个不能使用延时锦囊牌的额外出牌阶段。所有角色的初始手牌称为“炁”。"..
    "你每回合对一名角色首次造成伤害后，你获得其一张“炁”。",

  ["@@duoqi-inhand"] = "炁",

  ["$duoqi1"] = "你的胆气，一文不值！",
  ["$duoqi2"] = "你的脊梁，不堪一击！",
}

duoqi:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  --实测要晚于纵傀，暂不处理此优先级顺序（意义不大）
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(duoqi.name) and player.room:getBanner("RoundCount") == 1
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(true, duoqi.name, { Player.Play })
  end,
})

duoqi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.reason == duoqi.name
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "duoqi_extra-turn", 1)
  end,
})

duoqi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    --待定：是否限定在出牌阶段内？
    return player:getMark("duoqi_extra-turn") > 0 and card.sub_type == Card.SubtypeDelayedTrick
  end,
})

duoqi:addEffect(fk.GameStart, {
  mute = true,
  --实测只计算初始手牌，机制不明，这里靠提高记录优先级来实现
  priority = 9,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(duoqi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark, ids = {}, {}
    for _, p in ipairs(room.alive_players) do
      local handcards = p:getCardIds("h")
      mark[tostring(p.id)] = handcards
      table.insertTableIfNeed(ids, handcards)
      if p == player then
        for _, id in ipairs(handcards) do
          --FIXME: 实测所有角色都能看到被记录的“炁”，先偷个懒
          room:setCardMark(Fk:getCardById(id), "@@duoqi-inhand", 1)
        end
      end
    end
    room:setPlayerMark(player, "duoqi_record", mark)
    room:setPlayerMark(player, "duoqi_cards", ids)
  end,
})

duoqi:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    --FIXME: 实测所有角色都能看到被记录的“炁”，先偷个懒
    return player:hasSkill(duoqi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("duoqi_cards")
    if #mark == 0 then return end
    for _, id in ipairs(player:getCardIds("h")) do
      if table.contains(mark, id) then
        room:setCardMark(Fk:getCardById(id), "@@duoqi-inhand", 1)
      end
    end
  end,
})

duoqi:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(duoqi.name) then return false end
    local to = data.to
    --实测能对自己以及死亡角色发动
    local room = player.room
    local mark = player:getTableMark("duoqi_damage-turn")
    if mark[tostring(to.id)] == nil then
      player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        if player == damage.from and data.to == damage.to then
          mark[tostring(to.id)] = e.id
          room:setPlayerMark(player, "duoqi_damage-turn", mark)
          return true
        end
        return false
      end, Player.HistoryTurn)
    end
    return mark[tostring(to.id)] == room.logic:getCurrentEvent().id
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local to = data.to
    local cards = player:getTableMark("duoqi_record")[tostring(to.id)]
    if cards == nil then return end
    local room = player.room
    --移动信息对其他角色不可见
    --优先级顺序：其手牌区>其装备区>其判定区>从其开始，除其外的每名其他角色的{手牌区>装备区>判定区}>
    --弃牌堆>摸牌堆>自己的装备区>自己的判定区
    local to_get = {}

    local all_players = room:getAllPlayers()
    if to ~= player then
      table.removeOne(all_players, player)
    end
    local index = table.indexOf(all_players, to)
    local p
    for i = index, #all_players, 1 do
      p = all_players[i]
      for _, playerArea in ipairs({"h", "e", "j"}) do
        to_get = table.filter(p:getCardIds(playerArea), function(id)
          return table.contains(cards, id)
        end)
        if #to_get > 0 then
          if playerArea ~= "h" or p ~= player then
            room:obtainCard(player, room:tableRandomPick(to_get), false, fk.ReasonPrey, player, duoqi.name)
          end
          return
        end
      end
    end
    if index > 1 then
      for i = 1, index - 1, 1 do
        p = all_players[i]
        for _, playerArea in ipairs({"h", "e", "j"}) do
          to_get = table.filter(p:getCardIds(playerArea), function(id)
            return table.contains(cards, id)
          end)
          if #to_get > 0 then
            if playerArea ~= "h" or p ~= player then
              room:obtainCard(player, room:tableRandomPick(to_get), false, fk.ReasonPrey, player, duoqi.name)
            end
            return
          end
        end
      end
    end

    to_get = table.filter(cards, function(id)
      return table.contains(room.discard_pile, id)
    end)
    if #to_get == 0 then
      to_get = table.filter(cards, function(id)
        return table.contains(room.draw_pile, id)
      end)
    end
    if #to_get > 0 then
      room:obtainCard(player, room:tableRandomPick(to_get), false, fk.ReasonJustMove, player, duoqi.name)
      return
    end

    if to ~= player then
      for _, playerArea in ipairs({"e", "j"}) do
        to_get = table.filter(player:getCardIds(playerArea), function(id)
          return table.contains(cards, id)
        end)
        if #to_get > 0 then
          room:obtainCard(player, room:tableRandomPick(to_get), false, fk.ReasonPrey, player, duoqi.name)
          return
        end
      end
    end
  end,
})

duoqi:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "duoqi_cards", 0)
  room:setPlayerMark(player, "duoqi_record", 0)
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@duoqi-inhand", 0)
  end
end)

return duoqi
