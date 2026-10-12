local chuanyu = fk.CreateSkill{
  name = "chuanyu",
}

Fk:loadTranslationTable{
  ["chuanyu"] = "传舆",
  [":chuanyu"] = "每轮开始时，你可以交给一名角色一张牌，称为“舆”。"..
  "每当“舆”因使用进入弃牌堆后，你可以将之交给本轮未获得过“舆”的一名角色。"..
  "每轮结束时，你可以令本轮所有获得过“舆”的角色依次视为对你指定的一名角色使用【杀】（无距离限制），然后弃置所有“舆”。",

  ["@@chuanyu-inhand-round"] = "舆",
  ["#chuanyu-give"] = "传舆：将一张牌标记为“舆”交给一名角色",
  ["#chuanyu-choose"] = "传舆：你可以将“舆”%arg交给一名角色",
  ["#chuanyu-slash"] = "传舆：你可以选择一名角色，所有本轮获得过“舆”的角色视为对其使用【杀】！",

  ["$chuanyu1"] = "传下去，钟会那厮已挖好了大坑！",
  ["$chuanyu2"] = "再不动手，姓钟的就把咱们都埋了！",
}

chuanyu:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chuanyu.name) and
      not player:isNude() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = chuanyu.name,
      prompt = "#chuanyu-give",
      cancelable = true,
    })
    if #to > 0 and #card > 0 then
      event:setCostData(self, {tos = to, card = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = Fk:getCardById(event:getCostData(self).card[1])
    room:setPlayerMark(player, "chuanyu_card-round", card.id)
    room:addTableMark(player, "chuanyu-round", to.id)
    if to ~= player then
      room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, chuanyu.name, nil, false, player)
    else
      room:setCardMark(card, "@@chuanyu-inhand-round", 1)
    end
  end,
})

chuanyu:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(chuanyu.name) and player:getMark("chuanyu_card-round") ~= 0 and
      table.find(player.room.alive_players, function (p)
        return not table.contains(player:getTableMark("chuanyu-round"), p.id)
      end) then
      local id = player:getMark("chuanyu_card-round")
      if not table.contains(player.room.discard_pile, id) then return false end
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonUse and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.cardId == id then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not table.contains(player:getTableMark("chuanyu-round"), p.id)
    end)
    local card = Fk:getCardById(player:getMark("chuanyu_card-round"))
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#chuanyu-choose:::" .. card:toLogString(),
      skill_name = chuanyu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMark(player, "chuanyu-round", to.id)
    room:moveCardTo(player:getMark("chuanyu_card-round"), Card.PlayerHand, to, fk.ReasonGive, chuanyu.name, nil, true, player)
  end,

  can_refresh = function (self, event, target, player, data)
    return not player.dead and player:getMark("chuanyu_card-round") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local id = player:getMark("chuanyu_card-round")
    if room:getCardArea(id) == Card.PlayerHand then
      room:setCardMark(Fk:getCardById(id), "@@chuanyu-inhand-round", 1)
    end
  end,
})

chuanyu:addEffect(fk.RoundEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chuanyu.name) and
      table.find(player:getTableMark("chuanyu-round"), function (id)
        return not player.room:getPlayerById(id).dead
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#chuanyu-slash",
      skill_name = chuanyu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = player:getMark("chuanyu_card-round")
    local targets = table.map(player:getTableMark("chuanyu-round"), Util.Id2PlayerMapper)
    targets = table.filter(targets, function (p)
      return not p.dead
    end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if to.dead then break end
      if not p.dead and p ~= to then
        room:useVirtualCard("slash", nil, p, to, chuanyu.name)
      end
    end
    if room:getCardOwner(id) ~= nil and
      table.contains({Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}, room:getCardArea(id)) then
      room:throwCard(id, chuanyu.name, room:getCardOwner(id))
    end
  end,
})

return chuanyu
