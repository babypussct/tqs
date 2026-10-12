local xiaxing = fk.CreateSkill {
  name = "os__xiaxing",
}

Fk:loadTranslationTable{
  ["os__xiaxing"] = "侠行",
  [":os__xiaxing"] = "游戏开始时，你获得并使用<a href=':xuanjian_sword'>【玄剑】</a>；当【玄剑】进入弃牌堆后，你可以弃2枚“启诲”获得之。",

  ["#xiaxing-choice"] = "侠行：是否移除两个“启诲”标记获得【玄剑】？",

  ["$os__xiaxing1"] = "愿以手中长剑，荡尽天下魍魉。",
  ["$os__xiaxing2"] = "吾为侠也，不愧持正之心，不负三尺之剑。",
}

local char2type = {
  ["基"] = "basic_char",
  ["锦"] = "trick_char",
  ["装"] = "equip_char",
}

xiaxing:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xiaxing.name) then
      local room = player.room
      local cards = table.filter(room:prepareDeriveCards({ {"xuanjian_sword", Card.Spade, 2} }, xiaxing.name), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      return #cards > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(room:prepareDeriveCards({ {"xuanjian_sword", Card.Spade, 2} }, xiaxing.name), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, xiaxing.name, nil, true, player)
    local card = Fk:getCardById(cards[1])
    if table.contains(player:getCardIds("h"), cards[1]) and player:canUseTo(card, player) then
      room:useCard{
        from = player,
        tos = {player},
        card = Fk:getCardById(cards[1]),
      }
    end
  end,
})
xiaxing:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xiaxing.name) and #player:getTableMark("@os__qihui") > 1 then
      local cards = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "xuanjian_sword" then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      cards = player.room.logic:moveCardsHoldingAreaCheck(cards)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local record = player:getMark("@os__qihui")
    local record_suffix = {} -- ChoiceBox直接用string判断，同名需要后缀
    local suffix_count = {}
    for _, value in ipairs(record) do
      suffix_count[value] = (suffix_count[value] or 0) + 1
      if suffix_count[value] == 1 then
        table.insert(record_suffix, Fk:translate(value))
      else
        table.insert(record_suffix, Fk:translate(value) .. tostring(suffix_count[value]))
      end
    end
    local choice = player.room:askToChoices(player, {
      min_num = 2,
      max_num = 2,
      choices = record_suffix,
      skill_name = xiaxing.name,
      prompt = "#xiaxing-choice",
      cancelable = true,
    })
    if #choice == 2 then
      choice = table.map(choice, function (s)
        return char2type[s[1]]
      end)
      event:setCostData(self, {cards = event:getCostData(self).cards, choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, c in ipairs(event:getCostData(self).choice) do
      room:removeTableMark(player, "@os__qihui", c)
    end
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonJustMove, xiaxing.name, nil, true, player)
  end,
})

return xiaxing
