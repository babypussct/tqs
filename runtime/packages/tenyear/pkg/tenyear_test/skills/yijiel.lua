
local yijiel = fk.CreateSkill {
  name = "yijiel",
  max_branches_use_time = {
    ["1"] = {
      [Player.HistoryTurn] = 1
    },
    ["2"] = {
      [Player.HistoryTurn] = 1
    },
  },
}

Fk:loadTranslationTable {
  ["yijiel"] = "缢节",
  [":yijiel"] = "每回合各限一次，其他角色获得你的牌后，你可以失去1点体力并弃置这些牌；"..
  "你获得其他角色的牌后，你可以弃置除这些牌以外的其他全部手牌并回复1点体力。",

  ["#yijiel1-invoke"] = "缢节：其他角色获得了你的牌，你可以失去1点体力并弃置这些牌",
  ["#yijiel2-invoke"] = "缢节：你可以弃置除获得牌之外的手牌，回复1点体力",

  ["$yijiel1"] = "",
  ["$yijiel2"] = "",
}

yijiel:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yijiel.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and
          (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) and
          yijiel:withinBranchTimesLimit(player, "1", Player.HistoryTurn) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        elseif move.from and move.from ~= player and move.to == player and
          (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) and
          yijiel:withinBranchTimesLimit(player, "2", Player.HistoryTurn) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if not player:hasSkill(yijiel.name) then return end
      if move.from == player and move.to and move.to ~= player and
        yijiel:withinBranchTimesLimit(player, "choice1", Player.HistoryTurn) then
        local yes = false
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            yes = true
          end
        end
        if yes then
          event:setCostData(self, { extra_data = 1 })
          self:doCost(event, target, player, data)
        end
      elseif move.from and move.from ~= player and move.to == player and
        (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) and
        yijiel:withinBranchTimesLimit(player, "choice2", Player.HistoryTurn) then
        local yes = false
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            yes = true
          end
        end
        if yes then
          event:setCostData(self, { extra_data = 2 })
          self:doCost(event, target, player, data)
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choice = event:getCostData(self).extra_data
    return player.room:askToSkillInvoke(player, {
      skill_name = yijiel.name,
      prompt = "#yijiel"..choice.."-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).extra_data
    player:addSkillBranchUseHistory(yijiel.name, tostring(choice), 1)
    if choice == 1 then
      room:loseHp(player, 1, yijiel.name, player)
      local moves = {}
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player then
          local ids = {}
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              table.contains(move.to:getCardIds("he"), info.cardId) then
              table.insert(ids, info.cardId)
            end
          end
          if #ids > 0 then
            table.insert(moves, {
              ids = ids,
              from = move.to,
              toArea = Card.DiscardPile,
              moveReason = fk.ReasonDiscard,
              skillName = yijiel.name,
              proposer = player,
            })
          end
        end
      end
      if next(moves) then
        room:moveCards(table.unpack(moves))
      end
    else
      local cards = table.filter(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id)
      end)
      for _, move in ipairs(data) do
        if move.from and move.from ~= player and move.to == player and
          (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.removeOne(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        room:throwCard(cards, yijiel.name, player, player)
      end
      if not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = yijiel.name
        }
      end
    end
  end,
})

return yijiel
