local yizhengx = fk.CreateSkill {
  name = "yizhengx",
}

Fk:loadTranslationTable{
  ["yizhengx"] = "议政",
  [":yizhengx"] = "回合开始时，你可以与任意名其他角色同时展示一张手牌，若展示的牌类别均相同，你可以将这些牌交给一名角色，否则弃置这些牌。",

  ["#yizhengx-choose"] = "议政：与任意名其他角色同时展示一张手牌，若类别均相同则交给一名角色，否则全部弃置",
  ["#yizhengx-ask"] = "议政：请展示一张手牌，若类别均相同则 %src 交给一名角色，否则弃置",
  ["#yizhengx-give"] = "议政：将这些牌交给一名角色",

  ["$yizhengx1"] = "大魏国朝待兴，岂可抱鹤鸣琴？",
  ["$yizhengx2"] = "居肉食者之位，理应为天下谋。",
}

yizhengx:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yizhengx.name) and
      not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng()
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 10,
      targets = targets,
      skill_name = yizhengx.name,
      prompt = "#yizhengx-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(yizhengx)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    table.insert(targets, player)
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      include_equip = false,
      cancelable = false,
      skill_name = yizhengx.name,
      prompt = "#yizhengx-ask:"..player.id,
    })
    local cards = {}
    for _, p in ipairs(targets) do
      local id = result[p][1]
      if not p.dead and table.contains(p:getCardIds("h"), id) then
        p:showCards(id)
        table.insertIfNeed(cards, id)
      end
    end
    local moves = {}
    if table.every(cards, function (id)
      return Fk:getCardById(id).type == Fk:getCardById(cards[1]).type
    end) then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = yizhengx.name,
        prompt = "#yizhengx-give",
        cancelable = false,
      })[1]
      for p, ids in pairs(result) do
        if p ~= to and table.contains(p:getCardIds("h"), ids[1]) then
          table.insert(moves, {
            from = p,
            to = to,
            ids = ids,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonGive,
            skillName = yizhengx.name,
            moveVisible = true,
            proposer = player,
          })
        end
      end
    else
      for p, ids in pairs(result) do
        if table.contains(p:getCardIds("h"), ids[1]) and (p ~= player or not player:prohibitDiscard(ids[1])) then
          table.insert(moves, {
            from = p,
            ids = ids,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonDiscard,
            skillName = yizhengx.name,
            moveVisible = true,
            proposer = player,
          })
        end
      end
    end
    room:moveCards(table.unpack(moves))
  end,
})

return yizhengx
