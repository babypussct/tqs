local premeditate_rule = fk.CreateSkill {
  name = "#premeditate_rule&",
}

Fk:loadTranslationTable{
  ["#premeditate_rule&"] = "蓄谋",
  ["#premediterate-use"] = "你可以使用此蓄谋牌%arg，或点“取消”将所有蓄谋牌置入弃牌堆",
  ["premeditate_href"] = "将一张手牌扣置于判定区，判定阶段开始时，按置入顺序（后置入的先处理）依次处理“蓄谋”牌："..
  "1.使用此牌，然后此阶段不能再使用此牌名的牌；2.将所有“蓄谋”牌置入弃牌堆。",

  ["premeditate"] = "蓄谋",
  [":premeditate"] = "这是一张“蓄谋”牌。蓄谋牌将在下个判定阶段按置入顺序从后往前依次询问使用。",
}

premeditate_rule:addEffect(fk.EventPhaseStart, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Judge
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    while true do
      local premeditate_cards = table.filter(player:getCardIds("j"), function(id)
        local card = player:getVirtualEquip(id)
        return card and card.name == "premeditate"
      end)
      if #premeditate_cards == 0 then break end
      -- 按置入顺序，后置入的先处理（假设getCardIds返回的顺序是置入顺序）
      local cur = premeditate_cards[#premeditate_cards]  -- 取最后一个，即最新置入的
      if player.dead then return end
      local use = room:askToUseRealCard(player, {
        pattern = {cur},
        skill_name = "premeditate",
        prompt = "#premediterate-use:::"..Fk:getCardById(cur, true):toLogString(),
        expand_pile = {cur},
        extra_data = {
          expand_pile = {cur},
          extraUse = true,
        },
        cancelable = true,
        skip = true,
      })
      if use then
        room:addTableMark(player, "premeditate-phase", use.card.trueName)
        use.extra_data = use.extra_data or {}
        use.extra_data.premeditate = true
        player:removeVirtualEquip(use.card.id)
        room:useCard(use)
      else
        break
      end
    end
    -- 移动剩余的蓄谋牌到弃牌堆
    local remaining = table.filter(player:getCardIds("j"), function(id)
      local card = player:getVirtualEquip(id)
      return card and card.name == "premeditate"
    end)
    room:moveCardTo(remaining, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, premeditate_rule.name, nil, true, player)
  end,
})

premeditate_rule:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("premeditate-phase"), card.trueName)
  end,
})

premeditate_rule:addEffect("visibility", {
  card_visible = function (self, player, card)
    local owner = Fk:currentRoom():getCardOwner(card)
    if owner and owner:getVirtualEquip(card.id) and owner:getVirtualEquip(card.id).name == "premeditate" then
      return player == owner
    end
  end,
  move_visible = function (self, player, info, move)
    local cid = info.cardId
    local from = move.from
    if from and move.toArea == Card.PlayerJudge then
      if from:getVirtualEquip(cid) and from:getVirtualEquip(cid).name == "premeditate" then
        return false
      end
    end
  end,
})

return premeditate_rule
