local ruilian = fk.CreateSkill {
  name = "ruilian",
}

Fk:loadTranslationTable{
  ["ruilian"] = "睿敛",
  [":ruilian"] = "每轮开始时，你可选择一名角色，其下个回合结束前，若其此回合弃置过牌，" ..
  "你可选择其此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌。",

  ["#ruilian-ask"] = "你可对一名角色发动“睿敛”",
  ["@@ruilian"] = "睿敛",
  ["@ruilian-turn"] = "睿敛",
  ["#ruilian-type"] = "睿敛：你可选择 %src 此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌",

  ["$ruilian1"] = "公若擅进庸肆，必失民心！",
  ["$ruilian2"] = "外敛虚进之势，内减弊民之政。",
}

ruilian:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ruilian.name)
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(
      player,
      {
        targets = player.room:getAlivePlayers(false),
        min_num = 1,
        max_num = 1,
        prompt = "#ruilian-ask",
        skill_name = ruilian.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(to, "@@ruilian", 1)
    local ruilianGiver = to:getTableMark("_ruilianGiver")
    table.insertIfNeed(ruilianGiver, player.id)
    room:setPlayerMark(to, "_ruilianGiver", ruilianGiver)
  end,
})

ruilian:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(ruilian.name) and
      tonumber(target:getMark("@ruilian-turn")) > 0 and
      table.contains(target:getTableMark("_ruilianGiver"), player.id)
  end,
  on_cost = function(self, event, target, player, data)
    local cids = target:getTableMark("_ruilianCids-turn")
    local cardType = {}
    table.forEach(cids, function(cid)
      table.insertIfNeed(cardType, Fk:getCardById(cid):getTypeString())
    end)
    table.insert(cardType, "Cancel")
    local choice = player.room:askToChoice(
      player,
      {
        choices = cardType,
        skill_name = ruilian.name,
        prompt = "#ruilian-type:" .. target.id,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = ruilian.name
    local room = player.room
    local costData = event:getCostData(self).choice
    local id = room:getCardsFromPileByRule(".|.|.|.|.|" .. costData, 1, "discardPile")
    if #id > 0 then
      room:obtainCard(target, id[1], true, fk.ReasonPrey, player, skillName)
    end
    id = room:getCardsFromPileByRule(".|.|.|.|.|" .. costData, 1, "discardPile")
    if #id > 0 and not player.dead then
      room:obtainCard(player, id[1], true, fk.ReasonPrey, player, skillName)
    end
  end,
})

ruilian:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player ~= player.room.current or player:getMark("@ruilian-turn") == 0 then
      return false
    end

    local cids = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(cids, info.cardId)
          end
        end
      end
    end
    if #cids > 0 then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cids = player:getTableMark("_ruilianCids-turn")
    local otherCids = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(otherCids, info.cardId)
          end
        end
      end
    end
    table.insertTable(cids, otherCids)
    room:setPlayerMark(player, "_ruilianCids-turn", cids)
    room:setPlayerMark(player, "@ruilian-turn", #player:getMark("_ruilianCids-turn"))
  end,
})

ruilian:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player == player.room.current and target == player and player:getMark("@@ruilian") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ruilian-turn", "0")
    room:setPlayerMark(player, "@@ruilian", 0)
  end,
})

return ruilian
