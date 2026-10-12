local tianhou = fk.CreateSkill{
  name = "tianhou",
  tags = { Skill.Compulsory },
  related_skills = { "tianhou_hot", "tianhou_fog", "tianhou_rain", "tianhou_frost" },
}

Fk:loadTranslationTable{
  ["tianhou"] = "天候",
  [":tianhou"] = "锁定技，结束阶段，你观看牌堆顶的三张牌并选择是否用你的手牌交换之，"..
    "然后你展示牌堆顶三张牌中的一张，令一名角色根据此牌花色获得技能直到你下次发动此技能：<br>"..
    "<font color='red'>♥</font><a href=':tianhou_hot'>〖烈暑〗</a>；"..
    "<font color='red'>♦</font><a href=':tianhou_fog'>〖凝雾〗</a>；"..
    "♠<a href=':tianhou_rain'>〖骤雨〗</a>；"..
    "♣<a href=':tianhou_frost'>〖严霜〗</a>。",

  ["#tianhou-exchange"] = "天候：你可以用一张手牌交换牌堆顶部的牌",
  ["#tianhou-choose"] = "天候：根据展示牌的花色令一名角色获得技能",

  ["$tianhou1"] = "雷霆雨露，皆为君恩。",
  ["$tianhou2"] = "天象之所显，世事之所为。",
}

Fk:addPoxiMethod{
  name = "tianhou_exchange",
  prompt = "#tianhou-exchange",
  card_filter = Util.TrueFunc,
  feasible = function(selected, data, extra_data)
    if data == nil then return false end
    if data == nil or #selected == 0 then return false end
    local cards = data[1][2]
    return #table.filter(selected, function (id)
      return table.contains(cards, id)
    end) *2 == #selected
  end
}

Fk:addCardTip{
  name = "tianhou",
  card_tip = function (self, player, to_select, selected, selected_targets, card, selectable, extra_data)
    local skills = { "tianhou_rain", "tianhou_frost", "tianhou_hot", "tianhou_fog" }
    return selectable and skills[Fk:getCardById(to_select).suit] or nil
  end
}

tianhou:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianhou.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local top_cards = room:getNCards(3)
    local handcards = player:getCardIds("h")

    local cards = room:askToPoxi(player, {
      poxi_type = "tianhou_exchange",
      cancelable = true,
      data = {
        { "Top", top_cards },
        { "$Hand", handcards }
      },
    })

    if #cards > 0 then
      room:moveCardTo(cards, Card.Processing, nil, fk.ReasonExchange, tianhou.name, nil, false, player)
      if player.dead then
        room:cleanProcessingArea(cards, tianhou.name)
        return
      end

      --将输出的顺序调整为在框里（即原区域）的顺序而非点击顺序（其实上一步就该做的，先偷个懒）
      local cards1 = table.filter(top_cards, function(id)
        return table.contains(cards, id) and room:getCardArea(id) == Card.Processing
      end)

      --即将置顶的牌，需逆序
      local cards2 = {}
      for i = #handcards, 1, -1 do
        local id = handcards[i]
        if table.contains(cards, id) and room:getCardArea(id) == Card.Processing then
          table.insert(cards2, id)
        end
      end

      local moveInfos = {}
      if #cards1 > 0 then
        table.insert(moveInfos, {
          ids = cards1,
          from = nil,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          skillName = tianhou.name,
          proposer = player,
          moveVisible = false,
        })
      end
      if #cards2 > 0 then
        table.insert(moveInfos, {
          ids = cards2,
          from = nil,
          to = nil,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonExchange,
          skillName = tianhou.name,
          proposer = player,
          moveVisible = false,
          visiblePlayers = { player },
        })
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
        if player.dead then return end
      end
    end

    top_cards = room:getNCards(3)
    local skills = { "tianhou_rain", "tianhou_frost", "tianhou_hot", "tianhou_fog" }
    local tos, show_cards = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      targets = room.alive_players,
      skill_name = tianhou.name,
      pattern = tostring(Exppattern{ id = top_cards }),
      prompt = "#tianhou-choose",
      cancelable = false,
      expand_pile = top_cards,
      card_tip_name = tianhou.name,
    })
    local suit = Fk:getCardById(show_cards[1], true).suit
    room:showCards(show_cards)
    for _, p in ipairs(room.alive_players) do
      room:handleAddLoseSkills(p, "-"..table.concat(skills, "|-"))
    end
    if suit == Card.NoSuit then return end
    room:handleAddLoseSkills(tos[1], skills[suit])
  end,
})

return tianhou
