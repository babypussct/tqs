local chenshuo = fk.CreateSkill{
  name = "chenshuo",
}

Fk:loadTranslationTable{
  ["chenshuo"] = "谶说",
  [":chenshuo"] = "准备阶段，你可以令一名角色展示一张手牌，然后展示牌堆顶的牌，"..
    "若展示牌类型/花色/点数/牌名字数中任意项相同且展示牌堆顶牌数小于3，重复此流程，最后你获得以此法展示的牌。",

  ["#chenshuo-choose"] = "谶说：选择一名角色，令其展示一张手牌",
  ["#chenshuo-card"] = "谶说：展示一张手牌",

  ["$chenshuo1"] = "命数玄奥，然吾可言之。",
  ["$chenshuo2"] = "天地神鬼之辩，在吾唇舌之间。",
}

chenshuo:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(chenshuo.name) and
      not table.every(player.room.alive_players, function(p)
        return p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = table.filter(room.alive_players, function(p)
        return not p:isKongcheng()
      end),
      skill_name = chenshuo.name,
      prompt = "#chenshuo-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pcards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chenshuo.name,
      prompt = "#chenshuo-card",
      cancelable = false,
    })
    if #pcards == 0 then return end
    local card = Fk:getCardById(pcards[1])
    local cardType = card.type
    local suit = card.suit
    local number = card.number
    local nameLen = card:getNameLength(true)
    to:showCards(pcards)
    room:delay(1000)
    if player.dead then return end
    local dpShown = {}
    for i = 1, 3, 1 do
      local dcards = room:getNCards(i)
      --依次展示牌堆顶1、2、3张牌
      --FIXME: 由于不想桌面出现6张牌，做手动去重处理，待UI完善后再调整此部分逻辑
      dcards = table.filter(dcards, function(id)
        return table.insertIfNeed(dpShown, id)
      end)
      if #dcards > 0 then
        room:showCards(dcards, nil, player)
        room:delay(1000)
        if player.dead then return end
        if not table.every(dcards, function(id)
          card = Fk:getCardById(id)
          return card.type == cardType or card.suit == suit or card.number == number or
            card:getNameLength(true) == nameLen
        end) then
          break
        end
      end
    end
    local moveInfos = {}
    if to ~= player and table.contains(to:getCardIds("h"), pcards[1]) then
      table.insert(moveInfos, {
        ids = pcards,
        from = to,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        skillName = chenshuo.name,
        moveVisible = true,
        proposer = player,
      })
    end
    dpShown = table.filter(dpShown, function(id)
      return table.contains(room.draw_pile, id)
    end)
    if #dpShown > 0 then
      table.insert(moveInfos, {
        ids = dpShown,
        from = nil,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        skillName = chenshuo.name,
        moveVisible = true,
        proposer = player,
      })
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end
  end,
})

return chenshuo
