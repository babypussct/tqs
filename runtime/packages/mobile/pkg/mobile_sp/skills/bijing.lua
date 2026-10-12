local bijing = fk.CreateSkill {
  name = "mobile__bijing",
}

Fk:loadTranslationTable{
  ["mobile__bijing"] = "闭境",
  [":mobile__bijing"] = "结束阶段，你可以选择一张手牌标记为“闭境”。若你于回合外失去“闭境”牌，当前回合角色的弃牌阶段开始时，其需弃置两张牌。"..
  "你的准备阶段，你弃置手牌中的“闭境”牌。",

  ["#mobile__bijing-invoke"] = "闭境：你可以将一张手牌标记为“闭境”牌",
  ["@@mobile__bijing"] = "闭境",

  ["$mobile__bijing1"] = "拒吴闭境，臣誓保永昌！",
  ["$mobile__bijing2"] = "一臣无二主，可战不可降！",
}

bijing:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bijing.name) and player.phase == Player.Finish and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = bijing.name,
      cancelable = true,
      prompt = "#mobile__bijing-invoke",
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@mobile__bijing", 1)
    end
  end,
})

bijing:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Discard and not target.dead and
      table.contains(target:getTableMark("mobile_bijing_invoking-turn"), player.id) and not target:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(target, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = bijing.name,
      cancelable = false,
    })
  end,
})

bijing:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player.room.current ~= player then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@mobile__bijing") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@mobile__bijing", 0)
        end
      end
    end
    if not room.current.dead then
      room:addTableMark(room.current, "mobile_bijing_invoking-turn", player.id)
    end
  end,
})

bijing:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@mobile__bijing") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@mobile__bijing") > 0
    end)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@mobile__bijing", 0)
    end
    cards = table.filter(cards, function (id)
      return not player:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(cards, bijing.name, player, player)
    end
  end,
})

return bijing
