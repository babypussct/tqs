local skill = fk.CreateSkill {
  name = "es__poison_skill",
}

Fk:loadTranslationTable{
  ["#es__poison-give"] = "你可以将摸到的【毒】交给其他角色（不触发失去体力效果）",
  ["es__poison_give"] = "毒",
}

skill:addEffect("cardskill", {
  can_use = Util.FalseFunc,
})

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = event:getCostData(self).cards
    local result = room:askToYiji(player, {
      cards = ids,
      targets = room:getOtherPlayers(player, false),
      skill_name = "",
      min_num = 0,
      max_num = #ids,
      prompt = "#es__poison-give",
      skip = true,
    })
    for _, cards in pairs(result) do
      if #cards > 0 then
        event:setCostData(self, {extra_data = result})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:doYiji(event:getCostData(self).extra_data, player, "es__poison_give")
  end,
}

skill:addEffect(fk.AfterCardsMove, {
  global = true,
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead then
      for _, move in ipairs(data) do
        if move.from == player and move.skillName ~= "es__poison_give" and move.skillName ~= "scrape_poison_skill" then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and info.beforeCard.name == "es__poison" and
              (move.moveVisible or
              table.contains({ Card.PlayerEquip, Card.Processing, Card.DiscardPile, Card.Void }, move.toArea)) then
              return true
            end
          end
        end
        if move.to == player and move.toArea == Card.PlayerHand and move.moveReason == fk.ReasonDraw then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "es__poison" and
              table.contains(player:getCardIds("h"), info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = 0
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player and move.skillName ~= "es__poison_give" and move.skillName ~= "scrape_poison_skill" then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and info.beforeCard.name == "es__poison" and
            (move.moveVisible or
            table.contains({ Card.PlayerEquip, Card.Processing, Card.DiscardPile, Card.Void }, move.toArea)) then
            n = n + 1
          end
        end
      end
      if move.to == player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "es__poison" and
            table.contains(player:getCardIds("h"), info.cardId) then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    for _ = 1, n, 1 do
      if not player.dead then
        player.room:loseHp(player, 1, "poison")
      end
    end
    ids = table.filter(ids, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if not player.dead and #ids > 0 and #player.room:getOtherPlayers(player, false) > 0 then
      event:setCostData(self, {cards = ids})
      self:doCost(event, nil, player, ids)
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

skill:addEffect(fk.AfterDrawInitialCards, {
  global = true,
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and #player.room:getOtherPlayers(player, false) > 0 then
      local cards = table.filter(data.cards, function (id)
        return table.contains(player:getCardIds("h"), id) and
          Fk:getCardById(id).name == "es__poison"
      end)
      if #cards > 0 then
        event:setCostData(self, { cards = cards })
        return true
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return skill
