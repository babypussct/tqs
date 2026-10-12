local yizhu = fk.CreateSkill {
  name = "yizhu",
}

Fk:loadTranslationTable{
  ["yizhu"] = "遗珠",
  [":yizhu"] = "结束阶段，你摸两张牌，然后选择两张牌作为“遗珠”并记录之，随机洗入牌堆顶前2X张牌中（X为场上存活角色数）。"..
  "其他角色使用“遗珠”牌指定唯一目标后，你可以取消之，然后你将此牌从记录中移除。",

  ["#yizhu-card"] = "遗珠：将两张牌作为“遗珠”洗入牌堆",
  ["#yizhu-invoke"] = "遗珠：你可以取消 %dest 使用的%arg",

  ["$yizhu1"] = "老夫有二女，视之如明珠。",
  ["$yizhu2"] = "将军若得遇小女，万望护送而归。",
}

yizhu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yizhu.name) and player.phase == Player.Finish
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, yizhu.name)
    if player.dead or player:isNude() then return end
    local cards = room:askToCards(player, {
      min_num = math.min(#player:getCardIds("he"), 2),
      max_num = 2,
      include_equip = true,
      skill_name = yizhu.name,
      cancelable = false,
      prompt = "#yizhu-card",
    })
    local mark = player:getTableMark("yizhu_cards")
    local moves = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(mark, id)
      table.insert(moves, {
        ids = {id},
        from = player,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = yizhu.name,
        drawPilePosition = math.random(math.min(#room.draw_pile, math.max(2 * #room.alive_players , 1))),
      })
    end
    room:setPlayerMark(player, "yizhu_cards", mark)
    room:moveCards(table.unpack(moves))
  end,
})
yizhu:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(yizhu.name) then
      local mark = player:getTableMark("yizhu_cards")
      if #mark > 0 and data:isOnlyTarget(data.to) then
        return table.find(Card:getIdList(data.card), function(id)
          return table.contains(mark, id)
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yizhu.name,
      prompt = "#yizhu-invoke::"..target.id..":"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, {data.to})
    data:cancelTarget(data.to)
    local mark = player:getTableMark("yizhu_cards")
    for _, id in ipairs(Card:getIdList(data.card)) do
      table.removeOne(mark, id)
    end
    room:setPlayerMark(player, "yizhu_cards", #mark > 0 and mark or 0)
  end,
})
yizhu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    local mark = player:getTableMark("yizhu_cards")
    if #mark > 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(mark, info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("yizhu_cards")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(mark, info.cardId) then
            table.removeOne(mark, info.cardId)
          end
        end
      end
    end
    room:setPlayerMark(player, "yizhu_cards", #mark > 0 and mark or 0)
  end,
})

return yizhu
