local dingpin = fk.CreateSkill {
  name = "m_ex__dingpin",
}

Fk:loadTranslationTable{
  ["m_ex__dingpin"] = "定品",
  [":m_ex__dingpin"] = "出牌阶段，你可以弃置一张牌（不能是你本回合使用或弃置过的类型）并选择一名角色，令其进行判定，若结果为："..
  "黑色，该角色摸X张牌（X为当前体力值且最大为3），然后你于此回合内不能对其发动“定品”；"..
  "<font color='red'>♥</font>，你此次发动“定品”弃置的牌不计入弃置过的类型；<font color='red'>♦</font>，你翻面。",

  ["#m_ex__dingpin-active"] = "定品：选择1张牌弃置（不能是你本回合使用或弃置过的类型），并选择1名角色",

  ["$m_ex__dingpin1"] = "察举旧制已隳，简拔当立中正。",
  ["$m_ex__dingpin2"] = "置州郡中正，以九品进退人才。",
}

dingpin:addEffect("active", {
  anim_type = "support",
  prompt = "#m_ex__dingpin-active",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return not (player:prohibitDiscard(card) or table.contains(player:getTableMark("m_ex__dingpin_types-turn"), card:getTypeString()))
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark("m_ex__dingpin_target-turn"), to_select.id)
  end,
  on_use = function(self, room, use)
    local player = use.from
    local target = use.tos[1]
    room:throwCard(use.cards, dingpin.name, player)
    local judge = {
      who = target,
      reason = dingpin.name
    }
    room:judge(judge)
    if judge.card.color == Card.Black then
      if not target.dead and target.hp > 0 then
        room:drawCards(target, math.min(3, target.hp), dingpin.name)
        room:addTableMark(player, "m_ex__dingpin_target-turn", target.id)
      end
    elseif judge.card.suit == Card.Heart then
      room:removeTableMark(player, "m_ex__dingpin_types-turn", Fk:getCardById(use.cards[1], true):getTypeString())
    elseif judge.card.suit == Card.Diamond then
      player:turnOver()
    end
  end,
})

dingpin:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return player == data.from and player:hasSkill(dingpin.name) and player.room:getCurrent() == player and
      #player:getTableMark("m_ex__dingpin_types-turn") < 3
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "m_ex__dingpin_types-turn", data.card:getTypeString())
  end,
})

dingpin:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(dingpin.name) and player.room:getCurrent() == player and
      #player:getTableMark("m_ex__dingpin_types-turn") < 3
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getTableMark("m_ex__dingpin_types-turn")
    local changemark = false
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            if table.insertIfNeed(mark, Fk:getCardById(info.cardId, true):getTypeString()) then
              changemark = true
            end
          end
        end
      end
    end
    if changemark then
      player.room:setPlayerMark(player, "m_ex__dingpin_types-turn", mark)
    end
  end,
})

dingpin:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "m_ex__dingpin_target-turn", 0)
  room:setPlayerMark(player, "m_ex__dingpin_types-turn", 0)
end)

return dingpin
