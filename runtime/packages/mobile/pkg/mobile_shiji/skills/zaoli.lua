local zaoli = fk.CreateSkill {
  name = "zaoli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zaoli"] = "躁厉",
  [":zaoli"] = "锁定技，出牌阶段，你不能使用或打出非本回合获得的手牌。当你使用或打出手牌时，若你的“厉”标记数小于4，你获得1个“厉”标记。"..
  "回合开始时，若你有“厉”标记，你移去所有“厉”标记并弃置任意张牌（至少弃置一张牌），然后摸X张牌（X为你移去的“厉”标记数与弃置牌数之和）。"..
  "若你移去的“厉”标记数大于2，你失去1点体力。",

  ["@@zaoli-turn-inhand"] = "躁厉",
  ["@zaoli"] = "厉",
  ["#zaoli-discard"] = "躁厉：选择至少一张牌，你弃置这些牌和所有“厉”，摸等量张牌",

  ["$zaoli1"] = "人贵正直，何欺暗室！",
  ["$zaoli2"] = "饰情矫行，吾以为耻！",
}

zaoli:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    if room.current == player and not player:isKongcheng() then
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.toArea == Player.Hand then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player:getCardIds("h"), info.cardId) then
                room:setCardMark(Fk:getCardById(info.cardId), "@@zaoli-turn-inhand", 1)
              end
            end
          end
        end
      end, Player.HistoryTurn)
    end
  end
end)

zaoli:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zaoli.name) and player:getMark("@zaoli") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@zaoli")
    room:setPlayerMark(player, "@zaoli", 0)
    local yes = n > 2
    n = n + #room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = zaoli.name,
      cancelable = false,
      prompt = "#zaoli-discard",
    })
    if not player.dead then
      player:drawCards(n, zaoli.name)
      if yes and not player.dead then
        room:loseHp(player, 1, zaoli.name)
      end
    end
  end,
})

---@type TrigSkelSpec<UseCardFunc>
local zaoli_spec = {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(zaoli.name) and
      data:isUsingHandcard(player) and player:getMark("@zaoli") < 4
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@zaoli")
  end,
}
zaoli:addEffect(fk.CardUsing, zaoli_spec)
zaoli:addEffect(fk.CardResponding, zaoli_spec)

zaoli:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(zaoli.name, true) and player.room.current == player then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@zaoli-turn-inhand", 1)
          end
        end
      end
    end
  end,
})
zaoli:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:hasSkill(zaoli.name) and player.phase == Player.Play then
      local cardIds = Card:getIdList(card)
      return table.find(cardIds, function(id)
        return Fk:getCardById(id):getMark("@@zaoli-turn-inhand") == 0 and table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:hasSkill(zaoli.name) and player.phase == Player.Play then
      local cardIds = Card:getIdList(card)
      return table.find(cardIds, function(id)
        return Fk:getCardById(id):getMark("@@zaoli-turn-inhand") == 0 and table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return zaoli
