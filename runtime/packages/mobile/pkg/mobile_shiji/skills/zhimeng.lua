local zhimeng = fk.CreateSkill {
  name = "zhimeng",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("role_mode") then
      return "zhimeng_role_mode"
    else
      return "zhimeng_1v2"
    end
  end,
}

Fk:loadTranslationTable{
  ["zhimeng"] = "智盟",
  [":zhimeng"] = "回合结束时，你可以与一名其他角色随机平均分配手牌（若不为身份模式，则改为手牌数不大于你手牌数+1的其他角色），" ..
  "若总牌数为奇数，则你分配较多张数。",

  [":zhimeng_role_mode"] = "回合结束时，你可以与一名其他角色随机平均分配手牌，若总牌数为奇数，则你分配较多张数。",
  [":zhimeng_1v2"] = "回合结束时，你可以与一名手牌数不大于你手牌数+1的其他角色随机平均分配手牌，若总牌数为奇数，则你分配较多张数。",

  ["#zhimeng-choose"] = "智盟：你可以选择一名角色与其随机平分手牌",

  ["$zhimeng1"] = "豫州何图远窜，而不投吾雄略之主乎？",
  ["$zhimeng2"] = "吾主英明神武，曹众虽百万亦无所惧！",
}

zhimeng:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhimeng.name) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return (player.room:isGameMode("role_mode") or p:getHandcardNum() <= player:getHandcardNum() + 1) and
          not (player:isKongcheng() and p:isKongcheng())
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return (room:isGameMode("role_mode") or p:getHandcardNum() <= player:getHandcardNum() + 1) and
        not (player:isKongcheng() and p:isKongcheng())
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhimeng.name,
      prompt = "#zhimeng-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local moveInfos = {}
    local wholeCards = {}
    if player:getHandcardNum() > 0 then
      table.insertTable(wholeCards, player:getCardIds("h"))
      table.insert(moveInfos, {
        from = player,
        ids = player:getCardIds("h"),
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = player,
        skillName = zhimeng.name,
        moveVisible = false,
      })
    end
    if to:getHandcardNum() > 0 then
      table.insertTable(wholeCards, to:getCardIds("h"))
      table.insert(moveInfos, {
        from = to,
        ids = to:getCardIds("h"),
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = player,
        skillName = zhimeng.name,
        moveVisible = false,
      })
    end

    if #moveInfos == 0 or #wholeCards == 0 then
      return false
    end

    room:moveCards(table.unpack(moveInfos))

    moveInfos = {}
    local youGainNum = math.ceil(#wholeCards / 2)
    local youGain = {}
    for i = 1, youGainNum do
      local idRemoved = table.remove(wholeCards, math.random(1, #wholeCards))
      table.insert(youGain, idRemoved)
    end

    if not player.dead then
      local to_ex_cards = table.filter(youGain, function (id)
        return room:getCardArea(id) == Card.Processing
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player,
          skillName = zhimeng.name,
          moveVisible = false,
        })
      end
    end
    if not to.dead then
      local to_ex_cards = table.filter(wholeCards, function (id)
        return room:getCardArea(id) == Card.Processing
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = wholeCards,
          fromArea = Card.Processing,
          to = to,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player,
          skillName = zhimeng.name,
          moveVisible = false,
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end
    room:cleanProcessingArea(wholeCards)
  end,
})

return zhimeng
