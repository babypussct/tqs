local shefuc = fk.CreateSkill {
  name = "shefuc",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shefuc"] = "慑伏",
  [":shefuc"] = "锁定技，你的牌造成的伤害改为X，其他角色的牌对你造成的伤害改为X（X为该牌在手中的轮数）。",

  ["$shefuc1"] = "刘备！你一介织鞋贩夫，凭什么在这耀武扬威啊？",
  ["$shefuc2"] = "爷们水里进火里出，是响当当的铁汉子、硬骨头！",
}

shefuc:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shefuc.name) and
      target and data.card and (target == player or data.to == player) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        if use.card == data.card and use.extra_data and use.extra_data.shefuc then
          event:setCostData(self, {choice = use.extra_data.shefuc})
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1 + event:getCostData(self).choice - data.damage)
  end,
})

shefuc:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "shefuc-inhand", room:getBanner("RoundCount"))
          end
        end
      end
    end
  end,
})

shefuc:addEffect(fk.GameStart, {
  can_refresh = Util.TrueFunc,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if not p:isKongcheng() then
        for _, id in ipairs(p:getCardIds("h")) do
          room:setCardMark(Fk:getCardById(id), "shefuc-inhand", 1)
        end
      end
    end
  end,
})

shefuc:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and
      data.card.is_damage_card and #Card:getIdList(data.card) == 1 and
      table.contains(player:getCardIds("h"), Card:getIdList(data.card)[1]) and
      Fk:getCardById(Card:getIdList(data.card)[1]):getMark("shefuc-inhand") < player.room:getBanner("RoundCount")
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.shefuc = player.room:getBanner("RoundCount") - Fk:getCardById(Card:getIdList(data.card)[1]):getMark("shefuc-inhand")
  end,
})

shefuc:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if not p:isKongcheng() then
        for _, id in ipairs(p:getCardIds("h")) do
          local card = Fk:getCardById(id)
          if card:getMark("shefuc-inhand") == 0 then
            room:setCardMark(card, "shefuc-inhand", room:getBanner("RoundCount"))
          end
        end
      end
    end
  end
end)

return shefuc
