local xingzuo = fk.CreateSkill {
  name = "xingzuo",
}

Fk:loadTranslationTable{
  ["xingzuo"] = "兴作",
  [":xingzuo"] = "出牌阶段开始时，你可以观看牌堆底的三张牌并用任意张手牌替换其中等量的牌。若如此做，结束阶段，你可以令一名有手牌的角色"..
  "用所有手牌替换牌堆底的三张牌，然后若交换前该角色的手牌数大于3，你失去1点体力。",

  ["#xingzuo-exchange"] = "兴作：你可以观看牌堆底的三张牌，用手牌替换其中等量的牌",
  ["#xingzuo-choose"] = "兴作：令一名角色用所有手牌交换牌堆底三张牌，若交换前手牌数大于3，你失去1点体力",

  ["$xingzuo1"] = "顺人之情，时之势，兴作可成。",
  ["$xingzuo2"] = "兴作从心，相继不绝。",
}

xingzuo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingzuo.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3, "bottom")
    room:turnOverCardsFromDrawPile(player, cards, xingzuo.name, false, { player })
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards == 0 then return end
    if player.dead then
      room:moveCards{
        ids = cards,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = xingzuo.name,
        moveVisible = false,
        proposer = player,
        drawPilePosition = -1,
        visiblePlayers = { player }
      }
      return
    end
    local results = room:askToArrangeCards(player, {
      skill_name = xingzuo.name,
      card_map = {
        "Bottom", cards,
        "$Hand", player:getCardIds("h"),
      },
      prompt = "#xingzuo-exchange",
      free_arrange = true,
    })

    --把不同区域的牌按特定顺序置于牌堆顶只能采用单卡move
    local moveInfos = {}
    for _, id in ipairs(results[1]) do
      table.insert(moveInfos, {
        ids = {id},
        from = not table.contains(cards, id) and player or nil,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = xingzuo.name,
        moveVisible = false,
        proposer = player,
        drawPilePosition = -1,
        visiblePlayers = { player }
      })
    end
    room:moveCards(table.unpack(moveInfos))

    cards = table.filter(results[2], function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      if player.dead then
        room:cleanProcessingArea(cards)
      else
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player, xingzuo.name)
      end
    end

  end
})

xingzuo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
      player:usedSkillTimes(xingzuo.name, Player.HistoryTurn) > 0 and
      table.find(player.room.alive_players, function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xingzuo-choose",
      skill_name = xingzuo.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = to:getHandcardNum()

    --先将手牌置于处理区，再获得牌堆底三张牌，再将处理区的牌置于牌堆底，牌堆底的顺序同手牌顺序（按获得的先后）
    local cards = to:getCardIds("h")
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, xingzuo.name, nil, false, player)
    if not to.dead then
      room:obtainCard(to, room:getNCards(3, "bottom"), false, fk.ReasonJustMove, player, xingzuo.name)
    end
    cards = table.filter(cards, function(id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      room:moveCards{
        ids = cards,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = xingzuo.name,
        moveVisible = false,
        proposer = player,
        visiblePlayers = to,
        drawPilePosition = -1
      }
    end

    if n > 3 and not player.dead then
      room:loseHp(player, 1, xingzuo.name)
    end
  end,
})

return xingzuo
