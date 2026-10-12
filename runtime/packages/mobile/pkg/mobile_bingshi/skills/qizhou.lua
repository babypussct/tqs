
local qizhou = fk.CreateSkill {
  name = "m_shi__qizhou",
}

Fk:loadTranslationTable{
  ["m_shi__qizhou"] = "绮胄",
  [":m_shi__qizhou"] = "当有牌进入你的场上后，你可以将一名角色的一张手牌标记为<a href='m_shi__qizhou_card'>应机牌</a>，"..
  "若此牌为【杀】，你下次以此法发动后摸两张应机牌。摸牌阶段，你额外摸两张应机牌。",

  ["m_shi__qizhou_card"] = "每回合结束时，所有角色手牌中的应机牌会被置入弃牌堆。",
  ["@@m_shi__qizhou"] = "应机",
  ["#m_shi__qizhou-choose"] = "绮胄：你可以将一名角色的一张手牌标记为应机牌，若标记【杀】则下次摸两张应机牌",

  ["$m_shi__qizhou1"] = "要说军容绮靡，天下唯我一人！",
  ["$m_shi__qizhou2"] = "军用何足道哉？器善方为精兵！",
}

qizhou:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qizhou.name) and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end) then
      for _, move in ipairs(data) do
        if move.to == player and (move.toArea == Card.PlayerEquip or move.toArea == Card.PlayerJudge) then
          return true
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_shi__qizhou-choose",
      skill_name = qizhou.name,
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
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = qizhou.name,
    })
    room:setCardMark(Fk:getCardById(card, true), "@@m_shi__qizhou", 1)
    local yes = player:getMark(qizhou.name) > 0
    if Fk:getCardById(card).trueName == "slash" then
      room:setPlayerMark(player, qizhou.name, 1)
    end
    if yes then
      local cards = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
        return Fk:getCardById(id, true):getMark("@@m_shi__qizhou") > 0
      end)
      if #cards > 0 then
        room:moveCardTo(room:tableRandomPick(cards, 2), Card.PlayerHand, player, fk.ReasonDraw, qizhou.name, nil, false, player)
      end
    end
  end,
})

qizhou:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
      return Fk:getCardById(id, true):getMark("@@m_shi__qizhou") > 0
    end)
    if #cards > 0 then
      room:moveCardTo(room:tableRandomPick(cards, 2), Card.PlayerHand, player, fk.ReasonDraw, qizhou.name, nil, false, player)
    end
  end,
})

qizhou:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id, true):getMark("@@m_shi__qizhou") > 0
    end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id, true):getMark("@@m_shi__qizhou") > 0
    end)
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile)
  end,
})

return qizhou
